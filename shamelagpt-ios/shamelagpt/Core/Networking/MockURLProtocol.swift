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
        let response = HTTPURLResponse(
            url: URL(string: "https://api.shamelagpt.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
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
        let response = HTTPURLResponse(
            url: URL(string: "https://api.shamelagpt.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        return MockResponse(data: data, response: response, delay: delay)
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

    // MARK: - Helper Methods

    /// Reads mock configuration from UserDefaults (shared between app and test)
    private func getMockResponseFromUserDefaults() -> MockResponse? {
        // Check if this is a chat API request
        guard let url = request.url?.absoluteString,
              url.contains("/api/chat") else {
            return nil
        }

        let delay = UserDefaults.standard.double(forKey: "mockDelay")

        // Check for network error
        if UserDefaults.standard.bool(forKey: "mockNetworkError") {
            return MockURLProtocol.networkError(delay: delay)
        }

        // Check for API error
        if let errorJSON = UserDefaults.standard.string(forKey: "mockChatError"),
           let errorData = errorJSON.data(using: .utf8) {
            let response = HTTPURLResponse(
                url: URL(string: "https://api.shamelagpt.com")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )
            return MockResponse(data: errorData, response: response, delay: delay)
        }

        // Check for successful response
        if let responseJSON = UserDefaults.standard.string(forKey: "mockChatResponse"),
           let responseData = responseJSON.data(using: .utf8) {
            let response = HTTPURLResponse(
                url: URL(string: "https://api.shamelagpt.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )
            return MockResponse(data: responseData, response: response, delay: delay)
        }

        return nil
    }

    override func stopLoading() {
        // Nothing to do
    }
}
