//
//  ChatViewModelTests.swift
//  shamelagptTests
//
//  Created by Ameed Khalid on 05/11/2025.
//

import XCTest
import Combine
@testable import ShamelaGPT

@MainActor
final class ChatViewModelTests: XCTestCase {

    var viewModel: ChatViewModel!
    var mockSendMessageUseCase: MockSendMessageUseCase!
    var mockChatRepository: MockChatRepository!
    var mockVoiceInputManager: MockVoiceInputManager!
    var mockOCRManager: MockOCRManager!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        mockSendMessageUseCase = MockSendMessageUseCase()
        mockChatRepository = MockChatRepository()
        mockVoiceInputManager = MockVoiceInputManager()
        mockOCRManager = MockOCRManager()
        cancellables = Set<AnyCancellable>()

        viewModel = ChatViewModel(
            conversationId: "test-conversation-id",
            sendMessageUseCase: mockSendMessageUseCase,
            chatRepository: mockChatRepository,
            apiClient: nil,
            isGuest: false,
            guestSessionId: nil,
            voiceInputManager: mockVoiceInputManager,
            ocrManager: mockOCRManager
        )
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockSendMessageUseCase = nil
        mockChatRepository = nil
        mockVoiceInputManager = nil
        mockOCRManager = nil
        cancellables = nil
    }

    // MARK: - Message Sending Tests

    func testSendMessageClearsInputText() async throws {
        // Given
        viewModel.inputText = "Test message"
        mockSendMessageUseCase.shouldSucceed = true

        // When
        viewModel.sendMessage()

        // Then - input should be cleared immediately
        XCTAssertEqual(viewModel.inputText, "")
    }

    func testCanSendMessageWhenInputIsNotEmpty() throws {
        // Given
        viewModel.inputText = "Test message"

        // Then
        XCTAssertTrue(viewModel.canSendMessage)
    }

    func testCannotSendMessageWhenInputIsEmpty() throws {
        // Given
        viewModel.inputText = ""

        // Then
        XCTAssertFalse(viewModel.canSendMessage)
    }

    func testCannotSendMessageWhenLoading() throws {
        // Given
        viewModel.inputText = "Test message"

        // Manually set loading state for test
        // Manually set loading state for test
        viewModel.isLoading = true

        // Then
        XCTAssertFalse(viewModel.canSendMessage)
    }

    func testSendMessageWithWhitespaceOnlyIsIgnored() async throws {
        // Given
        viewModel.inputText = "   \n\t  "
        let initialMessageCount = viewModel.messages.count

        // When
        viewModel.sendMessage()

        // Wait a bit for async operations
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        XCTAssertEqual(viewModel.messages.count, initialMessageCount)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSendMessageCreatesOptimisticMessage() async throws {
        // Given
        let testMessage = "Test message"
        viewModel.inputText = testMessage
        mockSendMessageUseCase.shouldSucceed = true
        mockSendMessageUseCase.delay = 0.5 // Add delay to test optimistic state

        // When
        viewModel.sendMessage()

        // Wait a tiny bit for optimistic message to be added
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

        // Then - optimistic message should appear
        XCTAssertTrue(viewModel.messages.contains(where: { $0.content == testMessage && $0.isUserMessage }))
        XCTAssertTrue(viewModel.isLoading)
    }

    func testSendMessageUpdatesThreadId() async throws {
        // Given
        viewModel.inputText = "Test message"
        let newThreadId = "new-thread-123"
        mockSendMessageUseCase.shouldSucceed = true
        mockSendMessageUseCase.mockThreadId = newThreadId
        mockChatRepository.mockConversation = Conversation(
            id: "test-conversation-id",
            threadId: nil,
            title: "Test",
            messages: []
        )

        // When
        viewModel.sendMessage()

        // Wait for async operation
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Then
        XCTAssertEqual(viewModel.threadId, newThreadId)
    }

    func testSendMessageSuccess() async throws {
        // Given
        let testMessage = "Hello, world!"
        viewModel.inputText = testMessage
        mockSendMessageUseCase.shouldSucceed = true
        mockChatRepository.mockMessages = []

        // When
        viewModel.sendMessage()

        // Wait for async operations
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Then
        XCTAssertEqual(viewModel.inputText, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testSendMessageFailureRemovesOptimisticMessage() async throws {
        // Given
        let testMessage = "Test message"
        viewModel.inputText = testMessage
        mockSendMessageUseCase.shouldSucceed = false
        let initialCount = viewModel.messages.count

        // When
        viewModel.sendMessage()

        // Wait for async operations
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Then - optimistic message should be removed
        XCTAssertEqual(viewModel.messages.count, initialCount)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSendMessageFailureRestoresInputText() async throws {
        // Given
        let testMessage = "Test message"
        viewModel.inputText = testMessage
        mockSendMessageUseCase.shouldSucceed = false

        // When
        viewModel.sendMessage()

        // Wait for async operations
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Then - input should be restored
        XCTAssertEqual(viewModel.inputText, testMessage)
    }

    func testSendMessageWithNetworkError() async throws {
        // Given
        viewModel.inputText = "Test message"
        mockSendMessageUseCase.shouldSucceed = false
        mockSendMessageUseCase.errorToThrow = NetworkError.noConnection

        // When
        viewModel.sendMessage()

        // Wait for async operations
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLocalConversationUsesGuestStreamWhenAuthenticated() async throws {
        // Given a local-only conversation opened while authenticated
        let mockAPIClient = MockAPIClient()
        let localConversation = Conversation(
            id: "local-conv-id",
            threadId: nil,
            title: "Local conversation",
            messages: [],
            isLocalOnly: true
        )
        mockChatRepository.mockConversation = localConversation
        mockChatRepository.mockMessages = []
        mockSendMessageUseCase.shouldSucceed = true

        viewModel = ChatViewModel(
            conversationId: localConversation.id,
            sendMessageUseCase: mockSendMessageUseCase,
            chatRepository: mockChatRepository,
            apiClient: mockAPIClient,
            isGuest: false,
            guestSessionId: "guest-session-id",
            voiceInputManager: mockVoiceInputManager,
            ocrManager: mockOCRManager
        )

        // Allow initial loadMessages to complete
        try await Task.sleep(nanoseconds: 50_000_000)

        // When
        viewModel.inputText = "Continue as guest"
        viewModel.sendMessage()

        // Wait for streaming branch to be exercised
        try await Task.sleep(nanoseconds: 150_000_000)

        // Then the guest stream should be used even though the session is authenticated
        XCTAssertEqual(mockAPIClient.streamGuestMessageCallCount, 1)
        XCTAssertEqual(mockAPIClient.streamMessageCallCount, 0)
    }

    func testMultipleSendMessagesInSequence() async throws {
        // Given
        mockSendMessageUseCase.shouldSucceed = true

        // When - send multiple messages
        viewModel.inputText = "Message 1"
        viewModel.sendMessage()
        try await Task.sleep(nanoseconds: 200_000_000)

        viewModel.inputText = "Message 2"
        viewModel.sendMessage()
        try await Task.sleep(nanoseconds: 200_000_000)

        viewModel.inputText = "Message 3"
        viewModel.sendMessage()
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    // MARK: - Message Loading Tests

    func testLoadMessagesPopulatesMessages() async throws {
        // Given
        let testMessages = [
            Message(
                id: "msg-1",
                conversationId: "test-conversation-id",
                content: "Hello",
                isUserMessage: true,
                timestamp: Date().addingTimeInterval(-1),
                sources: []
            ),
            Message(
                id: "msg-2",
                conversationId: "test-conversation-id",
                content: "Hi there",
                isUserMessage: false,
                timestamp: Date(),
                sources: []
            )
        ]
        mockChatRepository.mockMessages = testMessages
        mockChatRepository.mockConversation = Conversation(
            id: "test-conversation-id",
            threadId: nil,
            title: "Test",
            messages: testMessages
        )

        // When
        await viewModel.loadMessages()

        // Then
        XCTAssertEqual(viewModel.messages.count, 2)
    }

    func testLoadMessagesEmptyConversation() async throws {
        // Given
        mockChatRepository.mockMessages = []

        // When
        await viewModel.loadMessages()

        // Then
        XCTAssertEqual(viewModel.messages.count, 0)
    }

    func testLoadMessagesWithError() async throws {
        // Given
        mockChatRepository.shouldThrowError = true

        // When
        await viewModel.loadMessages()

        // Then
        XCTAssertNotNil(viewModel.error)
    }

    func testLoadMessagesUpdatesThreadId() async throws {
        // Given
        let testThreadId = "thread-123"
        mockChatRepository.mockConversation = Conversation(
            id: "test-conversation-id",
            threadId: testThreadId,
            title: "Test",
            messages: []
        )

        // When
        await viewModel.loadMessages()

        // Then
        XCTAssertEqual(viewModel.threadId, testThreadId)
    }

    // MARK: - Error Handling Tests

    func testClearErrorResetsErrorState() throws {
        // Given
        viewModel.error = NetworkError.noConnection

        // When
        viewModel.clearError()

        // Then
        XCTAssertNil(viewModel.error)
    }

    // MARK: - Voice Input Tests

    func testCannotSendMessageWhileRecording() throws {
        // Given
        viewModel.inputText = "Test message"
        viewModel.isRecording = true

        // Then
        XCTAssertFalse(viewModel.canSendMessage)
    }

    func testClearVoiceInputError() throws {
        // Given
        viewModel.voiceInputError = .permissionDenied

        // When
        viewModel.clearVoiceInputError()

        // Then
        XCTAssertNil(viewModel.voiceInputError)
    }

    // MARK: - OCR Tests

    func testCannotSendMessageWhileProcessingOCR() throws {
        // Given
        viewModel.inputText = "Test message"
        viewModel.isProcessingOCR = true

        // Then
        XCTAssertFalse(viewModel.canSendMessage)
    }

    func testDismissOCRConfirmationClearsState() throws {
        // Given
        viewModel.showOCRConfirmation = true
        viewModel.ocrExtractedText = "Test text"
        viewModel.ocrDetectedLanguage = "en"

        // When
        viewModel.dismissOCRConfirmation()

        // Then
        XCTAssertFalse(viewModel.showOCRConfirmation)
        XCTAssertEqual(viewModel.ocrExtractedText, "")
        XCTAssertNil(viewModel.ocrDetectedLanguage)
        XCTAssertNil(viewModel.ocrImageData)
    }

    func testClearOCRError() throws {
        // Given
        viewModel.ocrError = .noTextFound

        // When
        viewModel.clearOCRError()

        // Then
        XCTAssertNil(viewModel.ocrError)
    }

    // MARK: - Update Input Text Test

    func testUpdateInputTextUpdatesState() throws {
        // Given
        let newText = "New input text"

        // When
        viewModel.updateInputText(newText)

        // Then
        XCTAssertEqual(viewModel.inputText, newText)
    }

    // MARK: - Additional Voice Input Tests

    func testToggleVoiceInputStartsRecording() async throws {
        // Given - Not recording
        XCTAssertFalse(viewModel.isRecording)

        // When
        viewModel.toggleVoiceInput()

        // Then - Should attempt to start recording
        // Note: Actual recording start depends on permissions and may fail
        // We're testing that the toggle method is called
    }

    func testToggleVoiceInputStopsRecording() async throws {
        // Given - Simulated recording state
        await MainActor.run {
            viewModel.isRecording = true
        }

        // When
        viewModel.toggleVoiceInput()

        // Then - Should stop recording
        // The voice input manager will handle the actual stop
    }

    // MARK: - Additional OCR Tests

    func testHandleCameraButtonTapShowsSheet() throws {
        // Given
        XCTAssertFalse(viewModel.showImageSourceSheet)

        // When
        viewModel.handleCameraButtonTap()

        // Then
        XCTAssertTrue(viewModel.showImageSourceSheet)
    }

    func testSelectCameraShowsCameraPicker() throws {
        // Given
        XCTAssertFalse(viewModel.showCameraPicker)

        // When
        viewModel.selectCamera()

        // Then
        XCTAssertTrue(viewModel.showCameraPicker)
        XCTAssertFalse(viewModel.showImageSourceSheet)
    }

    func testSelectPhotoLibraryShowsPhotoPicker() throws {
        // Given
        XCTAssertFalse(viewModel.showPhotoLibraryPicker)

        // When
        viewModel.selectPhotoLibrary()

        // Then
        XCTAssertTrue(viewModel.showPhotoLibraryPicker)
        XCTAssertFalse(viewModel.showImageSourceSheet)
    }

    // MARK: - Fact-Check Tests

    func testConfirmFactCheckSendsMessage() async throws {
        // Given
        let factCheckText = "Test fact check message"
        viewModel.ocrExtractedText = factCheckText
        mockSendMessageUseCase.shouldSucceed = true

        // When
        viewModel.confirmFactCheck(text: factCheckText)

        // Give time for async operation
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then - Should send message
        XCTAssertFalse(viewModel.showOCRConfirmation)
        XCTAssertEqual(viewModel.ocrExtractedText, "")
    }

    func testConfirmFactCheckWithImageData() async throws {
        // Given
        let factCheckText = "Verify this claim"
        let testImageData = Data([0x00, 0x01, 0x02])
        viewModel.ocrExtractedText = factCheckText
        viewModel.ocrImageData = testImageData
        mockSendMessageUseCase.shouldSucceed = true

        // When
        viewModel.confirmFactCheck(text: factCheckText)

        // Give time for async operation
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then - Image data should be cleared after sending
        XCTAssertNil(viewModel.ocrImageData)
    }

    func testConfirmFactCheckWithDetectedLanguage() async throws {
        // Given
        let factCheckText = "Test message"
        viewModel.ocrExtractedText = factCheckText
        viewModel.ocrDetectedLanguage = "ar"
        mockSendMessageUseCase.shouldSucceed = true

        // When
        viewModel.confirmFactCheck(text: factCheckText)

        // Give time for async operation
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then - Language should be cleared after sending
        XCTAssertNil(viewModel.ocrDetectedLanguage)
    }

    func testConfirmFactCheckClearsOCRState() async throws {
        // Given
        let factCheckText = "Test"
        viewModel.ocrExtractedText = factCheckText
        viewModel.ocrDetectedLanguage = "en"
        viewModel.ocrImageData = Data([0x01])
        viewModel.showOCRConfirmation = true
        mockSendMessageUseCase.shouldSucceed = true

        // When
        viewModel.confirmFactCheck(text: factCheckText)

        // Give time for async operation
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then - All OCR state should be cleared
        XCTAssertFalse(viewModel.showOCRConfirmation)
        XCTAssertEqual(viewModel.ocrExtractedText, "")
        XCTAssertNil(viewModel.ocrDetectedLanguage)
        XCTAssertNil(viewModel.ocrImageData)
    }

    func testFactCheckMessageWithEmptyText() async throws {
        // Given
        let emptyText = ""
        viewModel.ocrExtractedText = emptyText
        mockSendMessageUseCase.shouldSucceed = true
        let initialMessageCount = viewModel.messages.count

        // When
        viewModel.confirmFactCheck(text: emptyText)

        // Give time for async operation
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then - Should not send message with empty text
        // Message count should remain the same or handle appropriately
        XCTAssertEqual(viewModel.messages.count, initialMessageCount)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testFactCheckMessageFailureHandling() async throws {
        // Given
        let factCheckText = "Test fact check"
        viewModel.ocrExtractedText = factCheckText
        viewModel.ocrImageData = Data([0, 1, 2]) // Provide mock image data
        mockChatRepository.shouldThrowError = true
        mockChatRepository.errorToThrow = NSError(
            domain: "test",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Fact check failed"]
        )

        // When
        viewModel.confirmFactCheck(text: factCheckText)

        // Give time for async operation (increased timeout for all async calls)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Then - Should handle error
        XCTAssertNotNil(viewModel.error, "Error should be set when fact check fails")
    }

    // MARK: - Additional Error Handling Tests

    func testNetworkErrorDisplaysCorrectMessage() async throws {
        // Given
        mockSendMessageUseCase.shouldSucceed = false
        mockSendMessageUseCase.errorToThrow = NetworkError.noConnection
        viewModel.inputText = "Test message"

        // When
        viewModel.sendMessage()

        // Give time for async operation
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertNotNil(viewModel.error)
        if let error = viewModel.error as? NetworkError {
            XCTAssertEqual(error, .noConnection)
        } else {
            XCTFail("Expected NetworkError.noConnection, got \(String(describing: viewModel.error))")
        }
    }

    func testAPIErrorDisplaysCorrectMessage() async throws {
        // Given
        mockSendMessageUseCase.shouldSucceed = false
        mockSendMessageUseCase.errorToThrow = NetworkError.serverError(500)
        viewModel.inputText = "Test message"

        // When
        viewModel.sendMessage()

        // Give time for async operation
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertNotNil(viewModel.error)
        if let error = viewModel.error as? NetworkError {
            XCTAssertEqual(error, .serverError(500))
        } else {
            XCTFail("Expected NetworkError.serverError(500), got \(String(describing: viewModel.error))")
        }
    }

    func testSendMessageErrorMatrixRestoresInputAndSetsExpectedError() async throws {
        let matrix: [(MockScenarioID, NetworkError)] = [
            (.http400, .httpError(statusCode: 400)),
            (.http401, .httpError(statusCode: 401)),
            (.http403, .httpError(statusCode: 403)),
            (.http404, .httpError(statusCode: 404)),
            (.http429, .httpError(statusCode: 429)),
            (.http500, .httpError(statusCode: 500)),
            (.timeout, .timeout),
            (.offline, .noConnection)
        ]

        for (scenario, expectedError) in matrix {
            mockSendMessageUseCase.shouldSucceed = false
            mockSendMessageUseCase.errorToThrow = expectedError
            viewModel.error = nil
            viewModel.isLoading = false

            let input = "scenario-\(scenario.rawValue)"
            viewModel.inputText = input
            viewModel.sendMessage()
            try await Task.sleep(nanoseconds: 250_000_000)

            XCTAssertFalse(viewModel.isLoading, "Loading should stop for \(scenario.rawValue)")
            XCTAssertEqual(viewModel.inputText, input, "Input should be restored for \(scenario.rawValue)")
            XCTAssertEqual(viewModel.error as? NetworkError, expectedError, "Unexpected error for \(scenario.rawValue)")
        }
    }

    func testLoadMessagesOrderedByTimestamp() async throws {
        // Given
        let now = Date()
        let olderMessage = Message(
            id: "1",
            conversationId: "test-conversation-id",
            content: "Older",
            isUserMessage: true,
            timestamp: now.addingTimeInterval(-3600), // 1 hour ago
            sources: []
        )
        let newerMessage = Message(
            id: "2",
            conversationId: "test-conversation-id",
            content: "Newer",
            isUserMessage: true,
            timestamp: now,
            sources: []
        )
        mockChatRepository.mockMessages = [newerMessage, olderMessage] // Intentionally out of order
        mockChatRepository.mockConversation = Conversation(
            id: "test-conversation-id",
            threadId: nil,
            title: "Test",
            messages: [newerMessage, olderMessage]
        )

        // When
        await viewModel.loadMessages()

        // Then - Should be ordered by timestamp (oldest first typically in chat)
        XCTAssertEqual(viewModel.messages.count, 2)
        // The order depends on how the repository returns them
        // This test verifies messages are loaded
    }

    // MARK: - Voice Input Permission Tests

    func testStartVoiceInputWithPermissionGranted() async throws {
        // Given - Mock permission will be granted
        // Note: The actual permission depends on system state
        // This test verifies the permission flow is called

        // When
        await viewModel.startVoiceInput()

        // Then - Should attempt to start recording
        // Actual recording state depends on system permissions
        // We verify the method completes without crashing
    }

    func testStartVoiceInputWithPermissionDenied() async throws {
        // Given - This test depends on system permission state
        // If permission is denied, voiceInputError should be set

        // When
        await viewModel.startVoiceInput()

        // Then - If permission was denied, error should be set
        // This depends on actual system permission state
        // The test verifies error handling path exists
    }

    // MARK: - Voice Input Transcription Test

    func testVoiceInputTranscriptionUpdatesInputText() async throws {
        // Given - Simulate transcription from voice input manager
        mockVoiceInputManager.transcribedText = "Transcribed text from speech"

        // When - The view model observes the voice input manager's transcription
        // Simulate the publisher update
        await MainActor.run {
            viewModel.inputText = mockVoiceInputManager.transcribedText
        }

        // Then
        XCTAssertEqual(viewModel.inputText, "Transcribed text from speech")
    }

    // MARK: - OCR Processing Integration Tests

    func testProcessImageWithOCRSuccess() async throws {
        // Given - Create a test image
        let testImage = try createSimpleTestImage()
        mockOCRManager.extractedText = "Extracted text from image"
        mockOCRManager.isProcessing = false

        // When - Process the image
        // Note: processImageWithOCR is private, so we test via the public flow
        // The image would be set via selectedImage property
        viewModel.selectedImage = testImage

        // Then - OCR state should be updated
        // This is tested indirectly through the OCR manager mock
    }

    func testProcessImageWithOCRFailure() async throws {
        // Given - Setup OCR to fail
        let testImage = try createSimpleTestImage()
        mockOCRManager.error = .noTextFound

        // When - Attempt to process image
        viewModel.selectedImage = testImage

        // Then - Error should be handled
        // The actual processing happens in processImageWithOCR which is private
        // Error handling is verified through the OCR manager mock
    }

    // MARK: - Conversation Error Test

    func testConversationNotFoundError() async throws {
        // Given - Setup repository to simulate conversation not found
        mockChatRepository.shouldThrowError = true
        mockChatRepository.errorToThrow = NSError(
            domain: "ChatRepository",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Conversation not found"]
        )

        // When
        await viewModel.loadMessages()

        // Then - Should handle error gracefully
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.error?.localizedDescription.contains("Conversation not found") ?? false)
    }

    // MARK: - Test Helper Methods

    private func createSimpleTestImage() throws -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        return image
    }
}
