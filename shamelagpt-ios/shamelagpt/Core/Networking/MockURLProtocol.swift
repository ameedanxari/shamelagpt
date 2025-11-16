//
//  MockURLProtocol.swift
//  shamelagptUITests
//
//  Created for mocking network responses in UI tests
//

import Foundation

/// Mock URLProtocol for stubbing network requests in UI tests
class MockURLProtocol: URLProtocol {

    // MARK: - Types

    private struct StreamChunk {
        let delay: TimeInterval
        let data: Data
    }

    struct MockResponse {
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?
        let delay: TimeInterval

        init(
            data: Data? = nil,
            response: HTTPURLResponse? = nil,
            error: Error? = nil,
            delay: TimeInterval = 0
        ) {
            self.data = data
            self.response = response
            self.error = error
            self.delay = delay
        }
    }

    // MARK: - Properties

    /// Storage for mock responses
    private static var mockResponses: [String: MockResponse] = [:]

    /// Request handler for dynamic mocking
    static var requestHandler: ((URLRequest) throws -> MockResponse)?

    // MARK: - Public Methods

    /// Registers a mock response for a specific URL pattern
    static func mockResponse(for urlPattern: String, response: MockResponse) {
        mockResponses[urlPattern] = response
    }

    /// Clears all mock responses
    static func clearMocks() {
        mockResponses.removeAll()
        requestHandler = nil
    }

    /// Creates a success response with JSON data
    static func successResponse(
        json: [String: Any],
        statusCode: Int = 200,
        delay: TimeInterval = 0.1
    ) -> MockResponse {
        let data = try? JSONSerialization.data(withJSONObject: json)
        let response = httpResponse(statusCode: statusCode)
        return MockResponse(data: data, response: response, delay: delay)
    }

    /// Creates an error response
    static func errorResponse(
        error: NSError,
        delay: TimeInterval = 0.1
    ) -> MockResponse {
        return MockResponse(error: error, delay: delay)
    }

    /// Creates a network error
    static func networkError(delay: TimeInterval = 0.1) -> MockResponse {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "No internet connection"]
        )
        return MockResponse(error: error, delay: delay)
    }

    /// Creates an API error response
    static func apiError(
        statusCode: Int,
        message: String = "API Error",
        delay: TimeInterval = 0.1
    ) -> MockResponse {
        let json = ["error": message]
        let data = try? JSONSerialization.data(withJSONObject: json)
        let response = httpResponse(statusCode: statusCode)
        return MockResponse(data: data, response: response, delay: delay)
    }

    /// Builds a standard response with content type
    private static func httpResponse(statusCode: Int, contentType: String = "application/json") -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://api.shamelagpt.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": contentType]
        )!
    }

    // MARK: - URLProtocol Overrides

    override class func canInit(with request: URLRequest) -> Bool {
        // Handle all requests
        AppLogger.network.logInfo("MockURLProtocol.canInit handling request: \(request.url?.absoluteString ?? "nil")")
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if handleStreamRequestIfNeeded() {
            return
        }

        // Try to find a matching mock response
        var mockResponse: MockResponse?

        if let handler = MockURLProtocol.requestHandler {
            // Use request handler if available
            do {
                mockResponse = try handler(request)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }
        } else {
            // Check UserDefaults for mock configuration (set by app during UI testing)
            mockResponse = getMockResponseFromUserDefaults()

            // If no UserDefaults config, find mock by URL pattern
            if mockResponse == nil {
                mockResponse = MockURLProtocol.mockResponses.first { pattern, _ in
                    guard let url = request.url?.absoluteString else { return false }
                    return url.contains(pattern)
                }?.value
            }
        }

        // Simulate network delay
        let delay = mockResponse?.delay ?? 0

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }

            if let error = mockResponse?.error {
                // Return error
                self.client?.urlProtocol(self, didFailWithError: error)
            } else if let response = mockResponse?.response {
                // Return response
                self.client?.urlProtocol(
                    self,
                    didReceive: response,
                    cacheStoragePolicy: .notAllowed
                )

                if let data = mockResponse?.data {
                    self.client?.urlProtocol(self, didLoad: data)
                }

                self.client?.urlProtocolDidFinishLoading(self)
            } else {
                // No mock found - return 404
                let response = HTTPURLResponse(
                    url: self.request.url!,
                    statusCode: 404,
                    httpVersion: nil,
                    headerFields: nil
                )!
                self.client?.urlProtocol(
                    self,
                    didReceive: response,
                    cacheStoragePolicy: .notAllowed
                )
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }
    }

    private func handleStreamRequestIfNeeded() -> Bool {
        guard let urlString = request.url?.absoluteString else {
            return false
        }

        let isStreamEndpoint = urlString.contains("/api/chat/stream")
            || urlString.contains("/api/guest/chat/stream")
            || urlString.contains("/api/confirm-fact-check")

        guard isStreamEndpoint else {
            return false
        }

        let baseDelay = UserDefaults.standard.double(forKey: "mockChatStreamDelay")
        let fallbackDelay = UserDefaults.standard.double(forKey: "mockDelay")
        let delay = baseDelay > 0 ? baseDelay : fallbackDelay

        if UserDefaults.standard.bool(forKey: "mockNetworkError") {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                let error = MockURLProtocol.networkError().error ?? URLError(.notConnectedToInternet)
                self.client?.urlProtocol(self, didFailWithError: error)
            }
            return true
        }

        if UserDefaults.standard.bool(forKey: "mockTimeoutError") {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                self.client?.urlProtocol(self, didFailWithError: URLError(.timedOut))
            }
            return true
        }

        if let errorJSON = UserDefaults.standard.string(forKey: "mockChatError"),
           let errorData = errorJSON.data(using: .utf8) {
            let statusCode = parseStatusCode(from: errorJSON) ?? 500
            let response = MockURLProtocol.httpResponse(statusCode: statusCode, contentType: "application/json")
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: errorData)
                self.client?.urlProtocolDidFinishLoading(self)
            }
            return true
        }

        let streamEvents = loadStreamEvents(defaultDelay: delay)
        guard !streamEvents.isEmpty else {
            return false
        }

        let response = MockURLProtocol.httpResponse(statusCode: 200, contentType: "text/event-stream")
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        var cumulativeDelay: TimeInterval = 0
        for event in streamEvents {
            cumulativeDelay += event.delay
            DispatchQueue.global().asyncAfter(deadline: .now() + cumulativeDelay) { [weak self] in
                guard let self = self else { return }
                self.client?.urlProtocol(self, didLoad: event.data)
            }
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + cumulativeDelay + 0.05) { [weak self] in
            guard let self = self else { return }
            self.client?.urlProtocolDidFinishLoading(self)
        }

        return true
    }

    private func loadStreamEvents(defaultDelay: TimeInterval) -> [StreamChunk] {
        if let streamJSON = UserDefaults.standard.string(forKey: "mockChatStream"),
           let data = streamJSON.data(using: .utf8),
           let rawArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return rawArray.compactMap { entry in
                let delay = entry["delay"] as? TimeInterval ?? defaultDelay
                if let rawData = entry["data"] as? String {
                    return StreamChunk(delay: delay, data: sseData(from: rawData))
                }

                var event = entry
                event.removeValue(forKey: "delay")
                guard !event.isEmpty,
                      let eventData = try? JSONSerialization.data(withJSONObject: event),
                      let payload = String(data: eventData, encoding: .utf8)
                else {
                    return nil
                }
                return StreamChunk(delay: delay, data: sseData(from: payload))
            }
        }

        return buildDefaultStreamEvents(defaultDelay: defaultDelay)
    }

    private func buildDefaultStreamEvents(defaultDelay: TimeInterval) -> [StreamChunk] {
        guard let responseJSON = UserDefaults.standard.string(forKey: "mockChatResponse"),
              let data = responseJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return []
        }

        let answer = json["answer"] as? String ?? "Mocked streaming response."
        let threadId = json["thread_id"] as? String ?? json["threadId"] as? String ?? "mock-thread"
        let thinking = UserDefaults.standard.string(forKey: "mockChatThinking") ?? "Thinking..."

        let midpoint = max(1, answer.count / 2)
        let splitIndex = answer.index(answer.startIndex, offsetBy: midpoint)
        let firstChunk = String(answer[..<splitIndex])
        let secondChunk = String(answer[splitIndex...])

        let events: [[String: Any]] = [
            ["type": "metadata", "thread_id": threadId],
            ["type": "thinking", "content": thinking],
            ["type": "chunk", "content": firstChunk],
            ["type": "chunk", "content": secondChunk],
            ["type": "done", "full_answer": answer]
        ]

        return events.compactMap { event in
            guard let eventData = try? JSONSerialization.data(withJSONObject: event),
                  let payload = String(data: eventData, encoding: .utf8)
            else { return nil }
            return StreamChunk(delay: defaultDelay, data: sseData(from: payload))
        }
    }

    private func sseData(from payload: String) -> Data {
        let line = "data: \(payload)\n\n"
        return line.data(using: .utf8) ?? Data()
    }

    // MARK: - Helper Methods

    /// Reads mock configuration from UserDefaults (shared between app and test)
    private func getMockResponseFromUserDefaults() -> MockResponse? {
        guard let urlString = request.url?.absoluteString else {
            return nil
        }

        let delay = UserDefaults.standard.double(forKey: "mockDelay")
        AppLogger.network.logDebug("MockURLProtocol: Processing request: \(urlString) with delay: \(delay)")

        // Check for network error (applies to all mocked endpoints)
        if UserDefaults.standard.bool(forKey: "mockNetworkError") {
            AppLogger.network.logInfo("MockURLProtocol: Returning network error for request")
            return MockURLProtocol.networkError(delay: delay)
        }

        if UserDefaults.standard.bool(forKey: "mockTimeoutError") {
            AppLogger.network.logInfo("MockURLProtocol: Returning timeout error for request")
            return MockResponse(error: URLError(.timedOut), delay: delay)
        }

        // Preferences endpoint
        if urlString.contains("/api/auth/me/preferences") {
            return mockPreferencesResponse(delay: delay)
        }

        // Conversation endpoints
        if urlString.contains("/api/conversations") {
            return mockConversationsResponse(delay: delay)
        }

        // Chat API request (both /api/chat and /api/guest/chat)
        if urlString.contains("/api/chat") || urlString.contains("/api/guest/chat") {
            // Check for API error
            if let errorJSON = UserDefaults.standard.string(forKey: "mockChatError"),
               let errorData = errorJSON.data(using: .utf8) {
                AppLogger.network.logInfo("MockURLProtocol: Returning API error for chat request: \(errorJSON)")
                let statusCode = parseStatusCode(from: errorJSON) ?? 500
                let response = MockURLProtocol.httpResponse(statusCode: statusCode)
                return MockResponse(data: errorData, response: response, delay: delay)
            }

            // Check for successful response
            if let responseJSON = UserDefaults.standard.string(forKey: "mockChatResponse"),
               let responseData = responseJSON.data(using: .utf8) {
                AppLogger.network.logInfo("MockURLProtocol: Returning success response for chat request")
                let response = MockURLProtocol.httpResponse(statusCode: 200)
                return MockResponse(data: responseData, response: response, delay: delay)
            }

            AppLogger.network.logWarning("MockURLProtocol: No mock configuration found for chat request")
        }

        AppLogger.network.logDebug("MockURLProtocol: No mock configuration found for request")
        return nil
    }

    private func mockPreferencesResponse(delay: TimeInterval) -> MockResponse? {
        let method = request.httpMethod?.uppercased() ?? "GET"

        if method == "PUT" {
            return MockURLProtocol.successResponse(json: [:], statusCode: 200, delay: delay)
        }

        if method == "GET" {
            if let preferencesJSON = UserDefaults.standard.string(forKey: "mockPreferences"),
               let preferencesData = preferencesJSON.data(using: .utf8) {
                AppLogger.network.logInfo("MockURLProtocol: Returning mocked preferences")
                let response = MockURLProtocol.httpResponse(statusCode: 200)
                return MockResponse(data: preferencesData, response: response, delay: delay)
            }

            let defaultPreferences: [String: Any] = [
                "language_preference": "en",
                "custom_system_prompt": "Be concise.",
                "response_preferences": [
                    "length": "short",
                    "style": "academic",
                    "focus": "historical"
                ]
            ]
            AppLogger.network.logInfo("MockURLProtocol: Returning default preferences")
            return MockURLProtocol.successResponse(json: defaultPreferences, statusCode: 200, delay: delay)
        }

        return nil
    }

    private func mockConversationsResponse(delay: TimeInterval) -> MockResponse? {
        guard let url = request.url else { return nil }
        let method = request.httpMethod?.uppercased() ?? "GET"
        let pathComponents = url.pathComponents

        if let conversationsIndex = pathComponents.firstIndex(of: "conversations"),
           pathComponents.last == "messages",
           pathComponents.count > conversationsIndex + 1 {
            let conversationId = pathComponents[conversationsIndex + 1]
            return mockMessagesResponse(conversationId: conversationId, delay: delay)
        }

        if method == "DELETE" {
            return MockURLProtocol.successResponse(json: [:], statusCode: 200, delay: delay)
        }

        if method != "GET" {
            return nil
        }

        let conversations = buildMockConversations()
        let data = try? JSONSerialization.data(withJSONObject: conversations)
        let response = MockURLProtocol.httpResponse(statusCode: 200)
        return MockResponse(data: data, response: response, delay: delay)
    }

    private func mockMessagesResponse(conversationId: String, delay: TimeInterval) -> MockResponse? {
        let messages = buildMockMessages(conversationId: conversationId)
        let payload: [String: Any] = [
            "conversation_id": conversationId,
            "messages": messages
        ]
        let data = try? JSONSerialization.data(withJSONObject: payload)
        let response = MockURLProtocol.httpResponse(statusCode: 200)
        return MockResponse(data: data, response: response, delay: delay)
    }

    private func buildMockConversations() -> [[String: Any]] {
        let history = loadMockHistory()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackDate = Date()

        return history.map { entry in
            let id = entry["id"] as? String ?? UUID().uuidString
            let title = entry["title"] as? String ?? "New Chat"
            let updatedAt = dateFromMilliseconds(entry["updated_at"]) ?? fallbackDate
            let iso = formatter.string(from: updatedAt)

            return [
                "id": id,
                "thread_id": "thread-\(id)",
                "title": title,
                "created_at": iso,
                "updated_at": iso
            ]
        }
    }

    private func buildMockMessages(conversationId: String) -> [[String: Any]] {
        let history = loadMockHistory()
        guard let entry = history.first(where: { ($0["id"] as? String) == conversationId }) else {
            return []
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let baseDate = dateFromMilliseconds(entry["updated_at"]) ?? Date()

        guard let rawMessages = entry["messages"] as? [[String: Any]] else {
            return []
        }

        return rawMessages.enumerated().map { index, raw in
            let messageId = raw["id"] as? String
            let content = raw["content"] as? String ?? ""
            let isUserMessage = raw["is_user_message"] as? Bool ?? false
            let timestamp = baseDate.addingTimeInterval(TimeInterval(-60 * (rawMessages.count - index)))

            var payload: [String: Any] = [
                "role": isUserMessage ? "user" : "assistant",
                "content": content,
                "created_at": formatter.string(from: timestamp)
            ]
            if let messageId {
                payload["id"] = messageId
            }
            return payload
        }
    }

    private func loadMockHistory() -> [[String: Any]] {
        guard let historyJSON = UserDefaults.standard.string(forKey: "mockHistory"),
              let historyData = historyJSON.data(using: .utf8) else {
            return []
        }

        do {
            let object = try JSONSerialization.jsonObject(with: historyData, options: [])
            return object as? [[String: Any]] ?? []
        } catch {
            AppLogger.network.logError("MockURLProtocol: Failed to decode mock history", error: error)
            return []
        }
    }

    private func dateFromMilliseconds(_ value: Any?) -> Date? {
        if let doubleValue = value as? Double {
            return Date(timeIntervalSince1970: doubleValue / 1000.0)
        }
        if let intValue = value as? Int {
            return Date(timeIntervalSince1970: Double(intValue) / 1000.0)
        }
        if let stringValue = value as? String, let doubleValue = Double(stringValue) {
            return Date(timeIntervalSince1970: doubleValue / 1000.0)
        }
        return nil
    }

    private func parseStatusCode(from rawJSON: String) -> Int? {
        guard let data = rawJSON.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        if let intCode = object["status_code"] as? Int {
            return intCode
        }
        if let stringCode = object["status_code"] as? String, let intCode = Int(stringCode) {
            return intCode
        }
        return nil
    }

    override func stopLoading() {
        // Nothing to do
    }
}
