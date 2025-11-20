//
//  SendMessageUseCaseTests.swift
//  shamelagptTests
//
//  Created by Ameed Khalid on 05/11/2025.
//

import XCTest
import Combine
@testable import ShamelaGPT

final class SendMessageUseCaseTests: XCTestCase {

    var sut: SendMessageUseCase!
    var mockChatRepository: MockChatRepository!
    var mockAPIClient: MockAPIClient!
    var mockNetworkMonitor: MockNetworkMonitor!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        mockChatRepository = MockChatRepository()
        mockAPIClient = MockAPIClient()
        mockNetworkMonitor = MockNetworkMonitor()
        cancellables = Set<AnyCancellable>()

        sut = SendMessageUseCase(
            chatRepository: mockChatRepository,
            apiClient: mockAPIClient,
            networkMonitor: mockNetworkMonitor
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        mockChatRepository = nil
        mockAPIClient = nil
        mockNetworkMonitor = nil
        cancellables = nil
    }

    // MARK: - Success Flow Tests

    func testExecuteWithValidMessage() async throws {
        // Given
        let conversationId = "test-conv-1"
        let message = "What is Islam?"
        let testConversation = Conversation(
            id: conversationId,
            threadId: nil,
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Islam is a religion.\n\nSources:\n\n* **book_name:** Test Book, **source_url:** https://shamela.ws/book/1/1",
            threadId: "thread-123"
        )

        // When
        let result = try await sut.execute(
            conversationId: conversationId,
            message: message
        )

        // Then
        XCTAssertEqual(result.userMessage.content, message)
        XCTAssertTrue(result.userMessage.isUserMessage)
        XCTAssertFalse(result.assistantMessage.isUserMessage)
        XCTAssertEqual(mockChatRepository.addMessageCallCount, 2) // user + assistant
        XCTAssertEqual(mockAPIClient.sendMessageCallCount, 1)
    }

    func testExecuteUpdatesThreadIdOnFirstMessage() async throws {
        // Given
        let conversationId = "test-conv-1"
        let message = "First message"
        let newThreadId = "new-thread-456"
        let testConversation = Conversation(
            id: conversationId,
            threadId: nil, // No thread ID yet
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Response",
            threadId: newThreadId
        )

        // When
        let result = try await sut.execute(
            conversationId: conversationId,
            message: message
        )

        // Then
        XCTAssertEqual(result.conversation.threadId, newThreadId)
    }

    func testExecuteSavesUserMessage() async throws {
        // Given
        let conversationId = "test-conv-1"
        let message = "Test question"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(answer: "Response", threadId: "thread-123")

        // When
        _ = try await sut.execute(
            conversationId: conversationId,
            message: message,
            saveUserMessage: true
        )

        // Then
        XCTAssertEqual(mockChatRepository.addMessageCallCount, 2) // user + assistant
        let userMessages = mockChatRepository.mockMessages.filter { $0.isUserMessage }
        XCTAssertEqual(userMessages.count, 1)
        XCTAssertEqual(userMessages.first?.content, message)
    }

    func testExecuteSavesAssistantMessage() async throws {
        // Given
        let conversationId = "test-conv-1"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "This is the answer",
            threadId: "thread-123"
        )

        // When
        let result = try await sut.execute(
            conversationId: conversationId,
            message: "Question"
        )

        // Then
        XCTAssertEqual(result.assistantMessage.content, "This is the answer")
        XCTAssertFalse(result.assistantMessage.isUserMessage)
    }

    func testExecuteParsesResponseCorrectly() async throws {
        // Given
        let conversationId = "test-conv-1"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: """
            This is the clean content.

            Sources:

            * **book_name:** Book 1, **source_url:** https://shamela.ws/book/1/1
            """,
            threadId: "thread-123"
        )

        // When
        let result = try await sut.execute(
            conversationId: conversationId,
            message: "Question"
        )

        // Then
        XCTAssertEqual(result.assistantMessage.content, "This is the clean content.")
        XCTAssertFalse(result.assistantMessage.content.contains("Sources:"))
    }

    func testExecuteExtractsSourcesCorrectly() async throws {
        // Given
        let conversationId = "test-conv-1"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: """
            Content.

            Sources:

            * **book_name:** صحيح البخاري, **source_url:** https://shamela.ws/book/1234/52
            * **book_name:** صحيح مسلم, **source_url:** https://shamela.ws/book/5678/123
            """,
            threadId: "thread-123"
        )

        // When
        let result = try await sut.execute(
            conversationId: conversationId,
            message: "Question"
        )

        // Then
        XCTAssertEqual(result.assistantMessage.sources.count, 2)
        XCTAssertEqual(result.assistantMessage.sources[0].bookTitle, "صحيح البخاري")
        XCTAssertEqual(result.assistantMessage.sources[1].bookTitle, "صحيح مسلم")
    }

    func testExecuteWithExistingThreadId() async throws {
        // Given
        let conversationId = "test-conv-1"
        let existingThreadId = "existing-thread-789"
        let testConversation = Conversation(
            id: conversationId,
            threadId: existingThreadId,
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Response",
            threadId: existingThreadId
        )

        // When
        _ = try await sut.execute(
            conversationId: conversationId,
            message: "Question"
        )

        // Then
        XCTAssertEqual(mockAPIClient.lastSendMessageRequest?.threadId, existingThreadId)
    }

    func testExecuteWithFactCheckMessageSkipsSaveUserMessage() async throws {
        // Given
        let conversationId = "test-conv-1"
        let message = "Fact check this"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Fact check response",
            threadId: "thread-123"
        )

        // When
        _ = try await sut.execute(
            conversationId: conversationId,
            message: message,
            saveUserMessage: false
        )

        // Then
        // Only assistant message should be saved (count = 1)
        XCTAssertEqual(mockChatRepository.addMessageCallCount, 1)
        let savedMessages = mockChatRepository.mockMessages
        XCTAssertTrue(savedMessages.allSatisfy { !$0.isUserMessage })
    }

    // MARK: - Error Handling Tests

    func testExecuteWithNoNetworkConnection() async throws {
        // Given
        mockNetworkMonitor.mockIsConnected = false

        // When/Then
        do {
            _ = try await sut.execute(
                conversationId: "test-conv",
                message: "Question"
            )
            XCTFail("Should throw NetworkError.noConnection")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.noConnection)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteWithConversationNotFound() async throws {
        // Given
        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = nil // Conversation doesn't exist

        // When/Then
        do {
            _ = try await sut.execute(
                conversationId: "non-existent",
                message: "Question"
            )
            XCTFail("Should throw conversationNotFound error")
        } catch {
            // Success - error was thrown
            XCTAssertTrue(error is ChatRepositoryError || error.localizedDescription.contains("not found"))
        }
    }

    func testExecuteWithAPITimeout() async throws {
        // Given
        let conversationId = "test-conv-1"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.shouldFail = true
        mockAPIClient.errorToThrow = NetworkError.timeout

        // When/Then
        do {
            _ = try await sut.execute(
                conversationId: conversationId,
                message: "Question"
            )
            XCTFail("Should throw NetworkError.timeout")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.timeout)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteWithAPI4xxError() async throws {
        // Given
        let conversationId = "test-conv-1"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.shouldFail = true
        mockAPIClient.errorToThrow = NetworkError.badRequest

        // When/Then
        do {
            _ = try await sut.execute(
                conversationId: conversationId,
                message: "Question"
            )
            XCTFail("Should throw NetworkError.badRequest")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.badRequest)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteWithAPI5xxError() async throws {
        // Given
        let conversationId = "test-conv-1"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.shouldFail = true
        mockAPIClient.errorToThrow = NetworkError.serverError(500)

        // When/Then
        do {
            _ = try await sut.execute(
                conversationId: conversationId,
                message: "Question"
            )
            XCTFail("Should throw NetworkError.serverError")
        } catch let error as NetworkError {
            if case .serverError = error {
                // Success
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteWithInvalidResponse() async throws {
        // Given
        let conversationId = "test-conv-1"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.shouldFail = true
        mockAPIClient.errorToThrow = NetworkError.invalidResponse

        // When/Then
        do {
            _ = try await sut.execute(
                conversationId: conversationId,
                message: "Question"
            )
            XCTFail("Should throw NetworkError.invalidResponse")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.invalidResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteWithDecodingError() async throws {
        // Given
        let conversationId = "test-conv-1"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.shouldFail = true
        mockAPIClient.errorToThrow = NetworkError.decodingError

        // When/Then
        do {
            _ = try await sut.execute(
                conversationId: conversationId,
                message: "Question"
            )
            XCTFail("Should throw NetworkError.decodingError")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.decodingError)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteKeepsUserMessageOnAPIFailure() async throws {
        // Given
        let conversationId = "test-conv-1"
        let message = "Question that will fail"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.shouldFail = true
        mockAPIClient.errorToThrow = NetworkError.timeout

        // When
        do {
            _ = try await sut.execute(
                conversationId: conversationId,
                message: message
            )
            XCTFail("Should throw error")
        } catch {
            // Then - user message should still be saved
            XCTAssertEqual(mockChatRepository.addMessageCallCount, 1) // Only user message
            let userMessages = mockChatRepository.mockMessages.filter { $0.isUserMessage }
            XCTAssertEqual(userMessages.count, 1)
            XCTAssertEqual(userMessages.first?.content, message)
        }
    }

    // MARK: - Edge Cases

    func testExecuteWithEmptyMessage() async throws {
        // Given - Even though this should be validated in ViewModel,
        // use case should handle it
        let conversationId = "test-conv-1"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Response to empty message",
            threadId: "thread-123"
        )

        // When
        let result = try await sut.execute(
            conversationId: conversationId,
            message: ""
        )

        // Then - should still work (validation is in ViewModel)
        XCTAssertEqual(result.userMessage.content, "")
    }

    func testExecuteWithVeryLongMessage() async throws {
        // Given
        let conversationId = "test-conv-1"
        let longMessage = String(repeating: "a", count: 10000)
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Response to long message",
            threadId: "thread-123"
        )

        // When
        let result = try await sut.execute(
            conversationId: conversationId,
            message: longMessage
        )

        // Then
        XCTAssertEqual(result.userMessage.content, longMessage)
        XCTAssertEqual(mockAPIClient.lastSendMessageRequest?.question, longMessage)
    }

    func testExecuteWithSpecialCharacters() async throws {
        // Given
        let conversationId = "test-conv-1"
        let specialMessage = "Test with émojis 🌟 and spëcial çhars & symbols <>"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Response",
            threadId: "thread-123"
        )

        // When
        let result = try await sut.execute(
            conversationId: conversationId,
            message: specialMessage
        )

        // Then
        XCTAssertEqual(result.userMessage.content, specialMessage)
    }

    func testExecuteWithArabicText() async throws {
        // Given
        let conversationId = "test-conv-1"
        let arabicMessage = "ما هو الإسلام؟"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "الإسلام دين التوحيد",
            threadId: "thread-123"
        )

        // When
        let result = try await sut.execute(
            conversationId: conversationId,
            message: arabicMessage
        )

        // Then
        XCTAssertEqual(result.userMessage.content, arabicMessage)
        XCTAssertEqual(result.assistantMessage.content, "الإسلام دين التوحيد")
    }

    func testExecuteWithMixedLanguages() async throws {
        // Given
        let conversationId = "test-conv-1"
        let mixedMessage = "What is الإسلام in English?"
        let testConversation = Conversation(
            id: conversationId,
            threadId: "thread-123",
            title: "Test",
            messages: []
        )

        mockNetworkMonitor.mockIsConnected = true
        mockChatRepository.mockConversation = testConversation
        mockAPIClient.mockChatResponse = ChatResponse(
            answer: "Islam is التوحيد or monotheism",
            threadId: "thread-123"
        )

        // When
        let result = try await sut.execute(
            conversationId: conversationId,
            message: mixedMessage
        )

        // Then
        XCTAssertEqual(result.userMessage.content, mixedMessage)
        XCTAssertTrue(result.assistantMessage.content.contains("Islam"))
        XCTAssertTrue(result.assistantMessage.content.contains("التوحيد"))
    }
}
