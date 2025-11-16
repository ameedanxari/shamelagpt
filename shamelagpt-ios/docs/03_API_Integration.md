# iOS API Integration Document - ShamelaGPT

## Version: 1.0
## Date: 2025-11-02
## API Base URL: https://api.shamelagpt.com

---

## Table of Contents
1. [API Overview](#api-overview)
2. [API Testing Results](#api-testing-results)
3. [Endpoint Documentation](#endpoint-documentation)
4. [Request/Response Models](#requestresponse-models)
5. [Error Handling](#error-handling)
6. [Networking Implementation](#networking-implementation)
7. [Offline Support](#offline-support)
8. [Rate Limiting](#rate-limiting)
9. [Security Considerations](#security-considerations)

---

## 1. API Overview

### Base URL
```
https://api.shamelagpt.com
```

### API Type
- **RESTful HTTP API**
- **Content-Type**: `application/json`
- **Response Format**: JSON

### Authentication
- ⚠️ **No authentication required** (as of API testing on 2025-11-02)
- **Phase 1**: Anonymous usage with optional `user_id` parameter
- **Future**: JWT or OAuth 2.0 authentication expected for Phase 2

### API Documentation
- **ReDoc**: https://api.shamelagpt.com/redoc
- **Swagger UI**: https://api.shamelagpt.com/docs
- **OpenAPI Spec**: https://api.shamelagpt.com/openapi.json

---

## 2. API Testing Results

### Testing Date: 2025-11-02

| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| `/api/health` | GET | ✅ **WORKING** | Returns service status |
| `/api/chat` | POST | ✅ **WORKING** | Returns answer + thread_id |
| `/api/chat` (with thread_id) | POST | ✅ **WORKING** | Conversation continuation works |
| `/api/conversations` | POST | ❌ **NOT WORKING** | Returns "Internal Server Error" |
| `/api/conversations` | GET | ❌ **NOT WORKING** | Returns "Internal Server Error" |
| `/api/conversations` | DELETE | ⚠️ **NOT TESTED** | - |
| `/api/conversations/{id}` | DELETE | ❌ **NOT WORKING** | Returns "Internal Server Error" |
| `/api/conversations/{id}/messages` | GET | ❌ **NOT WORKING** | Returns "Internal Server Error" |

### Key Findings

#### ✅ Working Features
1. **Health Check**: API is responsive
2. **Basic Chat**: Can send questions and receive answers
3. **Conversation Continuation**: Using `thread_id` returned from previous responses works correctly

#### ❌ Broken Features
1. **Conversation Management**: All conversation CRUD endpoints return 500 errors
2. **Message Retrieval**: Cannot fetch messages for a conversation
3. **User-specific queries**: `user_id` parameter causes errors

#### 📝 Implications for iOS App

**Phase 1 Strategy**:
- ✅ Use `/api/chat` endpoint only
- ✅ Manage conversations **locally** in Core Data
- ✅ Generate `thread_id` by extracting from chat responses
- ✅ Store all messages locally
- ⚠️ **No server-side conversation sync** until API is fixed

**Future Phase Strategy** (when API is fixed):
- Sync conversations to server
- Fetch conversation history from server
- Multi-device sync

---

## 3. Endpoint Documentation

### 3.1 Health Check

#### `GET /api/health`

**Description**: Check API service status

**Request**:
```http
GET /api/health HTTP/1.1
Host: api.shamelagpt.com
```

**Response**:
```json
{
  "status": "ok",
  "service": "shamela-llm"
}
```

**Status Codes**:
- `200 OK`: Service is healthy

**iOS Implementation**:
```swift
struct HealthResponse: Codable {
    let status: String
    let service: String
}

func checkHealth() -> AnyPublisher<HealthResponse, Error> {
    let url = URL(string: "\(baseURL)/api/health")!
    return URLSession.shared.dataTaskPublisher(for: url)
        .map(\.data)
        .decode(type: HealthResponse.self, decoder: JSONDecoder())
        .eraseToAnyPublisher()
}
```

---

### 3.2 Send Message (Chat)

#### `POST /api/chat`

**Description**: Send a question and receive an AI-generated answer

**Request**:
```http
POST /api/chat HTTP/1.1
Host: api.shamelagpt.com
Content-Type: application/json

{
  "question": "What is Islam?",
  "thread_id": "a0525c8b-2e52-4d82-9d41-9e6e3ad34541"  // Optional
}
```

**Request Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `question` | string | ✅ Yes | User's question/message |
| `thread_id` | string | ❌ No | Conversation thread identifier (returned from previous response) |
| `user_id` | string | ❌ No | User identifier (⚠️ causes errors currently) |
| `prompt_config` | string/object | ❌ No | Custom prompt configuration |

**Response**:
```json
{
  "answer": "Here's a comprehensive answer...\n\n# What is Islam?\n\n...",
  "thread_id": "a0525c8b-2e52-4d82-9d41-9e6e3ad34541"
}
```

**Response Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `answer` | string | AI-generated response with markdown formatting |
| `thread_id` | string | Conversation identifier (UUID format) |

**Status Codes**:
- `200 OK`: Success
- `400 Bad Request`: Invalid request body
- `500 Internal Server Error`: Server error

**Example cURL**:
```bash
curl 'https://api.shamelagpt.com/api/chat' \
  -H 'Content-Type: application/json' \
  --data-raw '{"question":"What is Islam?"}'
```

**iOS Implementation**:
```swift
struct ChatRequest: Codable {
    let question: String
    let threadId: String?

    enum CodingKeys: String, CodingKey {
        case question
        case threadId = "thread_id"
    }
}

struct ChatResponse: Codable {
    let answer: String
    let threadId: String

    enum CodingKeys: String, CodingKey {
        case answer
        case threadId = "thread_id"
    }
}

func sendMessage(question: String, threadId: String? = nil) -> AnyPublisher<ChatResponse, Error> {
    let url = URL(string: "\(baseURL)/api/chat")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let requestBody = ChatRequest(question: question, threadId: threadId)
    request.httpBody = try? JSONEncoder().encode(requestBody)

    return URLSession.shared.dataTaskPublisher(for: request)
        .map(\.data)
        .decode(type: ChatResponse.self, decoder: JSONDecoder())
        .eraseToAnyPublisher()
}
```

---

### 3.3 Create Conversation (⚠️ Not Working)

#### `POST /api/conversations`

**Status**: ❌ **Returns 500 Internal Server Error**

**Expected Request**:
```json
{
  "user_id": "user_123"
}
```

**Expected Response**:
```json
{
  "conversation_id": "conv_abc123",
  "title": "New Conversation",
  "created_at": "2025-11-02T10:00:00Z"
}
```

**iOS Workaround**:
Create conversations locally in Core Data instead.

---

### 3.4 List Conversations (⚠️ Not Working)

#### `GET /api/conversations?user_id={user_id}`

**Status**: ❌ **Returns 500 Internal Server Error**

**iOS Workaround**:
Fetch conversations from Core Data.

---

### 3.5 Delete Conversation (⚠️ Not Working)

#### `DELETE /api/conversations/{conversation_id}`

**Status**: ❌ **Returns 500 Internal Server Error**

**iOS Workaround**:
Delete conversations from Core Data only.

---

### 3.6 Get Conversation Messages (⚠️ Not Working)

#### `GET /api/conversations/{conversation_id}/messages`

**Status**: ❌ **Returns 500 Internal Server Error**

**iOS Workaround**:
Fetch messages from Core Data.

---

## 4. Request/Response Models

### Data Models

```swift
// MARK: - Request Models

struct ChatRequest: Codable {
    let question: String
    let threadId: String?
    let userId: String?
    let promptConfig: String?

    enum CodingKeys: String, CodingKey {
        case question
        case threadId = "thread_id"
        case userId = "user_id"
        case promptConfig = "prompt_config"
    }
}

// MARK: - Response Models

struct ChatResponse: Codable {
    let answer: String
    let threadId: String

    enum CodingKeys: String, CodingKey {
        case answer
        case threadId = "thread_id"
    }
}

struct HealthResponse: Codable {
    let status: String
    let service: String
}

// MARK: - Domain Models (extracted from response)

struct Message: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUserMessage: Bool
    let timestamp: Date
    let sources: [Source]?
}

struct Source: Codable {
    let bookName: String
    let sourceURL: String

    enum CodingKeys: String, CodingKey {
        case bookName = "book_name"
        case sourceURL = "source_url"
    }
}

struct Conversation: Identifiable, Codable {
    let id: UUID
    let threadId: String?
    let title: String
    let createdAt: Date
    let updatedAt: Date
    var messages: [Message]
}
```

### Response Parsing

The `answer` field contains markdown-formatted text with source citations at the end. Sources follow this pattern:

```markdown
# Answer Content

## Section

Content...

Sources:

* **book_name:** Book Title, **source_url:** https://shamela.ws/book/12345/67
* **book_name:** Another Book, **source_url:** https://shamela.ws/book/67890/12
```

**Parsing Strategy**:
1. Split response on "Sources:" or "المصادر:"
2. Extract content (before sources)
3. Parse source lines using regex or string parsing
4. Create `Source` objects

```swift
extension ChatResponse {
    func parseAnswer() -> (content: String, sources: [Source]) {
        let components = answer.components(separatedBy: "Sources:")
        let content = components.first ?? answer

        guard components.count > 1 else {
            return (content, [])
        }

        let sourcesText = components[1]
        let sources = parseSources(from: sourcesText)

        return (content, sources)
    }

    private func parseSources(from text: String) -> [Source] {
        // Regex pattern: *   **book_name:** Title, **source_url:** URL
        let pattern = #"\*\*book_name:\*\*\s*([^,]+),\s*\*\*source_url:\*\*\s*(https?://[^\s]+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))

        return matches.compactMap { match in
            guard match.numberOfRanges == 3 else { return nil }

            let bookName = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
            let sourceURL = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)

            return Source(bookName: bookName, sourceURL: sourceURL)
        }
    }
}
```

---

## 5. Error Handling

### Network Errors

```swift
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case noConnection
    case timeout
    case serverError(message: String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Please check your internet connection and try again."
        case .timeout:
            return "The request took too long. Please try again."
        case .httpError(let statusCode) where statusCode >= 500:
            return "The server is experiencing issues. Please try again later."
        case .httpError(let statusCode) where statusCode == 404:
            return "The requested resource was not found."
        default:
            return "Please try again."
        }
    }
}
```

### Error Response Model

```swift
struct ErrorResponse: Codable {
    let detail: String?
    let message: String?
    let error: String?

    var errorMessage: String {
        detail ?? message ?? error ?? "Unknown error occurred"
    }
}
```

### Retry Logic

```swift
extension Publisher {
    func retryWithDelay(
        retries: Int = 3,
        delay: TimeInterval = 2.0
    ) -> AnyPublisher<Output, Failure> {
        self.catch { error -> AnyPublisher<Output, Failure> in
            if retries > 0 {
                return Just(())
                    .delay(for: .seconds(delay), scheduler: DispatchQueue.global())
                    .flatMap { _ in
                        self.retryWithDelay(retries: retries - 1, delay: delay)
                    }
                    .eraseToAnyPublisher()
            } else {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
}

// Usage
apiClient.sendMessage(question: "What is Islam?")
    .retryWithDelay(retries: 3, delay: 2.0)
    .sink(...)
    .store(in: &cancellables)
```

---

## 6. Networking Implementation

### API Client

```swift
protocol APIClientProtocol {
    func sendMessage(question: String, threadId: String?) -> AnyPublisher<ChatResponse, Error>
    func checkHealth() -> AnyPublisher<HealthResponse, Error>
}

final class APIClient: APIClientProtocol {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = URL(string: "https://api.shamelagpt.com")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func sendMessage(question: String, threadId: String? = nil) -> AnyPublisher<ChatResponse, Error> {
        let endpoint = ChatEndpoint.sendMessage(question: question, threadId: threadId)
        return request(endpoint: endpoint, responseType: ChatResponse.self)
    }

    func checkHealth() -> AnyPublisher<HealthResponse, Error> {
        let endpoint = HealthEndpoint.check
        return request(endpoint: endpoint, responseType: HealthResponse.self)
    }

    private func request<T: Decodable>(
        endpoint: Endpoint,
        responseType: T.Type
    ) -> AnyPublisher<T, Error> {
        guard let request = buildRequest(for: endpoint) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                // Check for HTTP errors
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Try to parse error response
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.serverError(message: errorResponse.errorMessage)
                    }
                    throw NetworkError.httpError(statusCode: httpResponse.statusCode)
                }

                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                }
                if let decodingError = error as? DecodingError {
                    return NetworkError.decodingError(decodingError)
                }
                return NetworkError.unknown(error)
            }
            .eraseToAnyPublisher()
    }

    private func buildRequest(for endpoint: Endpoint) -> URLRequest? {
        guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = 30

        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add custom headers
        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Set body
        if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        return request
    }
}
```

### Endpoint Definitions

```swift
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: [String: Any]? { get }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum ChatEndpoint: Endpoint {
    case sendMessage(question: String, threadId: String?)

    var path: String {
        switch self {
        case .sendMessage:
            return "/api/chat"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .sendMessage:
            return .post
        }
    }

    var headers: [String: String] {
        return [:]
    }

    var body: [String: Any]? {
        switch self {
        case .sendMessage(let question, let threadId):
            var params: [String: Any] = ["question": question]
            if let threadId = threadId {
                params["thread_id"] = threadId
            }
            return params
        }
    }
}

enum HealthEndpoint: Endpoint {
    case check

    var path: String { "/api/health" }
    var method: HTTPMethod { .get }
    var headers: [String: String] { [:] }
    var body: [String: Any]? { nil }
}
```

---

## 7. Offline Support

### Strategy: Local-First Architecture

Since conversation management endpoints are not working, the app will use a **local-first** approach:

1. **All data stored locally** in Core Data
2. **API calls for chat only**
3. **Optimistic UI updates**
4. **Offline queue** for pending messages

### Implementation

```swift
final class ChatRepository {
    private let apiClient: APIClientProtocol
    private let localDataSource: ChatLocalDataSource

    func sendMessage(question: String, conversationId: UUID, threadId: String?) -> AnyPublisher<Message, Error> {
        // 1. Save user message locally first (optimistic update)
        let userMessage = Message(
            id: UUID(),
            content: question,
            isUserMessage: true,
            timestamp: Date(),
            sources: nil
        )

        return localDataSource.saveMessage(userMessage, conversationId: conversationId)
            .flatMap { [weak self] _ -> AnyPublisher<ChatResponse, Error> in
                guard let self = self else {
                    return Fail(error: RepositoryError.unknown).eraseToAnyPublisher()
                }

                // 2. Call API
                return self.apiClient.sendMessage(question: question, threadId: threadId)
            }
            .flatMap { [weak self] response -> AnyPublisher<Message, Error> in
                guard let self = self else {
                    return Fail(error: RepositoryError.unknown).eraseToAnyPublisher()
                }

                // 3. Parse response
                let (content, sources) = response.parseAnswer()

                // 4. Create AI message
                let aiMessage = Message(
                    id: UUID(),
                    content: content,
                    isUserMessage: false,
                    timestamp: Date(),
                    sources: sources
                )

                // 5. Save AI message locally
                return self.localDataSource.saveMessage(aiMessage, conversationId: conversationId)
                    .flatMap { _ in
                        // 6. Update conversation thread_id
                        self.localDataSource.updateConversationThreadId(conversationId: conversationId, threadId: response.threadId)
                    }
                    .map { aiMessage }
                    .eraseToAnyPublisher()
            }
            .catch { [weak self] error -> AnyPublisher<Message, Error> in
                // Handle offline scenario
                if let networkError = error as? NetworkError, networkError == .noConnection {
                    // Mark message as pending sync
                    self?.localDataSource.markMessageAsPending(userMessage.id)
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
```

### Network Reachability

```swift
import Network

final class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)

    @Published var isConnected: Bool = true
    @Published var connectionType: NWInterface.InterfaceType?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

// Usage in View
@EnvironmentObject var networkMonitor: NetworkMonitor

var body: some View {
    VStack {
        if !networkMonitor.isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                Text("No internet connection")
            }
            .padding()
            .background(Color.orange)
        }

        // Rest of the view
    }
}
```

---

## 8. Rate Limiting

### Current Status
⚠️ **No rate limiting information** in API documentation

### Recommended Client-Side Rate Limiting

Implement conservative rate limiting to avoid overwhelming the server:

```swift
final class RateLimiter {
    private var lastRequestTime: Date?
    private let minimumInterval: TimeInterval = 1.0 // 1 second between requests

    func canMakeRequest() -> Bool {
        guard let lastTime = lastRequestTime else {
            lastRequestTime = Date()
            return true
        }

        let elapsed = Date().timeIntervalSince(lastTime)
        if elapsed >= minimumInterval {
            lastRequestTime = Date()
            return true
        }

        return false
    }

    func timeUntilNextRequest() -> TimeInterval {
        guard let lastTime = lastRequestTime else { return 0 }
        let elapsed = Date().timeIntervalSince(lastTime)
        return max(0, minimumInterval - elapsed)
    }
}

// Usage in ViewModel
private let rateLimiter = RateLimiter()

func sendMessage() {
    guard rateLimiter.canMakeRequest() else {
        let waitTime = rateLimiter.timeUntilNextRequest()
        showError("Please wait \(Int(ceil(waitTime))) seconds before sending another message.")
        return
    }

    // Proceed with API call
}
```

### Exponential Backoff for Retries

```swift
class ExponentialBackoff {
    private var attempt: Int = 0
    private let baseDelay: TimeInterval = 1.0
    private let maxDelay: TimeInterval = 60.0

    func nextDelay() -> TimeInterval {
        let delay = min(baseDelay * pow(2.0, Double(attempt)), maxDelay)
        attempt += 1
        return delay
    }

    func reset() {
        attempt = 0
    }
}
```

---

## 9. Security Considerations

### 9.1 HTTPS Only
- All API calls use HTTPS
- Enforce SSL/TLS certificate validation

```swift
// URLSession configuration
let configuration = URLSessionConfiguration.default
configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
let session = URLSession(configuration: configuration)
```

### 9.2 Certificate Pinning (Optional, for Production)

```swift
class PinnedURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Add certificate pinning logic here
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}
```

### 9.3 Input Validation

```swift
func validateQuestion(_ question: String) -> Result<String, ValidationError> {
    let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmed.isEmpty else {
        return .failure(.empty)
    }

    guard trimmed.count <= 1000 else {
        return .failure(.tooLong)
    }

    return .success(trimmed)
}
```

### 9.4 Secure Storage

```swift
import Security

class KeychainManager {
    static func save(key: String, value: String) -> Bool {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
```

---

## Conclusion

The ShamelaGPT API provides basic chat functionality, but conversation management endpoints are currently not working. The iOS app will adopt a **local-first** architecture, storing all data in Core Data and only using the `/api/chat` endpoint for AI responses.

### Key Takeaways:
1. ✅ Use `/api/chat` for sending questions and receiving answers
2. ✅ Store all conversations and messages locally in Core Data
3. ✅ Extract `thread_id` from responses for conversation continuation
4. ⚠️ Do not rely on server-side conversation management
5. ⚠️ Implement client-side rate limiting
6. ✅ Handle offline scenarios gracefully
7. ✅ Parse sources from markdown responses

When the API conversation endpoints are fixed in the future, the app can be updated to sync with the server while maintaining backward compatibility with local data.
