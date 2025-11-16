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
}
