//
//  ConversationSyncOrderingTests.swift
//  ShamelaGPTTests
//

import XCTest
import CoreData
@testable import ShamelaGPT

/// History claims to be ordered by recency. It was not: the sync upserted each
/// conversation with the server's `updated_at` and then immediately called
/// `markAsUpdated`, which sets it to `Date()` — so after any sync every conversation
/// carried the sync time and the ordering was whatever order the loop happened to run in.
final class ConversationSyncOrderingTests: XCTestCase {

    private var testCoreDataStack: TestCoreDataStack!
    private var conversationDAO: ConversationDAO!
    private var messageDAO: MessageDAO!

    override func setUpWithError() throws {
        testCoreDataStack = TestCoreDataStack()
        conversationDAO = ConversationDAO()
        messageDAO = MessageDAO()
    }

    override func tearDownWithError() throws {
        messageDAO = nil
        conversationDAO = nil
        testCoreDataStack = nil
    }

    private func makeRepository(apiClient: APIClientProtocol) -> ChatRepositoryImpl {
        ChatRepositoryImpl(
            coreDataStack: testCoreDataStack,
            conversationDAO: conversationDAO,
            messageDAO: messageDAO,
            apiClient: apiClient,
            networkMonitor: MockNetworkMonitor(),
            freshnessStore: ConversationSyncFreshnessStore(
                userDefaults: UserDefaults(suiteName: UUID().uuidString)!
            ),
            isAuthenticated: { true }
        )
    }

    func testSyncPreservesTheServersOrderingRatherThanStampingSyncTime() async throws {
        let apiClient = MockAPIClient()
        // Deliberately supplied oldest-first, so a correct result cannot come from
        // accidentally preserving the response order.
        apiClient.mockListConversationsResponse = [
            ConversationResponse(id: "old", threadId: nil, title: "Six months ago",
                                 createdAt: "2026-02-01T10:00:00Z", updatedAt: "2026-02-01T10:00:00Z"),
            ConversationResponse(id: "recent", threadId: nil, title: "This morning",
                                 createdAt: "2026-08-22T09:00:00Z", updatedAt: "2026-08-22T09:00:00Z"),
            ConversationResponse(id: "middle", threadId: nil, title: "Last month",
                                 createdAt: "2026-07-15T10:00:00Z", updatedAt: "2026-07-15T10:00:00Z")
        ]
        let repository = makeRepository(apiClient: apiClient)

        try await repository.syncRemoteConversations(forceRefresh: true)

        let sorted = try await repository.fetchAllConversations().sorted { $0.updatedAt > $1.updatedAt }
        XCTAssertEqual(sorted.map(\.id), ["recent", "middle", "old"],
                       "History must be ordered by the server's updated_at, newest first")

        // The precise failure being guarded against: every timestamp collapsing to now.
        let distinct = Set(sorted.map { $0.updatedAt.timeIntervalSince1970.rounded() })
        XCTAssertEqual(distinct.count, 3, "each conversation must keep its own timestamp")
    }

    /// The list endpoint returns ids, titles and timestamps only. Fetching every body
    /// during the sync turned one request into one per conversation.
    func testSyncDoesNotFetchMessageBodies() async throws {
        let apiClient = MockAPIClient()
        apiClient.mockListConversationsResponse = (1...25).map { index in
            ConversationResponse(id: "c\(index)", threadId: nil, title: "Conversation \(index)",
                                 createdAt: "2026-08-01T10:00:00Z", updatedAt: "2026-08-01T10:00:00Z")
        }
        let repository = makeRepository(apiClient: apiClient)

        try await repository.syncRemoteConversations(forceRefresh: true)

        XCTAssertEqual(apiClient.getMessagesCallCount, 0,
                       "bodies load when a conversation is opened, not during the list sync")
        let conversations = try await repository.fetchAllConversations()
        XCTAssertEqual(conversations.count, 25)
    }

    /// Local activity is the case `markAsUpdated` exists for, and it must still win.
    func testAddingAMessageStillBumpsAConversationToTheTop() async throws {
        let apiClient = MockAPIClient()
        apiClient.mockListConversationsResponse = [
            ConversationResponse(id: "stale", threadId: nil, title: "Old",
                                 createdAt: "2026-02-01T10:00:00Z", updatedAt: "2026-02-01T10:00:00Z"),
            ConversationResponse(id: "newer", threadId: nil, title: "Newer",
                                 createdAt: "2026-08-01T10:00:00Z", updatedAt: "2026-08-01T10:00:00Z")
        ]
        let repository = makeRepository(apiClient: apiClient)
        try await repository.syncRemoteConversations(forceRefresh: true)

        _ = try await repository.addMessage(toConversation: "stale", content: "New question",
                                            isUserMessage: true, sources: [], reasoning: nil)

        let sorted = try await repository.fetchAllConversations().sorted { $0.updatedAt > $1.updatedAt }
        XCTAssertEqual(sorted.first?.id, "stale",
                       "a conversation the user just posted to belongs at the top")
    }

    /// An unparseable timestamp used to become `Date()`, putting that conversation above
    /// genuinely recent ones — the same shape as the `expires_in ?? 0` bug.
    func testUnparseableTimestampDoesNotJumpToTheTop() async throws {
        let apiClient = MockAPIClient()
        apiClient.mockListConversationsResponse = [
            ConversationResponse(id: "broken", threadId: nil, title: "Bad date",
                                 createdAt: "not-a-date", updatedAt: "also-not-a-date"),
            ConversationResponse(id: "recent", threadId: nil, title: "This morning",
                                 createdAt: "2026-08-22T09:00:00Z", updatedAt: "2026-08-22T09:00:00Z")
        ]
        let repository = makeRepository(apiClient: apiClient)

        try await repository.syncRemoteConversations(forceRefresh: true)

        let sorted = try await repository.fetchAllConversations().sorted { $0.updatedAt > $1.updatedAt }
        XCTAssertEqual(sorted.first?.id, "recent",
                       "a conversation with an unreadable date must not outrank a real one")
    }
}
