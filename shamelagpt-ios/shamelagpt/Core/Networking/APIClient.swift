//
//  APIClient.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Combine

/// Protocol defining the API client interface
protocol APIClientProtocol {
    func healthCheck() async throws -> HealthResponse
    func sendMessage(_ request: ChatRequest) async throws -> ChatResponse
    func streamMessage(_ request: ChatRequest) async throws -> AsyncThrowingStream<String, Error>
    func streamGuestMessage(_ request: ChatRequest) async throws -> AsyncThrowingStream<String, Error>
    func signup(_ request: SignupRequest) async throws -> AuthResponse
    func login(_ request: LoginRequest) async throws -> AuthResponse
    func forgotPassword(_ email: String) async throws
    func googleSignIn(_ request: GoogleSignInRequest) async throws -> AuthResponse
    func refreshToken(_ request: RefreshTokenRequest) async throws -> AuthResponse
    func getCurrentUser() async throws -> UserResponse
    func updateCurrentUser(_ request: UpdateUserRequest) async throws -> UserResponse
    func deleteCurrentUser() async throws
    func verifyToken() async throws
    func getPreferences() async throws -> UserPreferencesRequest
    func setPreferences(_ request: UserPreferencesRequest) async throws
    func generateConversationTitle(_ request: GenerateTitleRequest) async throws -> Data
    func listConversations() async throws -> [ConversationResponse]
    func createConversation(_ request: ConversationRequest) async throws -> ConversationResponse
    func deleteAllConversations() async throws
    func deleteConversation(id: String) async throws
    func getMessages(conversationId: String) async throws -> ConversationMessagesResponse
    func ocr(_ request: OCRRequest) async throws -> OCRResponse
    func confirmFactCheck(_ request: ConfirmFactCheckRequest) async throws -> AsyncThrowingStream<String, Error>
}

/// Main API client for communicating with the ShamelaGPT backend
final class APIClient: APIClientProtocol {

    // MARK: - Properties

    private let baseURL: URL
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private let authTokenProvider: (() -> String?)?

    /// Lightweight empty response placeholder
    private struct EmptyResponse: Decodable {}

    // MARK: - Configuration

    private struct Configuration {
        static let baseURLString = "https://shamelagpt.com"
        static let timeoutInterval: TimeInterval = 30.0
        static let defaultHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }

    // MARK: - Initialization

    init(
        baseURL: URL? = nil,
        session: URLSession? = nil,
        authTokenProvider: (() -> String?)? = nil
    ) {
        // Use provided base URL or default
        if let baseURL = baseURL {
            self.baseURL = baseURL
        } else if let url = URL(string: Configuration.baseURLString) {
            self.baseURL = url
        } else {
            fatalError("Invalid base URL: \(Configuration.baseURLString)")
        }

        // Configure URLSession
        let isUITesting = Self.isUITestEnvironment()
        if let providedSession = session {
            self.session = providedSession
        } else if isUITesting {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = Configuration.timeoutInterval
            configuration.timeoutIntervalForResource = Configuration.timeoutInterval * 2
            configuration.httpAdditionalHeaders = Configuration.defaultHeaders
            configuration.waitsForConnectivity = true
            configuration.protocolClasses = [MockURLProtocol.self]
            AppLogger.network.logInfo("APIClient init - using MockURLProtocol because UI-Testing is enabled, args: \(CommandLine.arguments), env has XCTestConfig: \(ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil)")
            self.session = URLSession(configuration: configuration)
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = Configuration.timeoutInterval
            configuration.timeoutIntervalForResource = Configuration.timeoutInterval * 2
            configuration.httpAdditionalHeaders = Configuration.defaultHeaders
            configuration.waitsForConnectivity = true
            self.session = URLSession(configuration: configuration)
        }

        // Configure JSON encoder/decoder
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.keyEncodingStrategy = .convertToSnakeCase

        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

        self.authTokenProvider = authTokenProvider
    }

    /// Detects UI test environment (arguments, env, or runner bundle path)
    private static func isUITestEnvironment() -> Bool {
        let argsContainFlag = CommandLine.arguments.contains("UI-Testing")
        let env = ProcessInfo.processInfo.environment
        let hasXCTestConfig = env["XCTestConfigurationFilePath"] != nil
        let bundlePathContainsRunner = Bundle.main.bundlePath.contains("ShamelaGPTUITests-Runner")
        let hasUITestingEnv = env["UI_TESTING"] == "1"
        return argsContainFlag || hasXCTestConfig || bundlePathContainsRunner || hasUITestingEnv
    }

    // MARK: - API Endpoints

    /// Performs a health check on the API
    /// GET /api/health
    func healthCheck() async throws -> HealthResponse {
        let endpoint = baseURL.appendingPathComponent("api/health")
        return try await performRequest(url: endpoint, method: "GET")
    }

    /// Sends a chat message to the API
    /// POST /api/chat
    func sendMessage(_ request: ChatRequest) async throws -> ChatResponse {
        // If an auth token is not available, route to the guest chat endpoint
        let endpointPath = (authTokenProvider?() == nil) ? "api/guest/chat" : "api/chat"
        let endpoint = baseURL.appendingPathComponent(endpointPath)
        return try await performRequest(
            url: endpoint,
            method: "POST",
            body: request
        )
    }

    /// Streaming chat via SSE for authenticated users
    /// POST /api/chat/stream
    func streamMessage(_ request: ChatRequest) async throws -> AsyncThrowingStream<String, Error> {
        let endpoint = baseURL.appendingPathComponent("api/chat/stream")
        return try await streamRequest(url: endpoint, body: request)
    }

    /// Streaming chat via SSE for guest users
    /// POST /api/guest/chat/stream
    func streamGuestMessage(_ request: ChatRequest) async throws -> AsyncThrowingStream<String, Error> {
        let endpoint = baseURL.appendingPathComponent("api/guest/chat/stream")
        return try await streamRequest(url: endpoint, body: request)
    }

    /// Signup
    func signup(_ request: SignupRequest) async throws -> AuthResponse {
        let endpoint = baseURL.appendingPathComponent("api/auth/signup")
        return try await performRequest(url: endpoint, method: "POST", body: request)
    }

    /// Login
    func login(_ request: LoginRequest) async throws -> AuthResponse {
        let endpoint = baseURL.appendingPathComponent("api/auth/login")
        return try await performRequest(url: endpoint, method: "POST", body: request)
    }

    /// Forgot password
    func forgotPassword(_ email: String) async throws {
        let endpoint = baseURL.appendingPathComponent("api/auth/forgot-password")
        let request = ForgotPasswordRequest(email: email)
        _ = try await performRequest(url: endpoint, method: "POST", body: request) as EmptyResponse
    }

    /// Google Sign-In
    func googleSignIn(_ request: GoogleSignInRequest) async throws -> AuthResponse {
        let endpoint = baseURL.appendingPathComponent("api/auth/google")
        return try await performRequest(url: endpoint, method: "POST", body: request)
    }

    /// Refresh token
    func refreshToken(_ request: RefreshTokenRequest) async throws -> AuthResponse {
        let endpoint = baseURL.appendingPathComponent("api/auth/refresh")
        return try await performRequest(url: endpoint, method: "POST", body: request)
    }

    /// Current user
    func getCurrentUser() async throws -> UserResponse {
        let endpoint = baseURL.appendingPathComponent("api/auth/me")
        return try await performRequest(url: endpoint, method: "GET")
    }

    /// Update user
    func updateCurrentUser(_ request: UpdateUserRequest) async throws -> UserResponse {
        let endpoint = baseURL.appendingPathComponent("api/auth/me")
        return try await performRequest(url: endpoint, method: "PUT", body: request)
    }

    /// Delete current user
    func deleteCurrentUser() async throws {
        let endpoint = baseURL.appendingPathComponent("api/auth/me")
        _ = try await performRequest(url: endpoint, method: "DELETE") as EmptyResponse
    }

    /// Verify token
    func verifyToken() async throws {
        let endpoint = baseURL.appendingPathComponent("api/auth/verify")
        _ = try await performRequest(url: endpoint, method: "GET") as EmptyResponse
    }

    /// Preferences
    func getPreferences() async throws -> UserPreferencesRequest {
        let endpoint = baseURL.appendingPathComponent("api/auth/me/preferences")
        return try await performRequest(url: endpoint, method: "GET")
    }

    func setPreferences(_ request: UserPreferencesRequest) async throws {
        let endpoint = baseURL.appendingPathComponent("api/auth/me/preferences")
        _ = try await performRequest(url: endpoint, method: "PUT", body: request) as EmptyResponse
    }

    /// Title generation
    func generateConversationTitle(_ request: GenerateTitleRequest) async throws -> Data {
        let endpoint = baseURL.appendingPathComponent("api/chat/generate-title")
        return try await performRequest(url: endpoint, method: "POST", body: request)
    }

    /// Conversations
    func listConversations() async throws -> [ConversationResponse] {
        let endpoint = baseURL.appendingPathComponent("api/conversations")
        return try await performRequest(url: endpoint, method: "GET")
    }

    func createConversation(_ request: ConversationRequest) async throws -> ConversationResponse {
        let endpoint = baseURL.appendingPathComponent("api/conversations")
        return try await performRequest(url: endpoint, method: "POST", body: request)
    }

    func deleteAllConversations() async throws {
        let endpoint = baseURL.appendingPathComponent("api/conversations")
        _ = try await performRequest(url: endpoint, method: "DELETE") as EmptyResponse
    }

    func deleteConversation(id: String) async throws {
        let endpoint = baseURL
            .appendingPathComponent("api/conversations")
            .appendingPathComponent(id)
        _ = try await performRequest(url: endpoint, method: "DELETE") as EmptyResponse
    }

    func getMessages(conversationId: String) async throws -> ConversationMessagesResponse {
        let endpoint = baseURL
            .appendingPathComponent("api/conversations")
            .appendingPathComponent(conversationId)
            .appendingPathComponent("messages")
        AppLogger.network.logInfo("Fetching messages for conversation \(conversationId) from API")
        return try await performRequest(url: endpoint, method: "GET")
    }

    /// OCR
    func ocr(_ request: OCRRequest) async throws -> OCRResponse {
        let endpoint = baseURL.appendingPathComponent("api/chat/ocr")
        return try await performRequest(url: endpoint, method: "POST", body: request)
    }

    /// Confirm fact-check (SSE)
    func confirmFactCheck(_ request: ConfirmFactCheckRequest) async throws -> AsyncThrowingStream<String, Error> {
        let endpoint = baseURL.appendingPathComponent("api/chat/confirm-factcheck")
        return try await streamRequest(url: endpoint, body: request)
    }

    // MARK: - Private Methods

    /// Performs a network request and decodes the response
    private func performRequest<T: Decodable>(
        url: URL,
        method: String,
        body: Encodable? = nil
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method

        AppLogger.network.logDebug("Making \(method) request to: \(url.absoluteString)")
        if let token = authTokenProvider?() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body if provided
        if let body = body {
            do {
                let encodedBody = try jsonEncoder.encode(body)
                request.httpBody = encodedBody
                if let bodyString = String(data: encodedBody, encoding: .utf8) {
                    AppLogger.network.logDebug("Request body: \(bodyString)")
                }
            } catch {
                AppLogger.network.logError("Failed to encode request body", error: error)
                throw NetworkError.decodingError(error)
            }
        }

        // Perform request
        let (data, response) = try await performDataTask(request: request)

        // Log response details
        if let httpResponse = response as? HTTPURLResponse {
            AppLogger.network.logInfo("Response status code: \(httpResponse.statusCode)")
        }
        AppLogger.network.logDebug("Response data size: \(data.count) bytes")
        if let responseString = String(data: data, encoding: .utf8) {
            // Log first 1000 chars to see more of the response
            AppLogger.network.logDebug("Response body: \(responseString.prefix(1000))...")

            // Also log the full response for debugging markdown issues
            AppLogger.network.logDebug("Full response length: \(responseString.count) characters")
        }

        // Validate response
        try validateResponse(response)

        // Decode response
        do {
            let decodedResponse = try jsonDecoder.decode(T.self, from: data)
            AppLogger.network.logInfo("Successfully decoded response")
            return decodedResponse
        } catch {
            AppLogger.network.logError("Failed to decode response", error: error)
            throw NetworkError.decodingError(error)
        }
    }

    /// Performs the actual data task with proper error handling
    private func performDataTask(request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            let protocolClasses = session.configuration.protocolClasses ?? []
            AppLogger.network.logDebug("URLSession configuration protocol classes: \(protocolClasses)")
            AppLogger.network.logDebug("URLSession configuration type: \(type(of: session))")
            let (data, response) = try await session.data(for: request)
            return (data, response)
        } catch {
            // Map URLError to NetworkError
            if let urlError = error as? URLError {
                throw mapURLError(urlError)
            } else {
                throw NetworkError.unknown(error)
            }
        }
    }

    /// Validates the HTTP response
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    /// Maps URLError to NetworkError
    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .timedOut:
            return .timeout
        case .badURL, .unsupportedURL:
            return .invalidURL
        case .badServerResponse:
            return .invalidResponse
        default:
            return .unknown(error)
        }
    }

    /// Streams SSE responses as text chunks
    private func streamRequest(
        url: URL,
        body: Encodable
    ) async throws -> AsyncThrowingStream<String, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = authTokenProvider?() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode body
        let encodedBody = try jsonEncoder.encode(AnyEncodable(body))
        request.httpBody = encodedBody

        // Log request details - headers and a preview of the body
        AppLogger.network.logInfo("Starting SSE stream to: \(url.absoluteString)")
        AppLogger.network.logDebug("SSE request headers: \(request.allHTTPHeaderFields ?? [:])")
        if let bodyString = String(data: encodedBody, encoding: .utf8) {
            AppLogger.network.logDebug("SSE request body (first 2000 chars): \(bodyString.prefix(2000))")
        }

        let (bytes, response) = try await session.bytes(for: request)

        if let httpResp = response as? HTTPURLResponse {
            AppLogger.network.logInfo("SSE response status: \(httpResp.statusCode)")
            AppLogger.network.logDebug("SSE response headers: \(httpResp.allHeaderFields)")
        }

        try validateResponse(response)

        let stream = AsyncThrowingStream<String, Error> { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        // Log each raw SSE line for debugging truncated to reasonable length
                        // AppLogger.network.logDebug("SSE line (raw): \(String(line.prefix(200)))")
                        continuation.yield(line)
                    }
                    continuation.finish()
                } catch {
                    AppLogger.network.logError("SSE stream error", error: error)
                    continuation.finish(throwing: error)
                }
            }
        }

        return stream
    }
}

/// Type-erasing wrapper to encode generic Encodable bodies for streaming
private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ encodable: Encodable) {
        self.encodeFunc = encodable.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}

// MARK: - Combine Support

extension APIClient {
    /// Publisher for health check
    func healthCheckPublisher() -> AnyPublisher<HealthResponse, Error> {
        Future { promise in
            Task {
                do {
                    let response = try await self.healthCheck()
                    promise(.success(response))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Publisher for sending message
    func sendMessagePublisher(_ request: ChatRequest) -> AnyPublisher<ChatResponse, Error> {
        Future { promise in
            Task {
                do {
                    let response = try await self.sendMessage(request)
                    promise(.success(response))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Mock Client for Testing
#if DEBUG
final class PreviewMockAPIClient: APIClientProtocol {
    var shouldFail = false
    var mockHealthResponse = HealthResponse(status: "ok", service: "shamelagpt-api")
    var mockChatResponse = ChatResponse(
        answer: "This is a mock response.\n\nSources:\n\n* **book_name:** صحيح البخاري, **source_url:** https://shamela.ws/book/1234/52",
        threadId: "mock-thread-id"
    )
    var mockAuthResponse = AuthResponse(
        token: "mock-token",
        refreshToken: "mock-refresh",
        expiresIn: "3600",
        user: [:]
    )

    func healthCheck() async throws -> HealthResponse {
        if shouldFail {
            throw NetworkError.noConnection
        }
        return mockHealthResponse
    }

    func sendMessage(_ request: ChatRequest) async throws -> ChatResponse {
        if shouldFail {
            throw NetworkError.timeout
        }
        return mockChatResponse
    }

    func streamMessage(_ request: ChatRequest) async throws -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield("data: \(mockChatResponse.answer)")
            continuation.finish()
        }
    }

    func streamGuestMessage(_ request: ChatRequest) async throws -> AsyncThrowingStream<String, Error> {
        try await streamMessage(request)
    }

    func signup(_ request: SignupRequest) async throws -> AuthResponse {
        if shouldFail { throw NetworkError.unknown(NSError(domain: "PreviewMockAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "mock network error"])) }
        return mockAuthResponse
    }

    func login(_ request: LoginRequest) async throws -> AuthResponse {
        if shouldFail { throw NetworkError.unknown(NSError(domain: "PreviewMockAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "mock network error"])) }
        return mockAuthResponse
    }

    func getCurrentUser() async throws -> UserResponse {
        UserResponse(
            id: "user-id",
            firebaseUid: "firebase-uid",
            email: "user@example.com",
            displayName: "Mock User",
            createdAt: "",
            updatedAt: "",
            lastLogin: ""
        )
    }

    func updateCurrentUser(_ request: UpdateUserRequest) async throws -> UserResponse {
        try await getCurrentUser()
    }

    func deleteCurrentUser() async throws {
        return
    }

    func verifyToken() async throws {
        return
    }

    func getPreferences() async throws -> UserPreferencesRequest {
        UserPreferencesRequest(
            languagePreference: "English",
            customSystemPrompt: "mock",
            responsePreferences: ResponsePreferencesRequest(length: "short", style: "concise", focus: "summary")
        )
    }

    func setPreferences(_ request: UserPreferencesRequest) async throws {
        return
    }

    func generateConversationTitle(_ request: GenerateTitleRequest) async throws -> Data {
        return Data("{\"title\":\"Mock Title\"}".utf8)
    }

    func listConversations() async throws -> [ConversationResponse] {
        return []
    }

    func createConversation(_ request: ConversationRequest) async throws -> ConversationResponse {
        return ConversationResponse(id: "c1", threadId: "t1", title: request.title, createdAt: nil, updatedAt: nil)
    }

    func deleteAllConversations() async throws {
        return
    }

    func deleteConversation(id: String) async throws {
        return
    }

    func forgotPassword(_ email: String) async throws {
        return
    }

    func googleSignIn(_ request: GoogleSignInRequest) async throws -> AuthResponse {
        return mockAuthResponse
    }

    func refreshToken(_ request: RefreshTokenRequest) async throws -> AuthResponse {
        return mockAuthResponse
    }

    func getMessages(conversationId: String) async throws -> ConversationMessagesResponse {
        return ConversationMessagesResponse(conversationId: conversationId, messages: [])
    }

    func ocr(_ request: OCRRequest) async throws -> OCRResponse {
        return OCRResponse(
            extractedText: "Extracted mock text",
            imageUrl: "https://example.com/mock.png",
            metadata: OCRMetadata(success: true, detectedLanguage: "en", confidence: "0.99", textLength: 19)
        )
    }

    func confirmFactCheck(_ request: ConfirmFactCheckRequest) async throws -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield("data: This is a facts check response.")
            continuation.finish()
        }
    }
}
#endif
