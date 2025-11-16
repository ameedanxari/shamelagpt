//
//  NetworkErrorRecoveryTests.swift
//  shamelagptTests
//
//  Integration tests for network error recovery and offline mode
//

import XCTest
@testable import ShamelaGPT

final class NetworkErrorRecoveryTests: XCTestCase {

    var chatRepository: ChatRepositoryImpl!
    var sendMessageUseCase: SendMessageUseCase!
    var mockAPIClient: MockAPIClient!
    var mockNetworkMonitor: MockNetworkMonitor!
    var testCoreDataStack: TestCoreDataStack!

    override func setUpWithError() throws {
        // Set up in-memory Core Data stack
        testCoreDataStack = TestCoreDataStack()

        // Set up mock network components
        mockAPIClient = MockAPIClient()
        mockNetworkMonitor = MockNetworkMonitor()

        // Create real repository with in-memory stack
        chatRepository = ChatRepositoryImpl(
            coreDataStack: testCoreDataStack,
            conversationDAO: ConversationDAO(),
            messageDAO: MessageDAO(),
            apiClient: mockAPIClient,
            networkMonitor: mockNetworkMonitor
        )

        // Create real use case
        sendMessageUseCase = SendMessageUseCase(
            chatRepository: chatRepository,
            apiClient: mockAPIClient,
            networkMonitor: mockNetworkMonitor
        )
    }

    override func tearDownWithError() throws {
        sendMessageUseCase = nil
        chatRepository = nil
        mockNetworkMonitor = nil
        mockAPIClient = nil
        testCoreDataStack = nil
    }

    // MARK: - Network Error Recovery Tests

    func testRecoveryAfterNetworkError() async throws {
        // Given - Create conversation
        let conversation = try await chatRepository.createConversation(title: "Recovery Test")

        // First attempt - network is disconnected
        mockNetworkMonitor.mockIsConnected = false

        // When - Try to send message while offline
        do {
            _ = try await sendMessageUseCase.execute(
                conversationId: conversation.id,
                message: "First message attempt",
                saveUserMessage: true
            )
            XCTFail("Should throw network error when offline")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.noConnection, "Should throw no connection error")
        }

        // Then - Reconnect and retry
        mockNetworkMonitor.mockIsConnected = true
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Recovery successful",
            threadId: "recovery-thread"
        )

        // When - Retry the message after recovery
        let result = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: "Retry after recovery",
            saveUserMessage: true
        )

        // Then - Verify successful recovery
        XCTAssertEqual(result.userMessage.content, "Retry after recovery")
        XCTAssertEqual(result.assistantMessage.content, "Recovery successful")

        // Verify messages were saved
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)
        // Offline attempt left the initial user message persisted; retry adds another user + assistant
        XCTAssertEqual(messages.count, 3, "Should include offline attempt plus retry pair")
    }

    func testOfflineModeMessageQueuing() async throws {
        // Given - Conversation exists
        let conversation = try await chatRepository.createConversation(title: "Offline Test")

        // Network is offline
        mockNetworkMonitor.mockIsConnected = false

        // When - Try to send message while offline
        // The use case should throw error, but we can still save user messages locally
        do {
            _ = try await sendMessageUseCase.execute(
                conversationId: conversation.id,
                message: "Offline message",
                saveUserMessage: true
            )
            XCTFail("Should fail when offline")
        } catch {
            // Expected to fail
            XCTAssertTrue(error is NetworkError)
        }

        // Then - Verify user message can be saved independently for queuing
        // In a real app, this would be handled by the ViewModel
        let userMessage = try await chatRepository.addMessage(
            toConversation: conversation.id,
            content: "Queued message for later",
            isUserMessage: true,
            sources: []
        )

        XCTAssertEqual(userMessage.content, "Queued message for later")

        // Verify it's persisted
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)
        XCTAssertEqual(messages.count, 2)
        XCTAssertTrue(messages.allSatisfy { $0.isUserMessage })
        XCTAssertTrue(messages.contains { $0.content == "Offline message" })
        XCTAssertTrue(messages.contains { $0.content == "Queued message for later" })
    }

    func testReconnectionResendsPendingMessages() async throws {
        // Given - Create conversation
        let conversation = try await chatRepository.createConversation(title: "Reconnection Test")

        // Save a pending user message while offline
        mockNetworkMonitor.mockIsConnected = false

        let pendingMessage = try await chatRepository.addMessage(
            toConversation: conversation.id,
            content: "Pending message from offline mode",
            isUserMessage: true,
            sources: []
        )

        // When - Network reconnects
        mockNetworkMonitor.mockIsConnected = true
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Response to pending message",
            threadId: "reconnect-thread"
        )

        // Simulate resending the pending message
        // In real app, this would be triggered by the ViewModel detecting reconnection
        let result = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: pendingMessage.content,
            saveUserMessage: false // Don't save again, already saved
        )

        // Then - Verify the flow completed successfully
        XCTAssertEqual(result.assistantMessage.content, "Response to pending message")

        // Verify we now have both messages (the pending one + new assistant response)
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)

        // We should have:
        // 1. The original pending user message
        // 2. The assistant response (result.assistantMessage is not saved by execute when saveUserMessage=false)
        // Actually, let's verify the assistant message was saved
        let assistantMessages = messages.filter { !$0.isUserMessage }
        XCTAssertEqual(assistantMessages.count, 1, "Should have assistant response")
        XCTAssertEqual(assistantMessages.first?.content, "Response to pending message")

        // Verify thread ID was updated on the conversation
        let updatedConversation = try await chatRepository.fetchConversation(byId: conversation.id)
        XCTAssertEqual(updatedConversation?.threadId, "reconnect-thread")
    }

    // MARK: - Additional Error Scenarios

    func testMultipleNetworkFailuresWithRecovery() async throws {
        // Given
        let conversation = try await chatRepository.createConversation(title: "Multiple Failures")

        // Simulate multiple network failures
        for attempt in 1...3 {
            mockNetworkMonitor.mockIsConnected = false

            do {
                _ = try await sendMessageUseCase.execute(
                    conversationId: conversation.id,
                    message: "Attempt \(attempt)",
                    saveUserMessage: true
                )
                XCTFail("Should fail when offline")
            } catch {
                XCTAssertTrue(error is NetworkError)
            }
        }

        // When - Finally reconnect and succeed
        mockNetworkMonitor.mockIsConnected = true
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Success after retries",
            threadId: "retry-thread"
        )

        let result = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: "Final successful attempt",
            saveUserMessage: true
        )

        // Then
        XCTAssertEqual(result.assistantMessage.content, "Success after retries")

        // Verify all user attempts remain plus the final assistant response
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)
        XCTAssertEqual(messages.count, 5)
    }

    func testAPITimeoutRecovery() async throws {
        // Given
        let conversation = try await chatRepository.createConversation(title: "Timeout Test")

        // First attempt - API timeout
        mockNetworkMonitor.mockIsConnected = true
        mockAPIClient.shouldFail = true
        mockAPIClient.errorToThrow = NetworkError.timeout

        do {
            _ = try await sendMessageUseCase.execute(
                conversationId: conversation.id,
                message: "Timeout attempt",
                saveUserMessage: true
            )
            XCTFail("Should throw timeout error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.timeout)
        }

        // When - Retry after timeout with successful response
        mockAPIClient.shouldFail = false
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Success after timeout",
            threadId: "timeout-recovery"
        )

        let result = try await sendMessageUseCase.execute(
            conversationId: conversation.id,
            message: "Retry after timeout",
            saveUserMessage: true
        )

        // Then
        XCTAssertEqual(result.assistantMessage.content, "Success after timeout")

        // Note: The first message's user message was saved before the timeout
        // The second message adds another user+assistant pair
        let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)
        XCTAssertGreaterThanOrEqual(messages.count, 2, "Should have at least the successful message pair")
    }

    func testSendMessageUseCaseErrorMatrixPropagatesExpectedNetworkErrors() async throws {
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

        mockNetworkMonitor.mockIsConnected = true

        for (scenario, expectedError) in matrix {
            let conversation = try await chatRepository.createConversation(title: "Matrix \(scenario.rawValue)")
            MockScenarioMatrix.apply(scenario, to: mockAPIClient)

            do {
                _ = try await sendMessageUseCase.execute(
                    conversationId: conversation.id,
                    message: "Failure scenario \(scenario.rawValue)",
                    saveUserMessage: true
                )
                XCTFail("Expected failure for scenario \(scenario.rawValue)")
            } catch let error as NetworkError {
                XCTAssertEqual(error, expectedError, "Unexpected error for scenario \(scenario.rawValue)")
            } catch {
                XCTFail("Unexpected error type for scenario \(scenario.rawValue): \(error)")
            }

            let messages = try await chatRepository.fetchMessages(forConversation: conversation.id)
            XCTAssertEqual(messages.count, 1, "User message should remain persisted after failed request for \(scenario.rawValue)")
            XCTAssertTrue(messages[0].isUserMessage, "Persisted message should be user message for \(scenario.rawValue)")
        }
    }
}
