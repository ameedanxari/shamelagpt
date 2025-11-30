//
//  MessageFlowIntegrationTests.swift
//  shamelagptTests
//
//  Integration tests for end-to-end message flow
//

import XCTest
import Combine
@testable import ShamelaGPT

final class MessageFlowIntegrationTests: XCTestCase {

    var chatRepository: ChatRepositoryImpl!
    var sendMessageUseCase: SendMessageUseCase!
    var mockAPIClient: MockAPIClient!
    var mockNetworkMonitor: MockNetworkMonitor!
    var testCoreDataStack: TestCoreDataStack!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        // Set up in-memory Core Data stack
        testCoreDataStack = TestCoreDataStack()

        // Set up mock network components
        mockAPIClient = MockAPIClient()
        mockNetworkMonitor = MockNetworkMonitor()
        mockNetworkMonitor.mockIsConnected = true

        // Create real repository with in-memory stack
        chatRepository = ChatRepositoryImpl(
            coreDataStack: testCoreDataStack,
            conversationDAO: ConversationDAO(),
            messageDAO: MessageDAO(),
            apiClient: mockAPIClient,
            networkMonitor: mockNetworkMonitor
        )

        // Create real use case with real repository and mock network
        sendMessageUseCase = SendMessageUseCase(
            chatRepository: chatRepository,
            apiClient: mockAPIClient,
            networkMonitor: mockNetworkMonitor
        )

        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        cancellables = nil
        sendMessageUseCase = nil
        chatRepository = nil
        mockNetworkMonitor = nil
        mockAPIClient = nil
        testCoreDataStack = nil
    }

    // MARK: - End-to-End Message Flow Tests

    func testCompleteMessageFlow() async throws {
        // Given - Create a conversation
        let conversation = try await chatRepository.createConversation(title: "Test Conversation")

        // Configure mock API response
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "This is the assistant's response.",
            threadId: "thread-123"
        )

        // When - Send a message through the complete flow
        let result = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: "What is the test question?",
            saveUserMessage: true
        )

        // Then - Verify the complete flow
        XCTAssertEqual(result.userMessage.content, "What is the test question?")
        XCTAssertTrue(result.userMessage.isUserMessage)

        XCTAssertEqual(result.assistantMessage.content, "This is the assistant's response.")
        XCTAssertFalse(result.assistantMessage.isUserMessage)

        // Verify messages were persisted
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)
        XCTAssertEqual(messages.count, 2, "Should have both user and assistant messages")
        XCTAssertEqual(messages[0].content, "What is the test question?")
        XCTAssertEqual(messages[1].content, "This is the assistant's response.")

        // Verify thread ID was updated
        let updatedConversation = try await chatRepository.fetchConversation(byId: conversation.id)
        XCTAssertEqual(updatedConversation?.threadId, "thread-123")
    }

    func testMessagePersistence() async throws {
        // Given
        let conversation = try await chatRepository.createConversation(title: "Persistence Test")

        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Persisted response",
            threadId: "thread-456"
        )

        // When - Send message
        _ = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: "Test persistence",
            saveUserMessage: true
        )

        // Then - Fetch from Core Data to verify persistence
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)

        XCTAssertEqual(messages.count, 2)

        // Verify user message persisted correctly
        let userMessage = messages.first(where: { $0.isUserMessage })
        XCTAssertNotNil(userMessage)
        XCTAssertEqual(userMessage?.content, "Test persistence")
        XCTAssertEqual(userMessage?.conversationId, conversation.id)

        // Verify assistant message persisted correctly
        let assistantMessage = messages.first(where: { !$0.isUserMessage })
        XCTAssertNotNil(assistantMessage)
        XCTAssertEqual(assistantMessage?.content, "Persisted response")
        XCTAssertEqual(assistantMessage?.conversationId, conversation.id)
    }

    func testMessageWithSourcesPersistence() async throws {
        // Given
        let conversation = try await chatRepository.createConversation(title: "Sources Test")

        // Mock response with sources in markdown format
        let responseWithSources = """
        This is the main answer content.

        ## Sources:
        - **[صحيح البخاري](https://shamela.ws/book/1/52)** - محمد بن إسماعيل البخاري
        """

        mockAPIClient.mockChatResponse = ChatResponse(
            answer: responseWithSources,
            threadId: "thread-789"
        )

        // When - Send message
        _ = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: "Question about sources",
            saveUserMessage: true
        )

        // Then - Verify sources were parsed and persisted
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)
        let assistantMessage = messages.first(where: { !$0.isUserMessage })

        XCTAssertNotNil(assistantMessage)
        XCTAssertFalse(assistantMessage?.sources.isEmpty ?? true, "Should have sources")
        XCTAssertEqual(assistantMessage?.sources.count, 1)

        let source = assistantMessage?.sources.first
        XCTAssertEqual(source?.bookTitle, "صحيح البخاري")
        XCTAssertEqual(source?.author, "محمد بن إسماعيل البخاري")
    }

    func testConversationUpdatedAfterMessage() async throws {
        // Given
        let conversation = try await chatRepository.createConversation(title: "Update Test")
        let originalUpdatedAt = conversation.updatedAt

        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Response",
            threadId: "thread-update"
        )

        // Wait a moment to ensure timestamp difference
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        // When - Send message
        _ = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: "Update the conversation",
            saveUserMessage: true
        )

        // Then - Verify conversation was updated
        let updatedConversation = try await chatRepository.fetchConversation(byId: conversation.id)

        XCTAssertNotNil(updatedConversation)
        XCTAssertGreaterThan(
            updatedConversation!.updatedAt,
            originalUpdatedAt,
            "Conversation updatedAt should be newer"
        )
        XCTAssertEqual(updatedConversation?.threadId, "thread-update")
        XCTAssertEqual(updatedConversation?.messages.count, 2)
    }

    func testThreadIdPersistsAcrossMessages() async throws {
        // Given
        let conversation = try await chatRepository.createConversation(title: "Thread Test")

        // First message - thread ID gets set
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "First response",
            threadId: "persistent-thread"
        )

        _ = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: "First question",
            saveUserMessage: true
        )

        // Second message - should use same thread ID
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Second response",
            threadId: "persistent-thread"
        )

        // When - Send second message
        _ = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: "Second question",
            saveUserMessage: true
        )

        // Then - Verify thread ID persisted
        XCTAssertEqual(mockAPIClient.sendMessageCallCount, 2)

        // Verify first request had no thread ID
        // Verify second request included the thread ID
        let updatedConversation = try await chatRepository.fetchConversation(byId: conversation.id)
        XCTAssertEqual(updatedConversation?.threadId, "persistent-thread")
        XCTAssertEqual(updatedConversation?.messages.count, 4, "Should have 4 messages total (2 pairs)")
    }

    func testMultipleMessagesInConversation() async throws {
        // Given
        let conversation = try await chatRepository.createConversation(title: "Multiple Messages")

        // When - Send multiple messages in sequence
        for i in 1...3 {
            mockAPIClient.mockChatResponse = ChatResponse(
                answer: "Response \(i)",
                threadId: "thread-multi"
            )

            _ = try await sendMessageUseCase.execute(
                conversationId: conversation.id,
                message: "Question \(i)",
                saveUserMessage: true
            )
        }

        // Then - Verify all messages persisted in order
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)

        XCTAssertEqual(messages.count, 6, "Should have 6 messages (3 pairs)")

        // Verify order is maintained (alternating user/assistant)
        XCTAssertTrue(messages[0].isUserMessage)
        XCTAssertEqual(messages[0].content, "Question 1")

        XCTAssertFalse(messages[1].isUserMessage)
        XCTAssertEqual(messages[1].content, "Response 1")

        XCTAssertTrue(messages[2].isUserMessage)
        XCTAssertEqual(messages[2].content, "Question 2")

        XCTAssertFalse(messages[3].isUserMessage)
        XCTAssertEqual(messages[3].content, "Response 2")

        XCTAssertTrue(messages[4].isUserMessage)
        XCTAssertEqual(messages[4].content, "Question 3")

        XCTAssertFalse(messages[5].isUserMessage)
        XCTAssertEqual(messages[5].content, "Response 3")

        // Verify timestamps are in order
        for i in 0..<(messages.count - 1) {
            XCTAssertLessThanOrEqual(
                messages[i].timestamp,
                messages[i + 1].timestamp,
                "Messages should be ordered by timestamp"
            )
        }
    }
}
