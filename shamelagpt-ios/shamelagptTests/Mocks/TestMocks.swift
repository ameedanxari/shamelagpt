//
//  TestMocks.swift
//  shamelagptTests
//
//  Centralized mock objects for testing
//

import Foundation
import Combine
import Speech
import UIKit
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

class MockNetworkMonitor: NetworkMonitorProtocol {
    var mockIsConnected = true
    var mockConnectionType: NetworkMonitor.ConnectionType = .wifi
    
    var isConnected: Bool {
        return mockIsConnected
    }
    
    var connectionType: NetworkMonitor.ConnectionType {
        return mockConnectionType
    }
    
    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        Just(mockIsConnected).eraseToAnyPublisher()
    }
    
    var connectionTypePublisher: AnyPublisher<NetworkMonitor.ConnectionType, Never> {
        Just(mockConnectionType).eraseToAnyPublisher()
    }
    
    func startMonitoring() {
        // Mock implementation - do nothing
    }
    
    func stopMonitoring() {
        // Mock implementation - do nothing
    }
}

// MARK: - Mock SendMessageUseCase

@MainActor
class MockSendMessageUseCase: SendMessageUseCaseProtocol {
    var shouldSucceed = true
    var errorToThrow: Error = NSError(domain: "test", code: -1, userInfo: nil)
    var mockThreadId: String?
    var delay: TimeInterval = 0

    // Track calls
    var executeCallCount = 0
    var lastQuestion: String?
    var lastConversationId: String?

    func execute(
        conversationId: String,
        message: String,
        imageData: Data? = nil,
        detectedLanguage: String? = nil,
        isFactCheckMessage: Bool = false,
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
                sources: [],
                imageData: imageData,
                detectedLanguage: detectedLanguage,
                isFactCheckMessage: isFactCheckMessage
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
    
    func executePublisher(
        conversationId: String,
        message: String,
        imageData: Data? = nil,
        detectedLanguage: String? = nil,
        isFactCheckMessage: Bool = false,
        saveUserMessage: Bool = true
    ) -> AnyPublisher<SendMessageUseCase.Result, Error> {
        Future { promise in
            Task {
                do {
                    let result = try await self.execute(
                        conversationId: conversationId,
                        message: message,
                        imageData: imageData,
                        detectedLanguage: detectedLanguage,
                        isFactCheckMessage: isFactCheckMessage,
                        saveUserMessage: saveUserMessage
                    )
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
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
class MockVoiceInputManager: VoiceInputManagerProtocol {
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .authorized
    @Published var error: VoiceInputError?
    
    var transcribedTextPublisher: Published<String>.Publisher { $transcribedText }
    var isRecordingPublisher: Published<Bool>.Publisher { $isRecording }
    var authorizationStatusPublisher: Published<SFSpeechRecognizerAuthorizationStatus>.Publisher { $authorizationStatus }
    var errorPublisher: Published<VoiceInputError?>.Publisher { $error }
    
    func requestPermission() async -> Bool {
        return authorizationStatus == .authorized
    }
    
    func startRecording(locale: Locale) async throws {
        isRecording = true
    }
    
    func stopRecording() {
        isRecording = false
    }
    
    func clearTranscription() {
        transcribedText = ""
    }
    
    func clearError() {
        error = nil
    }
}

// MARK: - Mock OCR Manager

@MainActor
class MockOCRManager: OCRManagerProtocol {
    @Published var extractedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var error: OCRError?
    
    var extractedTextPublisher: Published<String>.Publisher { $extractedText }
    var isProcessingPublisher: Published<Bool>.Publisher { $isProcessing }
    var errorPublisher: Published<OCRError?>.Publisher { $error }
    
    func recognizeText(from image: UIImage) async throws -> String {
        return extractedText
    }
    
    func recognizeTextWithLanguage(from image: UIImage) async throws -> OCRResult {
        return OCRResult(text: extractedText, detectedLanguage: "en")
    }
    
    func clearError() {
        error = nil
    }
}

// MARK: - Mock GetConversationsUseCase

class MockGetConversationsUseCase: GetConversationsUseCaseProtocol {
    var mockConversations: [Conversation] = []
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1, userInfo: nil)

    // Track calls
    var executeCallCount = 0
    var observeConversationsCallCount = 0

    private let conversationsSubject = PassthroughSubject<[Conversation], Never>()

    func execute() async throws -> [Conversation] {
        executeCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        // Sort by updatedAt descending (most recent first)
        return mockConversations.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func executePublisher() -> AnyPublisher<[Conversation], Error> {
        Future { promise in
            Task {
                do {
                    let result = try await self.execute()
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func observeConversations() -> AnyPublisher<[Conversation], Never> {
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

class MockDeleteConversationUseCase: DeleteConversationUseCaseProtocol {
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1, userInfo: nil)

    // Track calls
    var executeCallCount = 0
    var executeDeleteAllCallCount = 0
    var lastDeletedId: String?

    func execute(id: String) async throws {
        executeCallCount += 1
        lastDeletedId = id

        if shouldThrowError {
            throw errorToThrow
        }
    }

    func executeDeleteAll() async throws {
        executeDeleteAllCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }
    }
    
    func executePublisher(id: String) -> AnyPublisher<Void, Error> {
        Future { promise in
            Task {
                do {
                    try await self.execute(id: id)
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func executeDeleteAllPublisher() -> AnyPublisher<Void, Error> {
        Future { promise in
            Task {
                do {
                    try await self.executeDeleteAll()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
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
