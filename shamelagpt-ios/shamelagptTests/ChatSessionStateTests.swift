//
//  ChatSessionStateTests.swift
//  ShamelaGPTTests
//
//  Created by Codex on 18/12/2025.
//

import XCTest
@testable import ShamelaGPT

@MainActor
final class ChatSessionStateTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        suiteName = "ChatSessionStateTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDownWithError() throws {
        if let suiteName {
            userDefaults?.removePersistentDomain(forName: suiteName)
        }
        userDefaults = nil
        suiteName = nil
    }

    func testSetExistingRegeneratesViewKeyByDefault() {
        let sessionManager = SessionManager(defaults: userDefaults)
        let state = ChatSessionState(sessionManager: sessionManager, userDefaults: userDefaults)
        let initialKey = state.viewKey

        state.set(.existing(id: "abc-123"))

        XCTAssertEqual(state.conversationId, "abc-123")
        XCTAssertNotEqual(state.viewKey, initialKey, "View key should refresh when not preserving identity")
    }

    func testSetExistingCanPreserveViewKey() {
        let sessionManager = SessionManager(defaults: userDefaults)
        let state = ChatSessionState(sessionManager: sessionManager, userDefaults: userDefaults)
        let initialKey = state.viewKey

        state.set(.existing(id: "conv-1"), preserveViewKey: true)

        XCTAssertEqual(state.conversationId, "conv-1")
        XCTAssertEqual(state.viewKey, initialKey, "Preserving view key should keep the active ChatViewModel alive")
    }
}
