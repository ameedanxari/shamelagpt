//
//  NetworkMockHelper.swift
//  shamelagptUITests
//
//  Helper for setting up network mocks in UI tests
//

import Foundation

/// Helper class for setting up network mocks via launch environment
class NetworkMockHelper {
    enum MockScenarioID: String {
        case success = "success"
        case http400 = "http_400"
        case http401 = "http_401"
        case http403 = "http_403"
        case http404 = "http_404"
        case http429 = "http_429"
        case http500 = "http_500"
        case timeout = "timeout"
        case offline = "offline"
    }

    /// Keys for launch environment to configure mocking
    struct LaunchEnvironmentKeys {
        static let mockScenarioId = "MOCK_SCENARIO_ID"
        static let mockChatResponse = "MOCK_CHAT_RESPONSE"
        static let mockChatError = "MOCK_CHAT_ERROR"
        static let mockNetworkError = "MOCK_NETWORK_ERROR"
        static let mockDelay = "MOCK_DELAY"
        static let mockChatStreamEvents = "MOCK_CHAT_STREAM"
        static let mockChatStreamDelay = "MOCK_CHAT_STREAM_DELAY"
        static let mockHistory = "MOCK_HISTORY"
        static let mockPreferences = "MOCK_PREFERENCES"
        static let uiTesting = "UI_TESTING"
        static let resetAppState = "RESET_APP_STATE"
        static let skipWelcome = "SKIP_WELCOME"
    }

    /// Base environment for UI tests with a successful chat response
    static func baseUITestEnvironment(
        delay: Double = 0.1,
        includeReset: Bool = true,
        overrides: [String: String] = [:]
    ) -> [String: String] {
        var env = setupSuccessfulChatResponse(delay: delay)
        env[LaunchEnvironmentKeys.mockScenarioId] = MockScenarioID.success.rawValue
        env[LaunchEnvironmentKeys.uiTesting] = "1"
        // Default to skipping welcome (pre-authenticated) for most tests
        env[LaunchEnvironmentKeys.skipWelcome] = "1"
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

    /// Sets up one canonical scenario id for API-driven tests.
    static func setupScenario(_ scenario: MockScenarioID, delay: Double = 0.1) -> [String: String] {
        var env: [String: String] = [
            LaunchEnvironmentKeys.mockScenarioId: scenario.rawValue,
            LaunchEnvironmentKeys.mockDelay: String(delay)
        ]

        // Backward-compatible flags for existing tests/app code paths.
        switch scenario {
        case .offline:
            env[LaunchEnvironmentKeys.mockNetworkError] = "1"
        case .timeout:
            env[LaunchEnvironmentKeys.mockNetworkError] = "timeout"
        case .success:
            break
        case .http400, .http401, .http403, .http404, .http429, .http500:
            let statusCode: Int
            switch scenario {
            case .http400: statusCode = 400
            case .http401: statusCode = 401
            case .http403: statusCode = 403
            case .http404: statusCode = 404
            case .http429: statusCode = 429
            case .http500: statusCode = 500
            default: statusCode = 500
            }
            env[LaunchEnvironmentKeys.mockChatError] = """
            {"error":"Scenario \(scenario.rawValue)","status_code":\(statusCode)}
            """
        }

        return env
    }

    /// Sets up network error mock
    static func setupNetworkError() -> [String: String] {
        return setupScenario(.offline)
    }

    /// Sets up API error mock
    static func setupAPIError(statusCode: Int = 500, message: String = "Server error") -> [String: String] {
        let mapped: MockScenarioID?
        switch statusCode {
        case 400: mapped = .http400
        case 401: mapped = .http401
        case 403: mapped = .http403
        case 404: mapped = .http404
        case 429: mapped = .http429
        case 500: mapped = .http500
        default: mapped = nil
        }

        if let mapped {
            return setupScenario(mapped)
        }

        let error = """
        {"error":"\(message)","status_code":\(statusCode)}
        """
        return [
            LaunchEnvironmentKeys.mockChatError: error,
            LaunchEnvironmentKeys.mockDelay: "0.1"
        ]
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

    /// Builds SSE-like streaming events as JSON for MockURLProtocol to replay.
    /// Each entry supports an optional "delay" (seconds) and an event payload.
    static func buildChatStreamEvents(
        answer: String,
        threadId: String,
        thinking: String,
        baseDelay: Double = 0.2
    ) -> String {
        let midpoint = max(1, answer.count / 2)
        let splitIndex = answer.index(answer.startIndex, offsetBy: midpoint)
        let firstChunk = String(answer[..<splitIndex])
        let secondChunk = String(answer[splitIndex...])

        let events: [[String: Any]] = [
            [
                "delay": baseDelay,
                "type": "metadata",
                "thread_id": threadId
            ],
            [
                "delay": baseDelay,
                "type": "thinking",
                "content": thinking
            ],
            [
                "delay": baseDelay,
                "type": "chunk",
                "content": firstChunk
            ],
            [
                "delay": baseDelay,
                "type": "chunk",
                "content": secondChunk
            ],
            [
                "delay": baseDelay,
                "type": "done",
                "full_answer": answer
            ]
        ]

        let data = try? JSONSerialization.data(withJSONObject: events, options: [])
        return String(data: data ?? Data(), encoding: .utf8) ?? "[]"
    }

    /// Loads a JSON fixture from the UI test bundle.
    static func loadFixture(named name: String) -> String? {
        let bundle = Bundle(for: NetworkMockHelper.self)
        if let url = bundle.url(forResource: name, withExtension: "json") {
            do {
                return try String(contentsOf: url, encoding: .utf8)
            } catch {
                print("NetworkMockHelper: Failed to load fixture \(name).json from bundle: \(error)")
                return nil
            }
        }

        let helperURL = URL(fileURLWithPath: #filePath)
        let fixturesURL = helperURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("\(name).json")

        do {
            return try String(contentsOf: fixturesURL, encoding: .utf8)
        } catch {
            print("NetworkMockHelper: Missing fixture \(name).json (bundle + filesystem lookup failed): \(error)")
            return nil
        }
    }
}
