//
//  AppCoordinatorDeepLinkTests.swift
//  shamelagptTests
//
//  Created by automated change on 22/12/2025.
//

import XCTest
@testable import ShamelaGPT

@MainActor
final class AppCoordinatorDeepLinkTests: XCTestCase {

    func makeCoordinator(userDefaultsSuite: String = #file) -> (AppCoordinator, ChatSessionState) {
        let suiteName = "test_\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        let sessionManager = SessionManager(defaults: userDefaults)
        let sessionState = ChatSessionState(sessionManager: sessionManager, userDefaults: userDefaults)
        let coordinator = AppCoordinator(userDefaults: userDefaults, chatSessionState: sessionState, shouldShowWelcome: false)
        return (coordinator, sessionState)
    }

    func testHandleUniversalLinkWithConversationId_opensConversation() {
        let (coordinator, sessionState) = makeCoordinator()
        let id = "96f1024d-5432-44c2-be3b-d23681152a2c"
        let url = URL(string: "https://shamelagpt.com/chat?id=\(id)")!

        let handled = coordinator.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sessionState.conversationId, id)
        XCTAssertEqual(coordinator.selectedTab, 0)
        XCTAssertEqual(coordinator.navigationRoutes.last, .chat(conversationId: id))
    }

    func testHandleUniversalLinkWithoutId_startsNewConversation() {
        let (coordinator, sessionState) = makeCoordinator()
        let url = URL(string: "https://shamelagpt.com/chat")!

        let handled = coordinator.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertNil(sessionState.conversationId)
        XCTAssertEqual(coordinator.navigationRoutes.last, .chat(conversationId: nil))
    }

    func testHandleUniversalLinkWWWHost_opensConversation() {
        let (coordinator, sessionState) = makeCoordinator()
        let id = "abc-123"
        let url = URL(string: "https://www.shamelagpt.com/chat?id=\(id)")!

        let handled = coordinator.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sessionState.conversationId, id)
        XCTAssertEqual(coordinator.navigationRoutes.last, .chat(conversationId: id))
    }

    /// Swaps the shared container's ChatRepository for the duration of a test.
    /// `/shared` routing asks the repository whether the conversation is owned
    /// locally, so the test has to control that answer.
    private func withStubbedChatRepository(
        owning conversations: [Conversation],
        _ body: (MockChatRepository) async throws -> Void
    ) async rethrows {
        let previous = DependencyContainer.shared.resolve(ChatRepository.self)
        let mock = MockChatRepository()
        mock.mockConversations = conversations
        DependencyContainer.shared.register(ChatRepository.self, instance: mock as ChatRepository)
        defer {
            if let previous {
                DependencyContainer.shared.register(ChatRepository.self, instance: previous)
            }
        }
        try await body(mock)
    }

    func testHandleUniversalLinkSharedPath_opensConversationWhenOwned() async throws {
        let (coordinator, sessionState) = makeCoordinator()
        let id = "f1e2d3c4-5678-90ab-cdef-1234567890ab"
        let url = URL(string: "https://shamelagpt.com/shared?chatid=\(id)")!
        let owned = Conversation(id: id, title: "Owned", messages: [])

        try await withStubbedChatRepository(owning: [owned]) { _ in
            let handled = coordinator.handleDeepLink(url)
            XCTAssertTrue(handled, "The link is handled even though routing resolves asynchronously")

            // Ownership is resolved in a Task; give it a turn to finish.
            try await Task.sleep(nanoseconds: 200_000_000)

            XCTAssertEqual(sessionState.conversationId, id)
            XCTAssertEqual(coordinator.navigationRoutes.last, .chat(conversationId: id))
        }
    }

    func testHandleUniversalLinkSharedPath_doesNotOpenInAppWhenNotOwned() async throws {
        let (coordinator, sessionState) = makeCoordinator()
        let id = "not-mine-1234"
        let url = URL(string: "https://shamelagpt.com/shared?chatid=\(id)")!

        try await withStubbedChatRepository(owning: []) { _ in
            let handled = coordinator.handleDeepLink(url)
            XCTAssertTrue(handled)

            try await Task.sleep(nanoseconds: 200_000_000)

            // Non-owners are handed to Safari instead of the authenticated ChatView.
            XCTAssertNil(sessionState.conversationId)
            XCTAssertTrue(coordinator.navigationRoutes.isEmpty)
        }
    }

    func testHandleUniversalLinkLegacySharedPathSegment_isHandled() async throws {
        let (coordinator, sessionState) = makeCoordinator()
        let id = "legacy-1234-5678"
        // The shape the backend used to emit; those links are already in the wild.
        let url = URL(string: "https://shamelagpt.com/shared/\(id)")!
        let owned = Conversation(id: id, title: "Owned", messages: [])

        try await withStubbedChatRepository(owning: [owned]) { _ in
            let handled = coordinator.handleDeepLink(url)
            XCTAssertTrue(handled)

            try await Task.sleep(nanoseconds: 200_000_000)

            XCTAssertEqual(sessionState.conversationId, id)
        }
    }
}
