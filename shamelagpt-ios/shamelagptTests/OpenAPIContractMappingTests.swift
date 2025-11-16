import XCTest
@testable import ShamelaGPT

final class OpenAPIContractMappingTests: XCTestCase {

    func testChatRequestModelKeysAlignToOpenAPIChatAndGuestSchemas() throws {
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
}
