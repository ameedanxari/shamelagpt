//
//  VoiceTranscriptionTests.swift
//  shamelagptTests
//
//  Covers the hybrid voice pipeline: SFSpeechRecognizer supplies a live preview while
//  recording, then the recorded audio is uploaded to `POST /api/transcribe` and the
//  server's transcript replaces the preview.
//

import XCTest
import Combine
@testable import ShamelaGPT

@MainActor
final class VoiceTranscriptionTests: XCTestCase {

    private var viewModel: ChatViewModel!
    private var mockAPIClient: MockAPIClient!
    private var mockSendMessageUseCase: MockSendMessageUseCase!
    private var mockChatRepository: MockChatRepository!
    private var mockAuthRepository: MockAuthRepository!
    private var mockVoiceInputManager: MockVoiceInputManager!
    private var mockOCRManager: MockOCRManager!
    private var recordingURL: URL!

    override func setUpWithError() throws {
        mockAPIClient = MockAPIClient()
        mockSendMessageUseCase = MockSendMessageUseCase()
        mockChatRepository = MockChatRepository()
        mockAuthRepository = MockAuthRepository()
        mockAuthRepository.mockIsLoggedIn = true
        mockVoiceInputManager = MockVoiceInputManager()
        mockOCRManager = MockOCRManager()

        // Stand-in for the recorded .m4a. Nothing reads its contents through the mock, but
        // it must exist so the code under test behaves as it does in production.
        recordingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        try Data("fake-audio-bytes".utf8).write(to: recordingURL)

        // Deliberately does NOT touch LanguageManager.shared. Test classes run in
        // parallel, so mutating that singleton races against classes asserting on
        // English copy. Locale coverage is done against the pure
        // ChatViewModel.transcriptionLanguageHint(for:) instead.
        viewModel = ChatViewModel(
            conversationId: nil,
            sendMessageUseCase: mockSendMessageUseCase,
            chatRepository: mockChatRepository,
            apiClient: mockAPIClient,
            authRepository: mockAuthRepository,
            isGuest: false,
            guestSessionId: nil,
            voiceInputManager: mockVoiceInputManager,
            ocrManager: mockOCRManager
        )
    }

    override func tearDownWithError() throws {
        if let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
        }
        recordingURL = nil
        viewModel = nil
        mockAPIClient = nil
        mockSendMessageUseCase = nil
        mockChatRepository = nil
        mockAuthRepository = nil
        mockVoiceInputManager = nil
        mockOCRManager = nil
    }

    // MARK: - Helpers

    /// Drives one full round trip: user has `draft` typed, records, the on-device recognizer
    /// pushes `interimPreview` into the composer, recording stops, upload completes.
    private func recordAndStop(draft: String, interimPreview: String, capturedAudio: Bool = true) async {
        viewModel.inputText = draft
        await viewModel.startVoiceInput()

        if capturedAudio {
            mockVoiceInputManager.recordedFileURL = recordingURL
        }
        mockVoiceInputManager.transcribedText = interimPreview
        mockVoiceInputManager.stopRecording()

        await viewModel.voiceTranscriptionTask?.value
    }

    // MARK: - Language Hint

    /// Covers every locale against the pure mapping rather than by driving the app's
    /// language singleton — see the note in setUp. The hint is not cosmetic: the same
    /// clip returns garbled Urdu without it and clean Urdu with `language=ur`.
    func testLanguageHintMapsEveryAppLocaleToAnISOCode() {
        XCTAssertEqual(ChatViewModel.transcriptionLanguageHint(for: .english), "en")
        XCTAssertEqual(ChatViewModel.transcriptionLanguageHint(for: .arabic), "ar")
        XCTAssertEqual(ChatViewModel.transcriptionLanguageHint(for: .urdu), "ur")
    }

    /// And that whatever the mapping returns is actually the value put on the wire.
    func testUploadSendsTheLanguageHint() async throws {
        await recordAndStop(draft: "", interimPreview: "preview")

        XCTAssertEqual(mockAPIClient.transcribeCallCount, 1)
        XCTAssertEqual(
            mockAPIClient.lastTranscribeLanguage,
            ChatViewModel.transcriptionLanguageHint(for: LanguageManager.shared.currentLanguage)
        )
    }

    func testUploadReceivesTheRecordedFileURL() async throws {
        await recordAndStop(draft: "", interimPreview: "preview")

        XCTAssertEqual(mockAPIClient.lastTranscribeFileURL, recordingURL)
    }

    // MARK: - Success

    func testSuccessfulTranscriptionReplacesInputText() async throws {
        mockAPIClient.transcribeResult = TranscriptionResponse(
            text: "نماز کے بارے میں کیا کہا گیا ہے؟",
            language: "Urdu"
        )

        await recordAndStop(draft: "typed draft", interimPreview: "garbled on-device text")

        XCTAssertEqual(viewModel.inputText, "نماز کے بارے میں کیا کہا گیا ہے؟")
        XCTAssertFalse(viewModel.isTranscribing)
        XCTAssertNil(viewModel.voiceInputError)
    }

    func testTranscribingFlagIsClearedAfterUpload() async throws {
        XCTAssertFalse(viewModel.isTranscribing)

        await recordAndStop(draft: "", interimPreview: "preview")

        XCTAssertFalse(viewModel.isTranscribing, "isTranscribing must not stay latched after the upload settles")
    }

    func testRecordingIsDiscardedAfterSuccessfulUpload() async throws {
        await recordAndStop(draft: "", interimPreview: "preview")

        XCTAssertEqual(mockVoiceInputManager.discardRecordingCallCount, 1, "Temp recording must not leak in tmp")
    }

    func testEmptyServerTranscriptRestoresDraftRatherThanBlankingComposer() async throws {
        mockAPIClient.transcribeResult = TranscriptionResponse(text: "   ", language: "en")

        await recordAndStop(draft: "typed draft", interimPreview: "preview")

        XCTAssertEqual(viewModel.inputText, "typed draft")
    }

    func testNoCapturedAudioKeepsOnDevicePreview() async throws {
        await recordAndStop(draft: "typed draft", interimPreview: "on-device preview", capturedAudio: false)

        XCTAssertEqual(mockAPIClient.transcribeCallCount, 0, "Nothing to upload without a recorded file")
        XCTAssertEqual(viewModel.inputText, "on-device preview", "Should degrade to preview-only, not to an error")
        XCTAssertNil(viewModel.voiceInputError)
    }

    // MARK: - Failure Restores The Draft

    func testFailedTranscriptionRestoresDraftNotInterimPreview() async throws {
        mockAPIClient.transcribeError = NetworkError.httpError(statusCode: 500)

        await recordAndStop(draft: "a question I typed by hand", interimPreview: "garbage from the recognizer")

        XCTAssertEqual(
            viewModel.inputText,
            "a question I typed by hand",
            "A failed transcription must restore the pre-recording draft, not leave the interim preview behind"
        )
        XCTAssertEqual(viewModel.voiceInputError, .transcriptionFailed)
        XCTAssertEqual(mockVoiceInputManager.discardRecordingCallCount, 1, "Temp recording must be cleaned up on failure too")
    }

    // MARK: - Status Code Mapping

    func testPayloadTooLargeMapsToRecordingTooLong() async throws {
        mockAPIClient.transcribeError = NetworkError.httpError(statusCode: 413)

        await recordAndStop(draft: "draft", interimPreview: "preview")

        XCTAssertEqual(viewModel.voiceInputError, .recordingTooLong)
        XCTAssertEqual(viewModel.inputText, "draft")
    }

    func testRateLimitedMapsToRateLimitedErrorWithRetryAfter() async throws {
        mockAPIClient.transcribeError = NetworkError.rateLimited(retryAfter: 42)

        await recordAndStop(draft: "draft", interimPreview: "preview")

        XCTAssertEqual(viewModel.voiceInputError, .transcriptionRateLimited(retryAfter: 42))
    }

    func testRateLimitedWithoutRetryAfterHeaderStillMaps() async throws {
        mockAPIClient.transcribeError = NetworkError.httpError(statusCode: 429)

        await recordAndStop(draft: "draft", interimPreview: "preview")

        XCTAssertEqual(viewModel.voiceInputError, .transcriptionRateLimited(retryAfter: nil))
    }

    func testUpstreamFailuresMapToRetryableTranscriptionFailed() async throws {
        for statusCode in [500, 502, 504] {
            mockAPIClient.reset()
            mockVoiceInputManager.recordedFileURL = nil
            mockAPIClient.transcribeError = NetworkError.httpError(statusCode: statusCode)

            await recordAndStop(draft: "draft", interimPreview: "preview")

            XCTAssertEqual(viewModel.voiceInputError, .transcriptionFailed, "status \(statusCode)")
        }
    }

    func testOfflineMapsToNetworkUnavailable() async throws {
        mockAPIClient.transcribeError = NetworkError.noConnection

        await recordAndStop(draft: "draft", interimPreview: "preview")

        XCTAssertEqual(viewModel.voiceInputError, .transcriptionNetworkUnavailable)
    }

    // MARK: - 503 Latches The Mic Off

    func testServiceUnavailableSetsVoiceInputUnavailableFlag() async throws {
        XCTAssertFalse(viewModel.isVoiceInputUnavailable)
        mockAPIClient.transcribeError = NetworkError.httpError(statusCode: 503)

        await recordAndStop(draft: "draft", interimPreview: "preview")

        XCTAssertEqual(viewModel.voiceInputError, .transcriptionServiceUnavailable)
        XCTAssertTrue(viewModel.isVoiceInputUnavailable, "503 should hide the mic for the rest of the session")
    }

    func testVoiceInputIsNotStartedOnceServiceIsUnavailable() async throws {
        mockAPIClient.transcribeError = NetworkError.httpError(statusCode: 503)
        await recordAndStop(draft: "draft", interimPreview: "preview")
        XCTAssertTrue(viewModel.isVoiceInputUnavailable)

        let startsBefore = mockVoiceInputManager.startRecordingCallCount
        await viewModel.startVoiceInput()

        XCTAssertEqual(
            mockVoiceInputManager.startRecordingCallCount,
            startsBefore,
            "Recording should not start again once the service reported 503"
        )
    }
}

// MARK: - Multipart Body

/// Exercises the real `APIClient` over `MockURLProtocol` so the wire format is asserted,
/// not just the call.
final class TranscriptionMultipartTests: XCTestCase {

    private var session: URLSession!
    private var audioURL: URL!

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)

        audioURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        try Data("PRETEND-AAC-PAYLOAD".utf8).write(to: audioURL)

        MockURLProtocol.requestHandler = nil
        MockURLProtocol.error = nil
    }

    override func tearDownWithError() throws {
        if let audioURL {
            try? FileManager.default.removeItem(at: audioURL)
        }
        audioURL = nil
        session = nil
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.error = nil
    }

    private func makeClient(
        authTokenProvider: (() -> String?)? = nil,
        authRefreshHandler: (() async -> Bool)? = nil
    ) -> APIClient {
        APIClient(
            baseURL: URL(string: "https://test.api.com")!,
            session: session,
            authTokenProvider: authTokenProvider,
            authRefreshHandler: authRefreshHandler
        )
    }

    private static func successPayload(text: String = "hello", language: String? = "en") -> Data {
        var json: [String: Any] = ["text": text]
        if let language { json["language"] = language }
        return (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
    }

    /// `MockURLProtocol` hands a URLProtocol the body as `httpBodyStream`, never
    /// `httpBody`, so it has to be drained.
    private static func requestBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }
        stream.open()
        defer { stream.close() }
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        var data = Data()
        while true {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 { data.append(buffer, count: read) } else { break }
        }
        return data
    }

    private static func boundary(from request: URLRequest) throws -> String {
        let contentType = try XCTUnwrap(request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertTrue(
            contentType.hasPrefix("multipart/form-data; boundary="),
            "Unexpected Content-Type: \(contentType)"
        )
        return String(contentType.dropFirst("multipart/form-data; boundary=".count))
    }

    func testMultipartBodyContainsFilePartAndLanguagePart() async throws {
        var capturedRequest: URLRequest?
        var capturedBody: Data?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            capturedBody = Self.requestBody(from: request)
            return (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                Self.successPayload(text: "نماز", language: "Urdu")
            )
        }

        let response = try await makeClient().transcribe(audioFileURL: audioURL, language: "ur")

        XCTAssertEqual(response.text, "نماز")
        // Decoded but never branched on: the backend returns "Urdu"/"ur"/"English" for this.
        XCTAssertEqual(response.language, "Urdu")

        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(request.url?.path, "/api/transcribe")
        XCTAssertEqual(request.httpMethod, "POST")

        let boundary = try Self.boundary(from: request)
        XCTAssertFalse(boundary.isEmpty)

        let body = try XCTUnwrap(capturedBody)
        let text = try XCTUnwrap(String(data: body, encoding: .utf8))

        XCTAssertTrue(text.hasPrefix("--\(boundary)\r\n"), "Body should open with the boundary delimiter")
        XCTAssertTrue(text.hasSuffix("--\(boundary)--\r\n"), "Body should be closed by the terminating boundary")

        XCTAssertTrue(
            text.contains("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n"),
            "Missing file part"
        )
        XCTAssertTrue(text.contains("Content-Type: audio/m4a\r\n"), "File part must declare an audio/* content type")
        XCTAssertTrue(text.contains("PRETEND-AAC-PAYLOAD"), "File bytes should be inlined verbatim")

        XCTAssertTrue(
            text.contains("Content-Disposition: form-data; name=\"language\"\r\n\r\nur\r\n"),
            "Missing language part"
        )
    }

    func testMultipartBodyOmitsLanguagePartWhenHintIsNil() async throws {
        var capturedBody: Data?

        MockURLProtocol.requestHandler = { request in
            capturedBody = Self.requestBody(from: request)
            return (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                Self.successPayload()
            )
        }

        _ = try await makeClient().transcribe(audioFileURL: audioURL, language: nil)

        let body = try XCTUnwrap(capturedBody)
        let text = try XCTUnwrap(String(data: body, encoding: .utf8))
        XCTAssertFalse(text.contains("name=\"language\""), "No hint means no language part at all")
        XCTAssertTrue(text.contains("name=\"file\""))
    }

    func testRetryAfterHeaderIsSurfacedOn429() async throws {
        MockURLProtocol.requestHandler = { request in
            (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 429,
                    httpVersion: nil,
                    headerFields: ["Retry-After": "37"]
                )!,
                Data("{\"detail\":\"rate limited\"}".utf8)
            )
        }

        do {
            _ = try await makeClient().transcribe(audioFileURL: audioURL, language: "en")
            XCTFail("Expected a rate-limit error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .rateLimited(retryAfter: 37))
        }
    }

    func testNonIntegerRetryAfterYieldsNilRetryAfter() async throws {
        MockURLProtocol.requestHandler = { request in
            (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 429,
                    httpVersion: nil,
                    headerFields: ["Retry-After": "Wed, 21 Oct 2026 07:28:00 GMT"]
                )!,
                Data()
            )
        }

        do {
            _ = try await makeClient().transcribe(audioFileURL: audioURL, language: "en")
            XCTFail("Expected a rate-limit error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .rateLimited(retryAfter: nil))
        }
    }

    func testOtherStatusCodesSurfaceAsHTTPError() async throws {
        for statusCode in [400, 413, 500, 503] {
            MockURLProtocol.requestHandler = { request in
                (
                    HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!,
                    Data()
                )
            }

            do {
                _ = try await makeClient().transcribe(audioFileURL: audioURL, language: "en")
                XCTFail("Expected an error for status \(statusCode)")
            } catch let error as NetworkError {
                XCTAssertEqual(error, .httpError(statusCode: statusCode))
            }
        }
    }

    /// `/api/transcribe` is public. A 401 must surface as-is rather than kicking off the
    /// token-refresh-and-retry path, which would double the request and mask the failure.
    func testUnauthorizedDoesNotTriggerTokenRefreshRetry() async throws {
        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            return (
                HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!,
                Data()
            )
        }

        let refreshCalled = RefreshFlag()
        let client = makeClient(
            authTokenProvider: { "a-valid-looking-token" },
            authRefreshHandler: {
                await refreshCalled.markCalled()
                return true
            }
        )

        do {
            _ = try await client.transcribe(audioFileURL: audioURL, language: "en")
            XCTFail("Expected a 401")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .httpError(statusCode: 401))
        }

        XCTAssertEqual(requestCount, 1, "Public endpoint must not be retried after a refresh")
        let wasCalled = await refreshCalled.value
        XCTAssertFalse(wasCalled, "The auth refresh handler must not run for a public endpoint")
    }

    func testNoAuthorizationHeaderIsSentEvenWhenATokenExists() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                Self.successPayload()
            )
        }

        let client = makeClient(authTokenProvider: { "a-valid-looking-token" })
        _ = try await client.transcribe(audioFileURL: audioURL, language: "en")

        let request = try XCTUnwrap(capturedRequest)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }
}

/// Tiny actor so the escaping refresh closure can record a call without a data race.
private actor RefreshFlag {
    private(set) var value = false
    func markCalled() { value = true }
}
