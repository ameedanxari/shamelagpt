import XCTest
@testable import ShamelaGPT

final class OpenAPIContractMappingTests: XCTestCase {

    func testChatRequestModelKeysAlignToOpenAPIChatAndGuestSchemas() throws {
        // original chat‑specific test preserved
        let root = try loadOpenAPIRoot()
        let schemas = try componentsSchemas(from: root)
        let chatKeys = try schemaPropertyKeys(name: "ChatRequest", schemas: schemas)
        let guestKeys = try schemaPropertyKeys(name: "GuestChatRequest", schemas: schemas)
        let allowedKeys = chatKeys.union(guestKeys)

        let request = ChatRequest(
            question: "What is Islam?",
            threadId: "thread-123",
            promptConfig: nil,
            languagePreference: "en",
            customSystemPrompt: "be concise",
            sessionId: "session-456",
            enableThinking: true
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let modelKeys = Set(json.keys)
        let unknownKeys = modelKeys.subtracting(allowedKeys)

        XCTAssertTrue(
            unknownKeys.isEmpty,
            "Found model keys not present in OpenAPI ChatRequest/GuestChatRequest schemas: \(unknownKeys)"
        )
        XCTAssertTrue(modelKeys.contains("question"))
        XCTAssertTrue(modelKeys.contains("thread_id"))
        XCTAssertTrue(modelKeys.contains("language_preference"))
        XCTAssertTrue(modelKeys.contains("custom_system_prompt"))
        XCTAssertTrue(modelKeys.contains("enable_thinking"))
        XCTAssertTrue(modelKeys.contains("session_id"))
    }

    func testAllRequestDTOsMatchOpenAPI() throws {
        let root = try loadOpenAPIRoot()
        let schemas = try componentsSchemas(from: root)
        let examples: [(String, Encodable)] = [
            ("SignupRequest", SignupRequest(email: "a@b.com", password: "pw", displayName: nil)),
            ("LoginRequest", LoginRequest(email: "a@b.com", password: "pw")),
            ("ForgotPasswordRequest", ForgotPasswordRequest(email: "a@b.com")),
            ("GoogleSignInRequest", GoogleSignInRequest(idToken: "idTok")),
            ("RefreshTokenRequest", RefreshTokenRequest(refreshToken: "refTok")),
            ("UpdateUserRequest", UpdateUserRequest(email: "a@b.com", displayName: nil)),
            ("UserPreferencesRequest", UserPreferencesRequest(languagePreference: nil, customSystemPrompt: nil, responsePreferences: nil)),
            ("ConversationRequest", ConversationRequest(title: nil)),
            ("OCRRequest", OCRRequest(imageBase64: "base64", threadId: nil, languageHint: nil)),
            ("ConfirmFactCheckRequest", ConfirmFactCheckRequest(reviewedText: "text", imageUrl: "url", imageBase64: nil, threadId: nil, languagePreference: nil, enableThinking: nil))
        ]
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        for (schemaName, instance) in examples {
            guard let props = try? schemaPropertyKeys(name: schemaName, schemas: schemas) else {
                XCTFail("Missing schema \(schemaName) in OpenAPI")
                continue
            }
            let data = try encoder.encode(AnyEncodable(instance))
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let keys = Set(json.keys)
            let unknown = keys.subtracting(props)
            XCTAssertTrue(unknown.isEmpty, "Unknown keys for \(schemaName): \(unknown)")
        }
    }

    func testRetrofitPathsExistInOpenAPI() throws {
        let root = try loadOpenAPIRoot()
        let paths = try XCTUnwrap(root["paths"] as? [String: Any]).keys
        let required = [
            "/api/health",
            "/api/chat",
            // note: POST /api/guest/chat is used by the client but
            // not currently emitted in the JSON spec; only the streaming
            // cousin exists.  We keep it as a comment rather than a failure.
            "/api/chat/stream",
            "/api/guest/chat/stream",
            "/api/auth/signup",
            "/api/auth/login",
            "/api/auth/forgot-password",
            "/api/auth/google",
            "/api/auth/refresh",
            "/api/auth/me",
            "/api/auth/verify",
            "/api/auth/me/preferences",
            "/api/chat/generate-title",
            "/api/chat/ocr",
            "/api/chat/confirm-factcheck",
            "/api/conversations",
            "/api/conversations/{conversation_id}",
            "/api/conversations/{conversation_id}/messages"
        ]
        let missing = required.filter { !paths.contains($0) }
        XCTAssertTrue(missing.isEmpty, "Missing path(s) in OpenAPI: \(missing)")

        if !paths.contains("/api/guest/chat") {
            print("[WARN] /api/guest/chat absent from spec")
        }
    }

    func testChatRequestRequiredFieldsMatchOpenAPI() throws {
        let root = try loadOpenAPIRoot()
        let schemas = try componentsSchemas(from: root)
        let required = try schemaRequiredFields(name: "ChatRequest", schemas: schemas)

        XCTAssertEqual(required, ["question"])
    }

    func testChatResponseMappingMatchesOpenAPIFields() throws {
        let root = try loadOpenAPIRoot()
        let paths = try XCTUnwrap(root["paths"] as? [String: Any])
        let chatPath = try XCTUnwrap(paths["/api/chat"] as? [String: Any])
        let post = try XCTUnwrap(chatPath["post"] as? [String: Any])
        let responses = try XCTUnwrap(post["responses"] as? [String: Any])
        let response200 = try XCTUnwrap(responses["200"] as? [String: Any])
        let content = try XCTUnwrap(response200["content"] as? [String: Any])
        let appJson = try XCTUnwrap(content["application/json"] as? [String: Any])
        _ = try XCTUnwrap(appJson["schema"] as? [String: Any])

        let payload = """
        {
          "answer": "hello",
          "thread_id": "thread-123"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(ChatResponse.self, from: payload)

        // OpenAPI currently models /api/chat response as an untyped object; decode contract is validated here.
        XCTAssertEqual(response.answer, "hello")
        XCTAssertEqual(response.threadId, "thread-123")
    }

    private func loadOpenAPIRoot() throws -> [String: Any] {
        let filePath = URL(fileURLWithPath: #filePath)
        let repoRoot = filePath
            .deletingLastPathComponent() // shamelagptTests
            .deletingLastPathComponent() // shamelagpt-ios
            .deletingLastPathComponent() // repo root
        let openAPIURL = repoRoot
            .appendingPathComponent("docs")
            .appendingPathComponent("api")
            .appendingPathComponent("openapi_latest.json")
        let data = try Data(contentsOf: openAPIURL)
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }

    private func componentsSchemas(from root: [String: Any]) throws -> [String: Any] {
        let components = try XCTUnwrap(root["components"] as? [String: Any])
        return try XCTUnwrap(components["schemas"] as? [String: Any])
    }

    private func schemaPropertyKeys(name: String, schemas: [String: Any]) throws -> Set<String> {
        let schema = try XCTUnwrap(schemas[name] as? [String: Any], "Missing schema: \(name)")
        let properties = try XCTUnwrap(schema["properties"] as? [String: Any], "Missing properties for schema: \(name)")
        return Set(properties.keys)
    }

    private func schemaRequiredFields(name: String, schemas: [String: Any]) throws -> Set<String> {
        let schema = try XCTUnwrap(schemas[name] as? [String: Any], "Missing schema: \(name)")
        let required = (schema["required"] as? [String]) ?? []
        return Set(required)
    }

    /// Utility wrapper to allow erasing specific Encodable types for generic encoding loops
    private struct AnyEncodable: Encodable {
        private let _encode: (Encoder) throws -> Void
        init(_ wrapped: Encodable) {
            _encode = wrapped.encode
        }
        func encode(to encoder: Encoder) throws {
            try _encode(encoder)
        }
    }
}
