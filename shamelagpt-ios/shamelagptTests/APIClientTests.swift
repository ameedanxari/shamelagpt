//
//  APIClientTests.swift
//  shamelagptTests
//
//  Created by Ameed Khalid on 05/11/2025.
//

import XCTest
@testable import ShamelaGPT

final class APIClientTests: XCTestCase {

    var sut: APIClient!
    var mockSession: URLSession!

    override func setUpWithError() throws {
        // Configure mock URLSession with custom URLProtocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)

        // Create APIClient with test base URL and mock session
        let testBaseURL = URL(string: "https://test.api.com")!
        sut = APIClient(baseURL: testBaseURL, session: mockSession)

        // Reset mock state
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.error = nil
    }

    override func tearDownWithError() throws {
        sut = nil
        mockSession = nil
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.error = nil
    }

    // MARK: - Health Check Tests

    func testHealthCheckSuccess() async throws {
        // Given
        let expectedResponse = HealthResponse(status: "ok", service: "shamelagpt-api")
        let responseData = try JSONEncoder().encode(expectedResponse)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        // When
        let response = try await sut.healthCheck()

        // Then
        XCTAssertEqual(response.status, "ok")
        XCTAssertEqual(response.service, "shamelagpt-api")
    }

    func testHealthCheckEndpoint() async throws {
        // Given
        var capturedRequest: URLRequest?
        let responseData = try JSONEncoder().encode(HealthResponse(status: "ok", service: "test"))

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        _ = try await sut.healthCheck()

        // Then
        XCTAssertNotNil(capturedRequest)
        XCTAssertTrue(capturedRequest?.url?.absoluteString.contains("/api/health") ?? false)
    }

    func testHealthCheckMethod() async throws {
        // Given
        var capturedRequest: URLRequest?
        let responseData = try JSONEncoder().encode(HealthResponse(status: "ok", service: "test"))

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        _ = try await sut.healthCheck()

        // Then
        XCTAssertEqual(capturedRequest?.httpMethod, "GET")
    }

    // MARK: - Send Message Tests

    func testSendMessageSuccess() async throws {
        // Given
        let request = ChatRequest(question: "What is Islam?", threadId: nil)
        let expectedResponse = ChatResponse(answer: "Islam is a religion", threadId: "thread-123")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(expectedResponse)

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(
                url: urlRequest.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        // When
        let response = try await sut.sendMessage(request)

        // Then
        XCTAssertEqual(response.answer, "Islam is a religion")
        XCTAssertEqual(response.threadId, "thread-123")
    }

    func testSendMessageUsesAuthEndpointWhenTokenPresent() async throws {
        // Given
        let request = ChatRequest(question: "Question", threadId: nil)
        var capturedRequest: URLRequest?
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(ChatResponse(answer: "Answer", threadId: "tid"))

        MockURLProtocol.requestHandler = { urlRequest in
            capturedRequest = urlRequest
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        let authedClient = APIClient(
            baseURL: URL(string: "https://test.api.com")!,
            session: mockSession,
            authTokenProvider: { "token-123" }
        )
        _ = try await authedClient.sendMessage(request)

        // Then
        XCTAssertEqual(capturedRequest?.url?.absoluteString, "https://test.api.com/api/chat")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-123")
    }

    func testSendMessageUsesGuestEndpointWhenNoToken() async throws {
        // Given
        let request = ChatRequest(question: "Question", threadId: nil)
        var capturedRequest: URLRequest?
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(ChatResponse(answer: "Answer", threadId: "tid"))

        MockURLProtocol.requestHandler = { urlRequest in
            capturedRequest = urlRequest
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        _ = try await sut.sendMessage(request)

        // Then
        XCTAssertEqual(capturedRequest?.url?.absoluteString, "https://test.api.com/api/guest/chat")
        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"))
    }

    func testSendMessageEndpoint() async throws {
        // Given
        var capturedRequest: URLRequest?
        let request = ChatRequest(question: "Test", threadId: nil)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(ChatResponse(answer: "Response", threadId: nil))

        MockURLProtocol.requestHandler = { urlRequest in
            capturedRequest = urlRequest
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        _ = try await sut.sendMessage(request)

        // Then
        XCTAssertNotNil(capturedRequest)
        XCTAssertEqual(capturedRequest?.url?.absoluteString, "https://test.api.com/api/guest/chat")
        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"))
    }

    func testSendMessageMethod() async throws {
        // Given
        var capturedRequest: URLRequest?
        let request = ChatRequest(question: "Test", threadId: nil)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(ChatResponse(answer: "Response", threadId: nil))

        MockURLProtocol.requestHandler = { urlRequest in
            capturedRequest = urlRequest
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        _ = try await sut.sendMessage(request)

        // Then
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
    }

    func testSendMessageRequestBodySerialization() async throws {
        // Given
        var capturedRequestBody: Data?
        let request = ChatRequest(question: "What is Islam?", threadId: "thread-456")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(ChatResponse(answer: "Response", threadId: nil))

        MockURLProtocol.requestHandler = { urlRequest in
            if let body = urlRequest.httpBody {
                capturedRequestBody = body
            } else if let stream = urlRequest.httpBodyStream {
                stream.open()
                let bufferSize = 1024
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { buffer.deallocate() }
                var data = Data()
                while true {
                    let read = stream.read(buffer, maxLength: bufferSize)
                    if read > 0 {
                        data.append(buffer, count: read)
                    } else {
                        break
                    }
                }
                stream.close()
                capturedRequestBody = data
            }
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        _ = try await sut.sendMessage(request)

        // Then
        XCTAssertNotNil(capturedRequestBody, "Request body should not be nil")
        guard let requestBody = capturedRequestBody else { return }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decodedRequest = try decoder.decode(ChatRequest.self, from: requestBody)
        XCTAssertEqual(decodedRequest.question, "What is Islam?")
        XCTAssertEqual(decodedRequest.threadId, "thread-456")
    }

    func testSendMessageWithThreadId() async throws {
        // Given
        let threadId = "existing-thread-789"
        let request = ChatRequest(question: "Follow-up question", threadId: threadId)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(ChatResponse(answer: "Response", threadId: threadId))

        var capturedRequestBody: Data?
        MockURLProtocol.requestHandler = { urlRequest in
            if let body = urlRequest.httpBody {
                capturedRequestBody = body
            } else if let stream = urlRequest.httpBodyStream {
                stream.open()
                let bufferSize = 1024
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { buffer.deallocate() }
                var data = Data()
                while true {
                    let read = stream.read(buffer, maxLength: bufferSize)
                    if read > 0 {
                        data.append(buffer, count: read)
                    } else {
                        break
                    }
                }
                stream.close()
                capturedRequestBody = data
            }
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        let response = try await sut.sendMessage(request)

        // Then
        XCTAssertNotNil(capturedRequestBody)
        guard let requestBody = capturedRequestBody else { return }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decodedRequest = try decoder.decode(ChatRequest.self, from: requestBody)
        XCTAssertEqual(decodedRequest.threadId, threadId)
        XCTAssertEqual(response.threadId, threadId)
    }

    func testSendMessageWithoutThreadId() async throws {
        // Given
        let request = ChatRequest(question: "First message", threadId: nil)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(ChatResponse(answer: "Response", threadId: nil))

        var capturedRequestBody: Data?
        MockURLProtocol.requestHandler = { urlRequest in
            if let body = urlRequest.httpBody {
                capturedRequestBody = body
            } else if let stream = urlRequest.httpBodyStream {
                stream.open()
                let bufferSize = 1024
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { buffer.deallocate() }
                var data = Data()
                while true {
                    let read = stream.read(buffer, maxLength: bufferSize)
                    if read > 0 {
                        data.append(buffer, count: read)
                    } else {
                        break
                    }
                }
                stream.close()
                capturedRequestBody = data
            }
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        _ = try await sut.sendMessage(request)

        // Then
        XCTAssertNotNil(capturedRequestBody)
        guard let requestBody = capturedRequestBody else { return }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decodedRequest = try decoder.decode(ChatRequest.self, from: requestBody)
        XCTAssertNil(decodedRequest.threadId)
    }

    func testSendMessageReturnsThreadId() async throws {
        // Given
        let newThreadId = "new-thread-999"
        let request = ChatRequest(question: "Question", threadId: nil)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(ChatResponse(answer: "Answer", threadId: newThreadId))

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        let response = try await sut.sendMessage(request)

        // Then
        XCTAssertEqual(response.threadId, newThreadId)
    }

    func testSendMessageWithLongQuestion() async throws {
        // Given
        let longQuestion = String(repeating: "a", count: 5000)
        let request = ChatRequest(question: longQuestion, threadId: nil)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(ChatResponse(answer: "Response", threadId: nil))

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        let response = try await sut.sendMessage(request)

        // Then
        XCTAssertNotNil(response)
    }

    // MARK: - Network Error Tests

    func testSendMessageNoConnection() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)
        MockURLProtocol.error = URLError(.notConnectedToInternet)

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw NetworkError.noConnection")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.noConnection)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMessageTimeout() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)
        MockURLProtocol.error = URLError(.timedOut)

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw NetworkError.timeout")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.timeout)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMessageInvalidURL() async throws {
        // Given - this is hard to trigger since we use URL, but we can test the error mapping
        let request = ChatRequest(question: "Test", threadId: nil)
        MockURLProtocol.error = URLError(.badURL)

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw NetworkError.invalidURL")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.invalidURL)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMessageBadServerResponse() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)
        MockURLProtocol.error = URLError(.badServerResponse)

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw NetworkError.invalidResponse")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.invalidResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - HTTP Error Tests

    func testSendMessage400Error() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw HTTP error")
        } catch let error as NetworkError {
            if case .httpError(let statusCode) = error {
                XCTAssertEqual(statusCode, 400)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMessage401Error() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw HTTP error")
        } catch let error as NetworkError {
            if case .httpError(let statusCode) = error {
                XCTAssertEqual(statusCode, 401)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMessage403Error() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw HTTP error")
        } catch let error as NetworkError {
            if case .httpError(let statusCode) = error {
                XCTAssertEqual(statusCode, 403)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMessage429Error() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw HTTP error")
        } catch let error as NetworkError {
            if case .httpError(let statusCode) = error {
                XCTAssertEqual(statusCode, 429)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMessage422ValidationError() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 422, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw HTTP error")
        } catch let error as NetworkError {
            if case .httpError(let statusCode) = error {
                XCTAssertEqual(statusCode, 422)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMessage404Error() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw HTTP error")
        } catch let error as NetworkError {
            if case .httpError(let statusCode) = error {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMessage500Error() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw HTTP error")
        } catch let error as NetworkError {
            if case .httpError(let statusCode) = error {
                XCTAssertEqual(statusCode, 500)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMessage503Error() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw HTTP error")
        } catch let error as NetworkError {
            if case .httpError(let statusCode) = error {
                XCTAssertEqual(statusCode, 503)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Encoding/Decoding Tests

    func testRequestEncodingSnakeCaseCorrect() async throws {
        // Given
        var capturedRequestBody: Data?
        let request = ChatRequest(question: "Test", threadId: "thread-123")

        // Mock response MUST include thread_id per API spec
        // ✅ CORRECT: API always returns thread_id (never nil)
        let mockResponse = ChatResponse(answer: "Response", threadId: "thread_456")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(mockResponse)

        MockURLProtocol.requestHandler = { urlRequest in
            if let body = urlRequest.httpBody {
                capturedRequestBody = body
            } else if let stream = urlRequest.httpBodyStream {
                stream.open()
                let bufferSize = 1024
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { buffer.deallocate() }
                var data = Data()
                while true {
                    let read = stream.read(buffer, maxLength: bufferSize)
                    if read > 0 {
                        data.append(buffer, count: read)
                    } else {
                        break
                    }
                }
                stream.close()
                capturedRequestBody = data
            }
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        _ = try await sut.sendMessage(request)

        // Then
        XCTAssertNotNil(capturedRequestBody, "Request body should be captured by MockURLProtocol")
        guard let requestBody = capturedRequestBody else {
            XCTFail("Failed to capture request body")
            return
        }

        let jsonObject = try JSONSerialization.jsonObject(with: requestBody, options: []) as? [String: Any]
        XCTAssertNotNil(jsonObject, "Request body should be valid JSON")
        XCTAssertNotNil(jsonObject?["thread_id"], "Request should use snake_case thread_id, not camelCase threadId")
        XCTAssertEqual(jsonObject?["thread_id"] as? String, "thread-123", "Thread ID value should match")
        XCTAssertEqual(jsonObject?["question"] as? String, "Test", "Question should be included")
    }

    func testResponseDecodingSnakeCaseCorrect() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)
        let jsonString = """
        {
            "answer": "Response text",
            "thread_id": "thread-456"
        }
        """
        let responseData = jsonString.data(using: .utf8)!

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        let response = try await sut.sendMessage(request)

        // Then
        XCTAssertEqual(response.threadId, "thread-456") // Should decode from thread_id
    }

    func testSendMessageWithSpecialCharacters() async throws {
        // Given
        let specialText = "Test with émojis 🌟 and spëcial çhars"
        let request = ChatRequest(question: specialText, threadId: nil)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let responseData = try encoder.encode(ChatResponse(answer: "Response", threadId: nil))

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        let response = try await sut.sendMessage(request)

        // Then
        XCTAssertNotNil(response)
    }

    func testDecodingErrorHandled() async throws {
        // Given
        let request = ChatRequest(question: "Test", threadId: nil)
        let invalidJSON = "{ invalid json }".data(using: .utf8)!

        MockURLProtocol.requestHandler = { urlRequest in
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, invalidJSON)
        }

        // When/Then
        do {
            _ = try await sut.sendMessage(request)
            XCTFail("Should throw decoding error")
        } catch let error as NetworkError {
            if case .decodingError = error {
                // Success
            } else {
                XCTFail("Expected decodingError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testOCRDecodesSnakeCaseResponse() async throws {
        // Given
        let request = OCRRequest(
            imageBase64: "ZmFrZQ==",
            threadId: "thread-123",
            languageHint: "ur"
        )
        let responseJSON = """
        {
          "extracted_text": "Sample extracted text",
          "image_url": "uploads/2026/02/22/sample.png",
          "image_url_presigned": "https://example.com/sample.png",
          "metadata": {
            "success": true,
            "image_size": [1280, 720],
            "detected_language": "Mixed",
            "confidence": "high",
            "text_length": 21
          }
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { urlRequest in
            XCTAssertEqual(urlRequest.httpMethod, "POST")
            XCTAssertEqual(urlRequest.url?.absoluteString, "https://test.api.com/api/chat/ocr")

            let response = HTTPURLResponse(
                url: urlRequest.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseJSON)
        }

        // When
        let response = try await sut.ocr(request)

        // Then
        XCTAssertEqual(response.extractedText, "Sample extracted text")
        XCTAssertEqual(response.imageUrl, "uploads/2026/02/22/sample.png")
        XCTAssertEqual(response.metadata.success, true)
        XCTAssertEqual(response.metadata.detectedLanguage, "Mixed")
        XCTAssertEqual(response.metadata.textLength, 21)
    }

    // MARK: - Mock Client Test

    func testMockClientSendMessageSuccess() async throws {
        // Given - Use the mock API client from TestMocks
        let mockClient = MockAPIClient()
        mockClient.shouldFail = false
        mockClient.mockChatResponse = ChatResponse(
            answer: "Mock response from test client",
            threadId: "mock-thread-id"
        )

        let request = ChatRequest(
            question: "Test question",
            threadId: nil
        )

        // When
        let response = try await mockClient.sendMessage(request)

        // Then
        XCTAssertEqual(response.answer, "Mock response from test client")
        XCTAssertEqual(response.threadId, "mock-thread-id")
        XCTAssertEqual(mockClient.sendMessageCallCount, 1)
        XCTAssertEqual(mockClient.lastSendMessageRequest?.question, "Test question")
    }
}

// MARK: - Mock URLProtocol

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var error: Error?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let error = MockURLProtocol.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol: No request handler set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // Nothing to do
    }
}
