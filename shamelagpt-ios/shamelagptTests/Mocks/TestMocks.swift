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

    var streamMessageLines: [String] = []
    var streamGuestMessageLines: [String] = []
    var streamMessageError: Error?
    var streamGuestMessageError: Error?

    var mockHealthResponse = HealthResponse(status: "ok", service: "shamelagpt-api")
    var mockChatResponse = ChatResponse(
        answer: "This is a mock response.\n\nSources:\n\n* **book_name:** صحيح البخاري, **source_url:** https://shamela.ws/book/1234/52",
        threadId: "mock-thread-id"
    )
    var mockCreateConversationResponse: ConversationResponse?
    var mockUserPreferencesResponse: UserPreferencesRequest?

    // Track calls
    var healthCheckCallCount = 0
    var sendMessageCallCount = 0
    var streamMessageCallCount = 0
    var streamGuestMessageCallCount = 0
    var signupCallCount = 0
    var loginCallCount = 0
    var currentUserCallCount = 0
    var updateUserCallCount = 0
    var deleteUserCallCount = 0
    var verifyTokenCallCount = 0
    var forgotPasswordCallCount = 0
    var googleSignInCallCount = 0
    var refreshTokenCallCount = 0
    var getPreferencesCallCount = 0
    var setPreferencesCallCount = 0
    var generateTitleCallCount = 0
    var listConversationsCallCount = 0
    var createConversationCallCount = 0
    var deleteAllConversationsCallCount = 0
    var deleteConversationCallCount = 0
    var getMessagesCallCount = 0
    var lastSendMessageRequest: ChatRequest?
    var lastSetPreferencesRequest: UserPreferencesRequest?

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

    func streamMessage(_ request: ChatRequest) async throws -> AsyncThrowingStream<String, Error> {
        streamMessageCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if let streamMessageError {
            throw streamMessageError
        }
        if shouldFail { throw errorToThrow }
        let payloads = streamMessageLines.isEmpty ? ["chunk-1"] : streamMessageLines
        return AsyncThrowingStream { continuation in
            for payload in payloads {
                continuation.yield(payload)
            }
            continuation.finish()
        }
    }

    func streamGuestMessage(_ request: ChatRequest) async throws -> AsyncThrowingStream<String, Error> {
        streamGuestMessageCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if let streamGuestMessageError {
            throw streamGuestMessageError
        }
        if shouldFail { throw errorToThrow }
        let payloads = streamGuestMessageLines.isEmpty ? ["guest-chunk-1"] : streamGuestMessageLines
        return AsyncThrowingStream { continuation in
            for payload in payloads {
                continuation.yield(payload)
            }
            continuation.finish()
        }
    }

    func signup(_ request: SignupRequest) async throws -> AuthResponse {
        signupCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
        return AuthResponse(
            token: "mock-token",
            refreshToken: "mock-refresh",
            expiresIn: "3600",
            user: ["email": AnyCodable(request.email)]
        )
    }

    func login(_ request: LoginRequest) async throws -> AuthResponse {
        loginCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
        return AuthResponse(
            token: "mock-token",
            refreshToken: "mock-refresh",
            expiresIn: "3600",
            user: ["email": AnyCodable(request.email)]
        )
    }

    func forgotPassword(_ email: String) async throws {
        forgotPasswordCallCount += 1
        if shouldFail { throw errorToThrow }
    }

    func googleSignIn(_ request: GoogleSignInRequest) async throws -> AuthResponse {
        googleSignInCallCount += 1
        if shouldFail { throw errorToThrow }
        return AuthResponse(
            token: "mock-token",
            refreshToken: "mock-refresh",
            expiresIn: "3600",
            user: ["uid": AnyCodable("google-123")]
        )
    }

    func refreshToken(_ request: RefreshTokenRequest) async throws -> AuthResponse {
        refreshTokenCallCount += 1
        if shouldFail { throw errorToThrow }
        return AuthResponse(
            token: "mock-new-token",
            refreshToken: "mock-new-refresh",
            expiresIn: "3600",
            user: ["uid": AnyCodable("123")]
        )
    }

    func getCurrentUser() async throws -> UserResponse {
        currentUserCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
        return UserResponse(
            id: "mock-user-id",
            firebaseUid: "mock-firebase-uid",
            email: "mock@example.com",
            displayName: "Mock User",
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z",
            lastLogin: "2025-01-02T00:00:00Z"
        )
    }

    func updateCurrentUser(_ request: UpdateUserRequest) async throws -> UserResponse {
        updateUserCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
        return UserResponse(
            id: "mock-user-id",
            firebaseUid: "mock-firebase-uid",
            email: request.email ?? "mock@example.com",
            displayName: request.displayName ?? "Mock User",
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-02T00:00:00Z",
            lastLogin: "2025-01-02T00:00:00Z"
        )
    }

    func deleteCurrentUser() async throws {
        deleteUserCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
    }

    func verifyToken() async throws {
        verifyTokenCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
    }

    func getPreferences() async throws -> UserPreferencesRequest {
        getPreferencesCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
        return mockUserPreferencesResponse ?? UserPreferencesRequest(
            languagePreference: "en",
            customSystemPrompt: nil,
            responsePreferences: nil
        )
    }

    func setPreferences(_ request: UserPreferencesRequest) async throws {
        setPreferencesCallCount += 1
        lastSetPreferencesRequest = request
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
    }

    func generateConversationTitle(_ request: GenerateTitleRequest) async throws -> Data {
        generateTitleCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
        return Data("Mock Title".utf8)
    }

    func listConversations() async throws -> [ConversationResponse] {
        listConversationsCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
        return [
            ConversationResponse(
                id: "conv-1",
                threadId: "thread-1",
                title: "Sample Conversation",
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-02T00:00:00Z"
            )
        ]
    }

    func createConversation(_ request: ConversationRequest) async throws -> ConversationResponse {
        createConversationCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
        if let mockCreateConversationResponse {
            return mockCreateConversationResponse
        }
        return ConversationResponse(
            id: "conv-created",
            threadId: nil,
            title: request.title,
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z"
        )
    }

    func deleteAllConversations() async throws {
        deleteAllConversationsCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
    }

    func deleteConversation(id: String) async throws {
        deleteConversationCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
    }

    func getMessages(conversationId: String) async throws -> ConversationMessagesResponse {
        getMessagesCallCount += 1
        if requestDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        if shouldFail { throw errorToThrow }
        return ConversationMessagesResponse(
            conversationId: conversationId,
            messages: []
        )
    }

    func ocr(_ request: OCRRequest) async throws -> OCRResponse {
        if shouldFail { throw errorToThrow }
        return OCRResponse(
            extractedText: "Mock OCR Text",
            imageUrl: "https://example.com/image.jpg",
            metadata: OCRMetadata(success: true, detectedLanguage: "en", confidence: "0.99", textLength: 13)
        )
    }

    func confirmFactCheck(_ request: ConfirmFactCheckRequest) async throws -> AsyncThrowingStream<String, Error> {
        if shouldFail { throw errorToThrow }
        return AsyncThrowingStream { continuation in
            continuation.yield("Fact check confirmed.")
            continuation.finish()
        }
    }

    func reset() {
        healthCheckCallCount = 0
        sendMessageCallCount = 0
        lastSendMessageRequest = nil
        shouldFail = false
        requestDelay = 0
        streamMessageCallCount = 0
        streamGuestMessageCallCount = 0
        signupCallCount = 0
        loginCallCount = 0
        currentUserCallCount = 0
        updateUserCallCount = 0
        deleteUserCallCount = 0
        verifyTokenCallCount = 0
        forgotPasswordCallCount = 0
        googleSignInCallCount = 0
        refreshTokenCallCount = 0
        getPreferencesCallCount = 0
        setPreferencesCallCount = 0
        generateTitleCallCount = 0
        listConversationsCallCount = 0
        createConversationCallCount = 0
        deleteAllConversationsCallCount = 0
        deleteConversationCallCount = 0
        getMessagesCallCount = 0
        mockCreateConversationResponse = nil
        streamMessageLines = []
        streamGuestMessageLines = []
        streamMessageError = nil
        streamGuestMessageError = nil
        mockUserPreferencesResponse = nil
        lastSetPreferencesRequest = nil
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

    func fetchMostRecentEmptyConversation(includeLocalOnly: Bool = false) async throws -> Conversation? {
        if shouldThrowError { throw errorToThrow }
        if includeLocalOnly {
            return mockConversations.first { $0.messages.isEmpty }
        }
        return mockConversations.first { $0.messages.isEmpty && !$0.isLocalOnly }
    }

    var conversationsPublisher: AnyPublisher<[Conversation], Never> {
        Just(mockConversations).eraseToAnyPublisher()
    }

    func createConversation(title: String, isLocalOnly: Bool = false) async throws -> Conversation {
        createConversationCallCount += 1
        if shouldThrowError { throw errorToThrow }

        if let mock = mockConversation {
            return mock
        }

        let conversation = Conversation(
            id: UUID().uuidString,
            threadId: nil,
            title: title,
            messages: [],
            isLocalOnly: isLocalOnly
        )
        mockConversations.append(conversation)
        return conversation
    }

    func fetchAllConversations() async throws -> [Conversation] {
        if shouldThrowError { throw errorToThrow }
        return mockConversations
    }

    func syncRemoteConversations(forceRefresh: Bool) async throws {
        // no-op for mock
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
        
        // Update mockConversation if it matches
        if mockConversation?.id == id {
            mockConversation = Conversation(
                id: mockConversation!.id,
                threadId: threadId,
                title: mockConversation!.title,
                createdAt: mockConversation!.createdAt,
                updatedAt: mockConversation!.updatedAt,
                messages: mockConversation!.messages,
                isLocalOnly: mockConversation!.isLocalOnly
            )
        }
        
        // Update in mockConversations array
        if let index = mockConversations.firstIndex(where: { $0.id == id }) {
            let conv = mockConversations[index]
            mockConversations[index] = Conversation(
                id: conv.id,
                threadId: threadId,
                title: conv.title,
                createdAt: conv.createdAt,
                updatedAt: conv.updatedAt,
                messages: conv.messages,
                isLocalOnly: conv.isLocalOnly
            )
        }
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

    func fetchMessages(forConversation conversationId: String, forceRefresh: Bool) async throws -> [Message] {
        fetchMessagesCallCount += 1
        if shouldThrowError { throw errorToThrow }
        return mockMessages.filter { $0.conversationId == conversationId }
    }

    func ocr(_ request: OCRRequest) async throws -> OCRResponse {
        if shouldThrowError { throw errorToThrow }
        return OCRResponse(
            extractedText: "Mock OCR Text",
            imageUrl: "https://example.com/image.jpg",
            metadata: OCRMetadata(success: true, detectedLanguage: "en", confidence: "0.99", textLength: 13)
        )
    }

    func confirmFactCheck(_ request: ConfirmFactCheckRequest) async throws -> AsyncThrowingStream<String, Error> {
        if shouldThrowError { throw errorToThrow }
        return AsyncThrowingStream { continuation in
            continuation.yield("Fact check confirmed.")
            continuation.finish()
        }
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
