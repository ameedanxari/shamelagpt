//
//  VoiceInputManager.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Speech
import AVFoundation
import Combine

/// Manages voice input and speech recognition
@MainActor
final class VoiceInputManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var transcribedText: String = ""
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published private(set) var error: VoiceInputError?

    // MARK: - Recording Artefact

    /// Local `.m4a` written alongside the live SFSpeechRecognizer preview, populated when
    /// recording stops. `nil` when nothing usable was captured (simulation/unit-test modes,
    /// or a write failure) — callers must treat that as "no upload", not as an error.
    /// Ownership passes to the caller, which must call `discardRecording()` when done.
    private(set) var recordedFileURL: URL?

    /// Hard cap on a single recording. Mirrors the web client. At AAC ~64 kbps two minutes
    /// is roughly 1 MB, comfortably under the backend's 20 MB body limit.
    static let maxRecordingDuration: TimeInterval = 120

    // MARK: - Private Properties

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var recordingWriter: RecordingWriter?
    private var maxDurationTimer: Timer?
    private var environment: [String: String] { ProcessInfo.processInfo.environment }
    private var isRunningUnitTests: Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }

    private var isSimulatingPermissionDenied: Bool {
        environment["SIMULATE_SPEECH_PERMISSION_DENIED"] == "true"
    }

    private var isSimulatingPermissionGranted: Bool {
        environment["SIMULATE_SPEECH_PERMISSION_GRANTED"] == "true"
    }

    private var isSimulatingLanguageUnavailable: Bool {
        environment["SIMULATE_SPEECH_LANGUAGE_UNAVAILABLE"] == "true"
    }

    private var isSimulatingRecognitionError: Bool {
        environment["SIMULATE_SPEECH_ERROR"] == "true"
    }

    private var simulatedTranscription: String? {
        environment["SIMULATE_SPEECH_TRANSCRIPTION"]
    }

    private var shouldAutoStopSimulation: Bool {
        environment["SIMULATE_SPEECH_AUTO_STOP"] != "false"
    }

    // MARK: - Initialization

    override init() {
        super.init()
        // Default to English, will be updated when locale is specified
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        AppLogger.voiceInput.logDebug(
            "VoiceInputManager initialized appLocale=\(Locale.current.identifier) preferredLanguages=\(Locale.preferredLanguages.joined(separator: ","))"
        )
    }

    // MARK: - Public Methods

    /// Requests speech recognition permission
    func requestPermission() async -> Bool {
        AppLogger.voiceInput.logDebug(
            "Requesting speech recognition permission currentSpeechStatus=\(authorizationStatus.rawValue) currentMicStatus=\(AVAudioSession.sharedInstance().recordPermission.debugLabel)"
        )

        if isSimulatingPermissionDenied {
            await MainActor.run {
                self.authorizationStatus = .denied
                self.error = .permissionDenied
            }
            return false
        }

        if isSimulatingPermissionGranted {
            await MainActor.run {
                self.authorizationStatus = .authorized
                self.error = nil
            }
            return true
        }

        if isRunningUnitTests {
            await MainActor.run {
                self.authorizationStatus = .authorized
                self.error = nil
            }
            return true
        }

        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        await MainActor.run {
            self.authorizationStatus = speechStatus
        }

        AppLogger.voiceInput.logInfo("Speech recognition authorization status: \(speechStatus.rawValue)")

        guard speechStatus == .authorized else {
            await MainActor.run {
                self.error = .permissionDenied
            }
            AppLogger.voiceInput.logWarning("Speech recognition permission denied")
            return false
        }

        // Request microphone permission (iOS 15 compatible)
        AppLogger.voiceInput.logDebug("Requesting microphone permission")
        let microphoneStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        AppLogger.voiceInput.logInfo("Microphone permission granted: \(microphoneStatus)")

        guard microphoneStatus else {
            await MainActor.run {
                self.error = .microphonePermissionDenied
            }
            AppLogger.voiceInput.logWarning("Microphone permission denied")
            return false
        }

        return true
    }

    /// Starts recording with the specified locale
    /// - Parameter locale: The locale for speech recognition (e.g., en-US, ar-SA)
    func startRecording(locale: Locale) async throws {
        AppLogger.voiceInput.logInfo("Starting recording locale=\(locale.identifier) diagnostics=\(runtimeDiagnostics(for: locale))")

        // Cancel any ongoing recognition task
        if recognitionTask != nil {
            AppLogger.voiceInput.logWarning("Existing recognition task found, stopping it first")
            stopRecording()
        }

        // A new take invalidates the previous one; drop its temp file rather than leaking it.
        discardRecording()

        // Check authorization
        guard authorizationStatus == .authorized else {
            AppLogger.voiceInput.logError("Cannot start recording - not authorized")
            throw VoiceInputError.permissionDenied
        }

        if isSimulatingLanguageUnavailable {
            throw VoiceInputError.recognizerNotAvailable
        }

        if isSimulatingRecognitionError {
            isRecording = true
            let message = environment["SIMULATE_SPEECH_ERROR_MESSAGE"] ?? "Simulated speech recognition failure"
            error = .recognitionFailed(message)
            isRecording = false
            throw VoiceInputError.recognitionFailed(message)
        }

        if let simulatedTranscription {
            isRecording = true
            transcribedText = simulatedTranscription
            error = nil
            if shouldAutoStopSimulation {
                isRecording = false
            }
            return
        }

        if isRunningUnitTests {
            isRecording = true
            transcribedText = ""
            error = nil
            return
        }

        // Update recognizer with specified locale
        speechRecognizer = SFSpeechRecognizer(locale: locale)

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            AppLogger.voiceInput.logError("Speech recognizer not available locale=\(locale.identifier) diagnostics=\(runtimeDiagnostics(for: locale))")
            throw VoiceInputError.recognizerNotAvailable
        }

        let supportsOnDevice = speechRecognizer.supportsOnDeviceRecognition
        AppLogger.voiceInput.logDebug(
            "Speech recognizer initialized available=true locale=\(speechRecognizer.locale.identifier) supportsOnDevice=\(supportsOnDevice)"
        )

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        AppLogger.voiceInput.logDebug(
            "Audio session pre-config category=\(audioSession.category.rawValue) mode=\(audioSession.mode.rawValue) sampleRate=\(audioSession.sampleRate)"
        )
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        AppLogger.voiceInput.logDebug("Audio session configured successfully")

        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            AppLogger.voiceInput.logError("Failed to create recognition request")
            throw VoiceInputError.unableToCreateRequest
        }

        recognitionRequest.shouldReportPartialResults = true

        // Get the audio input node
        let inputNode = audioEngine.inputNode

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            Task { @MainActor in
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                    AppLogger.voiceInput.logDebug(
                        "Recognition callback isFinal=\(result.isFinal) transcriptionLen=\(result.bestTranscription.formattedString.count) segments=\(result.bestTranscription.segments.count)"
                    )
                    if result.isFinal {
                        AppLogger.voiceInput.logInfo("Voice transcription completed")
                    }
                }

                if let error = error {
                    let nsError = error as NSError
                    AppLogger.voiceInput.logError(
                        "Recognition task failed domain=\(nsError.domain) code=\(nsError.code) message=\(nsError.localizedDescription)",
                        error: error
                    )
                    self.error = .recognitionFailed(error.localizedDescription)
                    self.stopRecording()
                } else if result?.isFinal == true {
                    AppLogger.voiceInput.logInfo("Recognition task completed with final result")
                    self.stopRecording()
                }
            }
        }

        // Configure the microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        AppLogger.voiceInput.logDebug(
            "Installing audio tap sampleRate=\(recordingFormat.sampleRate) channels=\(recordingFormat.channelCount)"
        )

        // Same mic session feeds two consumers: the recognizer (live preview) and an
        // AVAudioFile (the artefact uploaded to the backend for the authoritative text).
        // Encoding at the tap's own sample rate/channel count keeps the file's
        // processingFormat identical to the incoming buffers, so write(from:) cannot
        // throw a format mismatch.
        let writer = RecordingWriter.make(
            sampleRate: recordingFormat.sampleRate,
            channelCount: recordingFormat.channelCount
        )
        recordingWriter = writer

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
            // `writer` is captured directly rather than through `self`: this closure runs
            // on the realtime audio thread and must never touch main-actor state.
            writer?.write(buffer)
        }

        // Start the audio engine
        audioEngine.prepare()
        try audioEngine.start()

        AppLogger.voiceInput.logInfo("Audio engine started, recording is active")

        isRecording = true
        transcribedText = ""
        error = nil

        startMaxDurationTimer()
    }

    /// Stops recording and recognition
    func stopRecording() {
        AppLogger.voiceInput.logInfo("Stopping recording audioEngineRunning=\(audioEngine.isRunning)")

        maxDurationTimer?.invalidate()
        maxDurationTimer = nil

        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            AppLogger.voiceInput.logDebug("Audio engine stopped and tap removed")
        }

        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Finalise the file BEFORE flipping isRecording: observers react to that flip and
        // immediately read `recordedFileURL`.
        if let writer = recordingWriter {
            recordedFileURL = writer.finish()
            recordingWriter = nil
            AppLogger.voiceInput.logInfo(
                "Recording finalised hasFile=\(recordedFileURL != nil) bytes=\(Self.fileSize(of: recordedFileURL))"
            )
        }

        isRecording = false

        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            AppLogger.voiceInput.logDebug("Audio session deactivated successfully")
        } catch {
            AppLogger.voiceInput.logWarning("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }

    /// Clears the transcribed text
    func clearTranscription() {
        transcribedText = ""
    }

    /// Clears the current error
    func clearError() {
        error = nil
    }

    /// Deletes the recorded temp file and forgets it. Safe to call repeatedly; callers
    /// must call it on every path (success AND failure) or tmp accumulates recordings.
    func discardRecording() {
        guard let url = recordedFileURL else { return }
        recordedFileURL = nil
        do {
            try FileManager.default.removeItem(at: url)
            AppLogger.voiceInput.logDebug("Discarded recording at \(url.lastPathComponent)")
        } catch {
            AppLogger.voiceInput.logWarning("Failed to delete recording \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    // MARK: - Duration Cap

    private func startMaxDurationTimer() {
        maxDurationTimer?.invalidate()
        maxDurationTimer = Timer.scheduledTimer(
            withTimeInterval: Self.maxRecordingDuration,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isRecording else { return }
                AppLogger.voiceInput.logInfo(
                    "Maximum recording duration (\(Int(Self.maxRecordingDuration))s) reached, stopping automatically"
                )
                self.stopRecording()
            }
        }
    }

    private static func fileSize(of url: URL?) -> Int {
        guard let url,
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int else {
            return 0
        }
        return size
    }

    private func runtimeDiagnostics(for locale: Locale) -> String {
        let supportedLocaleIds = SFSpeechRecognizer.supportedLocales().map(\.identifier).sorted()
        let hasExactLocale = supportedLocaleIds.contains(locale.identifier)
        let micPermission = AVAudioSession.sharedInstance().recordPermission.debugLabel
        return "deviceLocale=\(Locale.current.identifier)" +
            ",preferredLanguages=\(Locale.preferredLanguages.joined(separator: "|"))" +
            ",requestedLocale=\(locale.identifier)" +
            ",hasExactLocale=\(hasExactLocale)" +
            ",supportedLocaleCount=\(supportedLocaleIds.count)" +
            ",speechAuth=\(authorizationStatus.rawValue)" +
            ",micPermission=\(micPermission)"
    }
}

// MARK: - Recording Writer

/// Writes mic buffers to an `.m4a` in the temp directory.
///
/// Deliberately NOT `@MainActor`: `write(_:)` is called from the realtime audio thread by
/// the engine tap, while `finish()` is called from the main actor when recording stops.
/// An `NSLock` serialises the two — `AVAudioFile` is not thread-safe, and a concurrent
/// write/close is a use-after-free, not a recoverable error.
///
/// Every failure mode degrades to "no file to upload"; nothing here is allowed to throw
/// into the audio thread or crash the app.
private final class RecordingWriter: @unchecked Sendable {

    private let lock = NSLock()
    private let url: URL
    private var file: AVAudioFile?
    private var framesWritten: AVAudioFramePosition = 0
    private var didFail = false

    private init(url: URL, file: AVAudioFile) {
        self.url = url
        self.file = file
    }

    /// Returns `nil` (rather than throwing) if the file cannot be created, so a broken
    /// disk degrades voice input to preview-only instead of failing the whole recording.
    static func make(sampleRate: Double, channelCount: AVAudioChannelCount) -> RecordingWriter? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        do {
            let file = try AVAudioFile(forWriting: url, settings: settings)
            AppLogger.voiceInput.logDebug(
                "Recording file created name=\(url.lastPathComponent) sampleRate=\(sampleRate) channels=\(channelCount)"
            )
            return RecordingWriter(url: url, file: file)
        } catch {
            AppLogger.voiceInput.logWarning(
                "Failed to create recording file, continuing without upload: \(error.localizedDescription)"
            )
            return nil
        }
    }

    func write(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }
        guard let file else { return }
        do {
            try file.write(from: buffer)
            framesWritten += AVAudioFramePosition(buffer.frameLength)
        } catch {
            // One bad write poisons the file; stop writing but never crash the audio thread.
            self.file = nil
            didFail = true
            AppLogger.voiceInput.logWarning("Audio write failed, abandoning recording: \(error.localizedDescription)")
        }
    }

    /// Closes the file (releasing `AVAudioFile` flushes and finalises the container) and
    /// returns its URL, or `nil` if nothing usable was captured.
    func finish() -> URL? {
        lock.lock()
        defer { lock.unlock() }

        let usable = !didFail && framesWritten > 0
        file = nil

        guard usable else {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
        return url
    }
}

// MARK: - Error Types

enum VoiceInputError: LocalizedError {
    case permissionDenied
    case microphonePermissionDenied
    case recognizerNotAvailable
    case unableToCreateRequest
    case recognitionFailed(String)

    // MARK: Backend transcription (`POST /api/transcribe`)

    /// HTTP 413 — the upload exceeded the server's body limit.
    case recordingTooLong
    /// HTTP 429. `retryAfter` is seconds from the `Retry-After` header when the server sent
    /// an integer one; `nil` otherwise.
    case transcriptionRateLimited(retryAfter: Int?)
    /// HTTP 500 / 502 / 504, or anything else transient. Retryable.
    case transcriptionFailed
    /// HTTP 503 — transcription is not configured on the server. Not worth retrying this
    /// session; the caller hides the mic instead.
    case transcriptionServiceUnavailable
    /// The upload never reached the server (offline, timeout).
    case transcriptionNetworkUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission denied. Please enable it in Settings."
        case .microphonePermissionDenied:
            return "Microphone permission denied. Please enable it in Settings."
        case .recognizerNotAvailable:
            return "Speech recognizer is not available for this language."
        case .unableToCreateRequest:
            return "Unable to create speech recognition request."
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        case .recordingTooLong:
            return "Recording too long for the transcription service."
        case .transcriptionRateLimited(let retryAfter):
            if let retryAfter {
                return "Transcription rate limited. Retry after \(retryAfter) seconds."
            }
            return "Transcription rate limited. Please try again shortly."
        case .transcriptionFailed:
            return "Transcription failed. Please try again."
        case .transcriptionServiceUnavailable:
            return "Transcription service is unavailable."
        case .transcriptionNetworkUnavailable:
            return "Transcription requires an internet connection."
        }
    }

    /// User message with debug code appended (for support tickets)
    var userMessageWithCode: String {
        // Handled before the table below because it interpolates the wait into the string
        // and so cannot go through the shared messageKey path.
        if case .transcriptionRateLimited(let retryAfter) = self, let retryAfter {
            let template = LanguageManager.shared.localizedString(
                forKey: LocalizationKeys.voiceTranscriptionRateLimitedRetry
            )
            return UserErrorFormatter.format(
                message: String(format: template, String(retryAfter)),
                code: "E-VOICE-007"
            )
        }

        let messageKey: String
        let debugCode: String

        switch self {
        case .permissionDenied:
            messageKey = LocalizationKeys.voicePermissionDenied
            debugCode = "E-VOICE-001"
        case .microphonePermissionDenied:
            messageKey = LocalizationKeys.voiceMicrophonePermissionDenied
            debugCode = "E-VOICE-002"
        case .recognizerNotAvailable:
            messageKey = LocalizationKeys.voiceRecognizerNotAvailable
            debugCode = "E-VOICE-003"
        case .unableToCreateRequest:
            messageKey = LocalizationKeys.voiceUnableToCreateRequest
            debugCode = "E-VOICE-004"
        case .recognitionFailed:
            messageKey = LocalizationKeys.voiceRecognitionFailed
            debugCode = "E-VOICE-005"
        case .recordingTooLong:
            messageKey = LocalizationKeys.voiceRecordingTooLong
            debugCode = "E-VOICE-006"
        case .transcriptionRateLimited:
            messageKey = LocalizationKeys.voiceTranscriptionRateLimited
            debugCode = "E-VOICE-007"
        case .transcriptionFailed:
            messageKey = LocalizationKeys.voiceTranscriptionFailed
            debugCode = "E-VOICE-008"
        case .transcriptionServiceUnavailable:
            messageKey = LocalizationKeys.voiceTranscriptionServiceUnavailable
            debugCode = "E-VOICE-009"
        case .transcriptionNetworkUnavailable:
            messageKey = LocalizationKeys.voiceTranscriptionNetworkUnavailable
            debugCode = "E-VOICE-010"
        }

        return UserErrorFormatter.format(messageKey: messageKey, code: debugCode)
    }
}

extension VoiceInputError: Equatable {
    static func == (lhs: VoiceInputError, rhs: VoiceInputError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied):
            return true
        case (.microphonePermissionDenied, .microphonePermissionDenied):
            return true
        case (.recognizerNotAvailable, .recognizerNotAvailable):
            return true
        case (.unableToCreateRequest, .unableToCreateRequest):
            return true
        case (.recognitionFailed(let lhsMessage), .recognitionFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.recordingTooLong, .recordingTooLong):
            return true
        case (.transcriptionRateLimited(let lhsRetry), .transcriptionRateLimited(let rhsRetry)):
            return lhsRetry == rhsRetry
        case (.transcriptionFailed, .transcriptionFailed):
            return true
        case (.transcriptionServiceUnavailable, .transcriptionServiceUnavailable):
            return true
        case (.transcriptionNetworkUnavailable, .transcriptionNetworkUnavailable):
            return true
        default:
            return false
        }
    }
}

private extension AVAudioSession.RecordPermission {
    var debugLabel: String {
        switch self {
        case .undetermined:
            return "undetermined"
        case .denied:
            return "denied"
        case .granted:
            return "granted"
        @unknown default:
            return "unknown"
        }
    }
}
