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
}

/// Main API client for communicating with the ShamelaGPT backend
final class APIClient: APIClientProtocol {

    // MARK: - Properties

    private let baseURL: URL
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    // MARK: - Configuration

    private struct Configuration {
        static let baseURLString = "https://api.shamelagpt.com"
        static let timeoutInterval: TimeInterval = 30.0
        static let defaultHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }

    // MARK: - Initialization

    init(
        baseURL: URL? = nil,
        session: URLSession? = nil
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
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Configuration.timeoutInterval
        configuration.timeoutIntervalForResource = Configuration.timeoutInterval * 2
        configuration.httpAdditionalHeaders = Configuration.defaultHeaders
        configuration.waitsForConnectivity = true

        self.session = session ?? URLSession(configuration: configuration)

        // Configure JSON encoder/decoder
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.keyEncodingStrategy = .convertToSnakeCase

        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
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
        let endpoint = baseURL.appendingPathComponent("api/chat")
        return try await performRequest(
            url: endpoint,
            method: "POST",
            body: request
        )
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
final class MockAPIClient: APIClientProtocol {
    var shouldFail = false
    var mockHealthResponse = HealthResponse(status: "ok", service: "shamelagpt-api")
    var mockChatResponse = ChatResponse(
        answer: "This is a mock response.\n\nSources:\n\n* **book_name:** صحيح البخاري, **source_url:** https://shamela.ws/book/1234/52",
        threadId: "mock-thread-id"
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
}
#endif
