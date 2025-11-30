//
//  NetworkMockHelper.swift
//  shamelagptUITests
//
//  Helper for setting up network mocks in UI tests
//

import Foundation

/// Helper class for setting up network mocks via launch environment
class NetworkMockHelper {

    /// Keys for launch environment to configure mocking
    struct LaunchEnvironmentKeys {
        static let mockChatResponse = "MOCK_CHAT_RESPONSE"
        static let mockChatError = "MOCK_CHAT_ERROR"
        static let mockNetworkError = "MOCK_NETWORK_ERROR"
        static let mockDelay = "MOCK_DELAY"
        static let uiTesting = "UI_TESTING"
        static let resetAppState = "RESET_APP_STATE"
    }

    /// Base environment for UI tests with a successful chat response
    static func baseUITestEnvironment(
        delay: Double = 0.1,
        includeReset: Bool = true,
        overrides: [String: String] = [:]
    ) -> [String: String] {
        var env = setupSuccessfulChatResponse(delay: delay)
        env[LaunchEnvironmentKeys.uiTesting] = "1"
        if includeReset {
            env[LaunchEnvironmentKeys.resetAppState] = "1"
        }
        overrides.forEach { env[$0.key] = $0.value }
        return env
    }

    /// Sets up successful chat response mock
    static func setupSuccessfulChatResponse(delay: Double = 0.5) -> [String: String] {
        let response = """
        {
            "answer": "This is a test response from the mocked API.\\n\\nSources:\\n\\n* **book_name:** Source 1, **source_url:** https://example.com/source1\\n* **book_name:** Source 2, **source_url:** https://example.com/source2",
            "sources": [
                {
                    "title": "Source 1",
                    "url": "https://example.com/source1",
                    "excerpt": "Test excerpt 1"
                },
                {
                    "title": "Source 2",
                    "url": "https://example.com/source2",
                    "excerpt": "Test excerpt 2"
                }
            ],
            "conversation_id": "test-conversation-123",
            "thread_id": "test-thread-123"
        }
        """
        return [
            LaunchEnvironmentKeys.mockChatResponse: response,
            LaunchEnvironmentKeys.mockDelay: String(delay)
        ]
    }

    /// Sets up network error mock
    static func setupNetworkError() -> [String: String] {
        return [LaunchEnvironmentKeys.mockNetworkError: "1"]
    }

    /// Sets up API error mock
    static func setupAPIError(statusCode: Int = 500, message: String = "Server error") -> [String: String] {
        let error = """
        {
            "error": "\(message)",
            "status_code": \(statusCode)
        }
        """
        return [LaunchEnvironmentKeys.mockChatError: error]
    }

    /// Sets up response with only text, no sources
    static func setupResponseWithoutSources(delay: Double = 0.5) -> [String: String] {
        let response = """
        {
            "answer": "This is a test response without sources.",
            "sources": [],
            "conversation_id": "test-conversation-456",
            "thread_id": "test-thread-456"
        }
        """
        return [
            LaunchEnvironmentKeys.mockChatResponse: response,
            LaunchEnvironmentKeys.mockDelay: String(delay)
        ]
    }

    /// Sets up loading indicator test (longer delay)
    static func setupSlowResponse(delay: Double = 2.0) -> [String: String] {
        let response = """
        {
            "answer": "This response came after a delay.",
            "sources": [],
            "conversation_id": "test-conversation-789",
            "thread_id": "test-thread-789"
        }
        """
        return [
            LaunchEnvironmentKeys.mockChatResponse: response,
            LaunchEnvironmentKeys.mockDelay: String(delay)
        ]
    }
}
