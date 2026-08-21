//
//  ReasoningStreamTests.swift
//  shamelagptTests
//
//  Covers the `{"type":"reasoning"}` SSE channel: the deltas are fragments of one
//  string and must be concatenated with NO separator, and the result must survive
//  the domain model and the Core Data mapper.
//

import XCTest
import CoreData
@testable import ShamelaGPT

final class ReasoningStreamTests: XCTestCase {

    // The provider streams thinking as deltas that split mid-word. This is the text
    // those deltas are cut from; every test below must rebuild it exactly.
    private let originalReasoning = "The user is asking about combining prayers while travelling. I should check all four schools before answering."

    /// Deltas deliberately broken mid-word ("trav|elling", "ans|wering") and with the
    /// separating spaces attached to a fragment, which is how the backend forwards them.
    private let deltas = [
        "The user is ",
        "asking about comb",
        "ining prayers while trav",
        "elling. I should check ",
        "all four schools before ans",
        "wering."
    ]

    // MARK: - Stream parsing

    func testReasoningDeltasConcatenateWithNoSeparator() async throws {
        // Given
        let lines = deltas.map { delta in
            "data: {\"type\":\"reasoning\",\"content\":\(jsonString(delta))}\n\n"
        }

        // When
        let events = try await collectEvents(from: lines)

        // Then
        var rebuilt = ""
        var reasoningEventCount = 0
        for event in events {
            if case .reasoning(let delta) = event {
                reasoningEventCount += 1
                rebuilt += delta
            }
        }

        XCTAssertEqual(reasoningEventCount, deltas.count, "Every reasoning delta should surface as its own event")
        XCTAssertEqual(rebuilt, originalReasoning, "Concatenating with no separator must reconstruct the original text")
    }

    func testReasoningDeltasPreserveLeadingAndTrailingWhitespace() async throws {
        // Given - the whitespace at a delta boundary is part of the text, so unlike
        // "thinking" labels the handler must not trim reasoning content.
        let lines = [
            "data: {\"type\":\"reasoning\",\"content\":\"Checking \"}\n\n",
            "data: {\"type\":\"reasoning\",\"content\":\" the sources\"}\n\n"
        ]

        // When
        let events = try await collectEvents(from: lines)

        // Then
        let rebuilt = events.reduce(into: "") { partial, event in
            if case .reasoning(let delta) = event { partial += delta }
        }
        XCTAssertEqual(rebuilt, "Checking  the sources", "Edge whitespace must survive; trimming it would corrupt the text")
    }

    func testReasoningEventIsNoLongerIgnoredAlongsideThinking() async throws {
        // Given - a realistic turn carrying both channels
        let lines = [
            "data: {\"type\":\"thinking\",\"content\":\"Planning search\"}\n\n",
            "data: {\"type\":\"reasoning\",\"content\":\"Weighing the evidence\"}\n\n",
            "data: {\"type\":\"chunk\",\"content\":\"Answer\"}\n\n",
            "data: {\"type\":\"done\",\"full_answer\":\"Answer\"}\n\n"
        ]

        // When
        let events = try await collectEvents(from: lines)

        // Then - the short label and the chain-of-thought stay in separate channels
        var thinking: [String] = []
        var reasoning: [String] = []
        for event in events {
            switch event {
            case .thinking(let text): thinking.append(text)
            case .reasoning(let text): reasoning.append(text)
            default: break
            }
        }

        XCTAssertEqual(thinking, ["Planning search"])
        XCTAssertEqual(reasoning, ["Weighing the evidence"])
    }

    func testEmptyReasoningDeltaIsDropped() async throws {
        // Given
        let lines = ["data: {\"type\":\"reasoning\",\"content\":\"\"}\n\n"]

        // When
        let events = try await collectEvents(from: lines)

        // Then
        let reasoningEvents = events.filter { if case .reasoning = $0 { return true } else { return false } }
        XCTAssertTrue(reasoningEvents.isEmpty, "An empty delta adds nothing and should not produce an event")
    }

    // MARK: - Domain model

    func testMessageWithoutReasoningReportsNoPanel() {
        let message = Message(conversationId: "c1", content: "Answer", isUserMessage: false)

        XCTAssertNil(message.reasoning)
        XCTAssertFalse(message.hasReasoning, "A nil reasoning must not render a panel")
    }

    func testMessageWithWhitespaceOnlyReasoningReportsNoPanel() {
        let message = Message(conversationId: "c1", content: "Answer", isUserMessage: false, reasoning: "   \n ")

        XCTAssertFalse(message.hasReasoning, "Whitespace-only reasoning has nothing to show")
    }

    func testMessageWithReasoningReportsPanel() {
        let message = Message(conversationId: "c1", content: "Answer", isUserMessage: false, reasoning: originalReasoning)

        XCTAssertTrue(message.hasReasoning)
        XCTAssertEqual(message.reasoning, originalReasoning)
    }

    // MARK: - Core Data mapping

    func testMapperRoundTripsNilReasoning() throws {
        // Given - a message stored before the reasoning channel existed
        let stack = TestCoreDataStack()
        let context = stack.viewContext
        let entity = MessageEntity(context: context)
        entity.id = "m1"
        entity.conversationId = "c1"
        entity.content = "Legacy answer"
        entity.isUserMessage = false
        entity.timestamp = Date()

        // When
        let message = MessageMapper.toDomainModel(entity)

        // Then
        XCTAssertNil(message.reasoning, "A row with no reasoning must map to nil, not an empty string")
        XCTAssertFalse(message.hasReasoning)
        XCTAssertEqual(message.content, "Legacy answer", "The rest of the message must be unaffected")
    }

    func testMapperRoundTripsReasoning() throws {
        // Given
        let stack = TestCoreDataStack()
        let context = stack.viewContext
        let entity = MessageEntity(context: context)
        entity.id = "m2"
        entity.conversationId = "c1"
        entity.content = "Answer"
        entity.isUserMessage = false
        entity.timestamp = Date()
        entity.reasoning = originalReasoning

        // When
        let message = MessageMapper.toDomainModel(entity)

        // Then
        XCTAssertEqual(message.reasoning, originalReasoning)
        XCTAssertTrue(message.hasReasoning)
    }

    func testRepositoryPersistsAndReloadsReasoning() async throws {
        // Given
        let stack = TestCoreDataStack()
        let repository = ChatRepositoryImpl(
            coreDataStack: stack,
            conversationDAO: ConversationDAO(),
            messageDAO: MessageDAO(),
            apiClient: nil,
            networkMonitor: nil
        )
        let conversation = try await repository.createConversation(title: "Reasoning")

        // When
        _ = try await repository.addMessage(
            toConversation: conversation.id,
            content: "Answer",
            isUserMessage: false,
            sources: [],
            reasoning: originalReasoning
        )
        // The 4-argument convenience overload must keep storing nil.
        _ = try await repository.addMessage(
            toConversation: conversation.id,
            content: "Question",
            isUserMessage: true,
            sources: []
        )

        // Then
        let reloaded = try await repository.fetchMessages(forConversation: conversation.id)
        XCTAssertEqual(reloaded.count, 2)
        XCTAssertEqual(reloaded.first(where: { !$0.isUserMessage })?.reasoning, originalReasoning)
        XCTAssertNil(reloaded.first(where: { $0.isUserMessage })?.reasoning)
    }

    // MARK: - Helpers

    private func collectEvents(from lines: [String]) async throws -> [StreamEvent] {
        let handler = StreamingMessageHandler()
        let raw = AsyncThrowingStream<String, Error> { continuation in
            for line in lines {
                continuation.yield(line)
            }
            continuation.finish()
        }

        var events: [StreamEvent] = []
        for try await event in try await handler.handleStream(raw) {
            events.append(event)
        }
        return events
    }

    /// Encodes a Swift string as a JSON string literal so the fixtures stay readable
    /// even when a delta contains characters that would need escaping.
    private func jsonString(_ value: String) -> String {
        let data = try! JSONSerialization.data(withJSONObject: [value], options: [])
        var literal = String(data: data, encoding: .utf8)!
        literal.removeFirst() // [
        literal.removeLast()  // ]
        return literal
    }
}
