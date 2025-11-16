//
//  ChatViewModelStreamingTests.swift
//  shamelagptTests
//
//  Focused coverage for SSE streaming paths and error handling in ChatViewModel.
//

import XCTest
import Combine
@testable import ShamelaGPT

@MainActor
final class ChatViewModelStreamingTests: XCTestCase {

    private var viewModel: ChatViewModel!
    private var mockSendMessageUseCase: MockSendMessageUseCase!
    private var mockChatRepository: MockChatRepository!
    private var mockAPIClient: MockAPIClient!
    private var mockVoiceInputManager: MockVoiceInputManager!
    private var mockOCRManager: MockOCRManager!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        mockSendMessageUseCase = MockSendMessageUseCase()
        mockChatRepository = MockChatRepository()
        mockAPIClient = MockAPIClient()
        mockVoiceInputManager = MockVoiceInputManager()
        mockOCRManager = MockOCRManager()
        cancellables = Set<AnyCancellable>()

        viewModel = ChatViewModel(
            conversationId: nil,
            sendMessageUseCase: mockSendMessageUseCase,
            chatRepository: mockChatRepository,
            apiClient: mockAPIClient,
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
        mockAPIClient = nil
        mockVoiceInputManager = nil
        mockOCRManager = nil
        cancellables = nil
    }

    func testStreamingSSEUpdatesThinkingAndFinalMessage() async throws {
        // Given
        mockAPIClient.streamMessageLines = [
            "data: {\"type\":\"metadata\",\"thread_id\":\"thread-xyz\"}\n\n",
            "data: {\"type\":\"thinking\",\"content\":\"Analyzing\"}\n\n",
            "data: {\"type\":\"chunk\",\"content\":\"Hello\"}\n\n",
            "data: {\"type\":\"chunk\",\"content\":\" world\"}\n\n",
            "data: {\"type\":\"done\",\"full_answer\":\"Hello world\",\"thread_id\":\"thread-xyz\"}\n\n",
            "data: [DONE]\n\n"
        ]

        let finished = expectation(description: "stream completes")
        viewModel.$isLoading
            .dropFirst()
            .removeDuplicates()
            .sink { isLoading in
                if !isLoading {
                    finished.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.inputText = "Hi there"
        viewModel.sendMessage()

        // Then
        await fulfillment(of: [finished], timeout: 3.0)

        XCTAssertEqual(viewModel.messages.count, 2, "User + assistant message should be present")
        XCTAssertEqual(viewModel.messages.last?.content, "Hello world")
        XCTAssertEqual(viewModel.threadId, "thread-xyz")
        XCTAssertTrue(viewModel.thinkingMessages.isEmpty, "Thinking indicators should clear after done event")
    }

    func testStreamingFailureSetsErrorAndRestoresInput() async throws {
        // Given
        mockAPIClient.streamMessageError = NetworkError.httpError(statusCode: 500)

        let finished = expectation(description: "stream error handled")
        viewModel.$isLoading
            .dropFirst()
            .sink { isLoading in
                if !isLoading {
                    finished.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.inputText = "Will fail"
        viewModel.sendMessage()

        // Then
        await fulfillment(of: [finished], timeout: 2.0)

        XCTAssertEqual(viewModel.inputText, "Will fail", "Input should be restored on failure")
        XCTAssertNotNil(viewModel.error, "Error should be set when streaming fails")
        XCTAssertEqual(viewModel.messages.count, 0, "Optimistic message should be removed after failure")
    }
}
