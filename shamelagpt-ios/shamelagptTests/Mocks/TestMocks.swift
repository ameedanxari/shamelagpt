//
//  TestMocks.swift
//  shamelagptTests
//
//  Centralized mock objects for testing
//

import Foundation
import Combine
@testable import ShamelaGPT

// MARK: - Mock API Client

class MockAPIClient: APIClientProtocol {
    var shouldFail = false
    var errorToThrow: Error = NetworkError.noConnection
    var requestDelay: TimeInterval = 0

    var mockHealthResponse = HealthResponse(status: "ok", service: "shamelagpt-api")
    var mockChatResponse = ChatResponse(
        answer: "This is a mock response.\n\nSources:\n\n* **book_name:** صحيح البخاري, **source_url:** https://shamela.ws/book/1234/52",
        threadId: "mock-thread-id"
    )

    // Track calls
    var healthCheckCallCount = 0
    var sendMessageCallCount = 0
    var lastSendMessageRequest: ChatRequest?

    func healthCheck() async throws -> HealthResponse {
        healthCheckCallCount += 1

        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }

        if shouldFail {
            throw errorToThrow
        }
        return mockHealthResponse
    }

    func sendMessage(_ request: ChatRequest) async throws -> ChatResponse {
        sendMessageCallCount += 1
        lastSendMessageRequest = request

        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }

        if shouldFail {
            throw errorToThrow
        }
        return mockChatResponse
    }

    func reset() {
        healthCheckCallCount = 0
        sendMessageCallCount = 0
        lastSendMessageRequest = nil
        shouldFail = false
        requestDelay = 0
    }
}

// MARK: - Mock Chat Repository

class MockChatRepository: ChatRepository {
    var mockMessages: [Message] = []
    var mockConversations: [Conversation] = []
    var mockConversation: Conversation?
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1, userInfo: nil)

    // Track calls
    var createConversationCallCount = 0
    var addMessageCallCount = 0
    var fetchMessagesCallCount = 0

    func fetchMostRecentEmptyConversation() async throws -> Conversation? {
        if shouldThrowError { throw errorToThrow }
        return mockConversations.first { $0.messages.isEmpty }
    }

    var conversationsPublisher: AnyPublisher<[Conversation], Never> {
        Just(mockConversations).eraseToAnyPublisher()
    }

    func createConversation(title: String) async throws -> Conversation {
        createConversationCallCount += 1
        if shouldThrowError { throw errorToThrow }

        let conversation = Conversation(
            id: UUID().uuidString,
            threadId: nil,
            title: title,
            messages: []
        )
        mockConversations.append(conversation)
        return conversation
    }

    func fetchAllConversations() async throws -> [Conversation] {
        if shouldThrowError { throw errorToThrow }
        return mockConversations
    }

    func fetchConversation(byId id: String) async throws -> Conversation? {
        if shouldThrowError { throw errorToThrow }
        return mockConversation ?? mockConversations.first { $0.id == id }
    }

    func fetchConversation(byThreadId threadId: String) async throws -> Conversation? {
        if shouldThrowError { throw errorToThrow }
        return mockConversations.first { $0.threadId == threadId }
    }

    func updateConversationTitle(id: String, title: String) async throws {
        if shouldThrowError { throw errorToThrow }
    }

    func updateConversationThreadId(id: String, threadId: String) async throws {
        if shouldThrowError { throw errorToThrow }
    }

    func deleteConversation(id: String) async throws {
        if shouldThrowError { throw errorToThrow }
        mockConversations.removeAll { $0.id == id }
    }

    func deleteAllConversations() async throws {
        if shouldThrowError { throw errorToThrow }
        mockConversations.removeAll()
    }

    func addMessage(
        toConversation conversationId: String,
        content: String,
        isUserMessage: Bool,
        sources: [Source]
    ) async throws -> Message {
        addMessageCallCount += 1
        if shouldThrowError { throw errorToThrow }

        let message = Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            content: content,
            isUserMessage: isUserMessage,
            timestamp: Date(),
            sources: sources
        )
        mockMessages.append(message)
        return message
    }

    func addFactCheckMessage(
        toConversation conversationId: String,
        content: String,
        isUserMessage: Bool,
        sources: [Source],
        imageData: Data?,
        detectedLanguage: String?,
        isFactCheckMessage: Bool
    ) async throws -> Message {
        addMessageCallCount += 1
        if shouldThrowError { throw errorToThrow }

        let message = Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            content: content,
            isUserMessage: isUserMessage,
            timestamp: Date(),
            sources: sources,
            imageData: imageData,
            detectedLanguage: detectedLanguage,
            isFactCheckMessage: isFactCheckMessage
        )
        mockMessages.append(message)
        return message
    }

    func fetchMessages(forConversation conversationId: String) async throws -> [Message] {
        fetchMessagesCallCount += 1
        if shouldThrowError { throw errorToThrow }
        return mockMessages.filter { $0.conversationId == conversationId }
    }

    func updateMessageContent(id: String, content: String) async throws {
        if shouldThrowError { throw errorToThrow }
    }

    func deleteMessage(id: String) async throws {
        if shouldThrowError { throw errorToThrow }
        mockMessages.removeAll { $0.id == id }
    }

    func reset() {
        mockMessages = []
        mockConversations = []
        mockConversation = nil
        shouldThrowError = false
        createConversationCallCount = 0
        addMessageCallCount = 0
        fetchMessagesCallCount = 0
    }
}

// MARK: - Mock Network Monitor

class MockNetworkMonitor: NetworkMonitor {
    var mockIsConnected = true

    override var isConnected: Bool {
        return mockIsConnected
    }
}

// MARK: - Mock SendMessageUseCase

@MainActor
class MockSendMessageUseCase: SendMessageUseCase {
    var shouldSucceed = true
    var errorToThrow: Error = NSError(domain: "test", code: -1, userInfo: nil)
    var mockThreadId: String?
    var delay: TimeInterval = 0

    // Track calls
    var executeCallCount = 0
    var lastQuestion: String?
    var lastConversationId: String?

    init() {
        let mockAPIClient = MockAPIClient()
        let mockChatRepository = MockChatRepository()
        let mockNetworkMonitor = MockNetworkMonitor()

        super.init(
            chatRepository: mockChatRepository,
            apiClient: mockAPIClient,
            networkMonitor: mockNetworkMonitor
        )
    }

    override func execute(
        conversationId: String,
        message: String,
        saveUserMessage: Bool = true
    ) async throws -> SendMessageUseCase.Result {
        executeCallCount += 1
        lastQuestion = message
        lastConversationId = conversationId

        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if shouldSucceed {
            let userMessage = Message(
                id: "user-\(UUID().uuidString)",
                conversationId: conversationId,
                content: message,
                isUserMessage: true,
                timestamp: Date(),
                sources: []
            )

            let assistantMessage = Message(
                id: "assistant-\(UUID().uuidString)",
                conversationId: conversationId,
                content: "Mock response",
                isUserMessage: false,
                timestamp: Date(),
                sources: []
            )

            let conversation = Conversation(
                id: conversationId,
                threadId: mockThreadId,
                title: "Test Conversation",
                messages: [userMessage, assistantMessage]
            )

            return SendMessageUseCase.Result(
                userMessage: userMessage,
                assistantMessage: assistantMessage,
                conversation: conversation
            )
        } else {
            throw errorToThrow
        }
    }

    func reset() {
        executeCallCount = 0
        lastQuestion = nil
        lastConversationId = nil
        shouldSucceed = true
        delay = 0
    }
}

// MARK: - Mock Voice Input Manager

@MainActor
class MockVoiceInputManager: VoiceInputManager {
    var mockTranscribedText: String = ""
    var mockIsRecording: Bool = false
    var mockError: VoiceInputError?

    override var transcribedText: String {
        return mockTranscribedText
    }

    override var isRecording: Bool {
        return mockIsRecording
    }

    override var error: VoiceInputError? {
        return mockError
    }
}

// MARK: - Mock OCR Manager

@MainActor
class MockOCRManager: OCRManager {
    var mockExtractedText: String = ""
    var mockIsProcessing: Bool = false
    var mockError: OCRError?

    override var extractedText: String {
        return mockExtractedText
    }

    override var isProcessing: Bool {
        return mockIsProcessing
    }

    override var error: OCRError? {
        return mockError
    }
}

// MARK: - Mock GetConversationsUseCase

class MockGetConversationsUseCase: GetConversationsUseCase {
    var mockConversations: [Conversation] = []
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1, userInfo: nil)

    // Track calls
    var executeCallCount = 0
    var observeConversationsCallCount = 0

    private let conversationsSubject = PassthroughSubject<[Conversation], Never>()

    init() {
        let mockRepository = MockChatRepository()
        super.init(chatRepository: mockRepository)
    }

    override func execute() async throws -> [Conversation] {
        executeCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        // Sort by updatedAt descending (most recent first)
        return mockConversations.sorted { $0.updatedAt > $1.updatedAt }
    }

    override func observeConversations() -> AnyPublisher<[Conversation], Never> {
        observeConversationsCallCount += 1

        // Return a publisher that emits the mock conversations
        return Just(mockConversations.sorted { $0.updatedAt > $1.updatedAt })
            .eraseToAnyPublisher()
    }

    func emitConversations(_ conversations: [Conversation]) {
        conversationsSubject.send(conversations.sorted { $0.updatedAt > $1.updatedAt })
    }

    func reset() {
        mockConversations = []
        shouldThrowError = false
        executeCallCount = 0
        observeConversationsCallCount = 0
    }
}

// MARK: - Mock DeleteConversationUseCase

class MockDeleteConversationUseCase: DeleteConversationUseCase {
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1, userInfo: nil)

    // Track calls
    var executeCallCount = 0
    var executeDeleteAllCallCount = 0
    var lastDeletedId: String?

    init() {
        let mockRepository = MockChatRepository()
        super.init(chatRepository: mockRepository)
    }

    override func execute(id: String) async throws {
        executeCallCount += 1
        lastDeletedId = id

        if shouldThrowError {
            throw errorToThrow
        }
    }

    override func executeDeleteAll() async throws {
        executeDeleteAllCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }
    }

    func reset() {
        shouldThrowError = false
        executeCallCount = 0
        executeDeleteAllCallCount = 0
        lastDeletedId = nil
    }
}

// MARK: - Test Data Fixtures

extension Message {
    static var preview: Message {
        Message(
            id: "preview-user",
            conversationId: "test-conv-1",
            content: "What is Islam?",
            isUserMessage: true,
            timestamp: Date(),
            sources: []
        )
    }

    static var previewAssistant: Message {
        Message(
            id: "preview-assistant",
            conversationId: "test-conv-1",
            content: "Islam is a monotheistic religion...",
            isUserMessage: false,
            timestamp: Date(),
            sources: [Source.preview]
        )
    }

    static var previewFactCheck: Message {
        Message(
            id: "preview-factcheck",
            conversationId: "test-conv-1",
            content: "This statement needs verification",
            isUserMessage: true,
            timestamp: Date(),
            sources: [],
            imageData: Data(),
            detectedLanguage: "en",
            isFactCheckMessage: true
        )
    }
}

extension Conversation {
    static var preview: Conversation {
        Conversation(
            id: "preview-conv",
            threadId: "thread-123",
            title: "Test Conversation",
            messages: [Message.preview, Message.previewAssistant]
        )
    }

    static var previewEmpty: Conversation {
        Conversation(
            id: "preview-empty",
            threadId: nil,
            title: "Empty Conversation",
            messages: []
        )
    }
}

extension Source {
    static var preview: Source {
        Source(
            bookTitle: "صحيح البخاري",
            author: "محمد بن إسماعيل البخاري",
            volumeNumber: 1,
            pageNumber: 52,
            text: "Sample text from Sahih al-Bukhari",
            sourceUrl: "https://shamela.ws/book/1234/52"
        )
    }
}
