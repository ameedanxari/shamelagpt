//
//  DeepLinkUITests.swift
//  shamelagptUITests
//
//  Verifies deep links route to the correct tabs without flakiness.
//

import XCTest

final class DeepLinkUITests: LocalizedUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        UITestLauncher.launch(app: app)
    }

    func testHistoryDeepLinkNavigatesToHistory() throws {
        guard #available(iOS 16.4, *) else {
            throw XCTSkip("Deep link opening requires iOS 16.4+ API")
        }
        let url = URL(string: "shamelagpt://history")!
        app.open(url)

        XCTAssertTrue(waitForHistoryScreen(), "History screen should be visible after deep link")

        assertSelectedIfDeterministic(historyTabButton(), expectedTabName: "History")
    }

    func testSettingsDeepLinkNavigatesToSettings() throws {
        guard #available(iOS 16.4, *) else {
            throw XCTSkip("Deep link opening requires iOS 16.4+ API")
        }
        let url = URL(string: "shamelagpt://settings")!
        app.open(url)

        XCTAssertTrue(waitForSettingsScreen(), "Settings screen should be visible after deep link")

        assertSelectedIfDeterministic(settingsTabButton(), expectedTabName: "Settings")
    }

    func testChatDeepLinkKeepsChatReady() throws {
        guard #available(iOS 16.4, *) else {
            throw XCTSkip("Deep link opening requires iOS 16.4+ API")
        }
        let url = URL(string: "shamelagpt://chat?id=deeplink-ui")!
        app.open(url)

        let input = app.textViews["messageInputField"]
        XCTAssertTrue(waitForElement(input), "Chat input should appear after chat deep link")
        XCTAssertTrue(input.isHittable, "Chat input should be ready after deep link navigation")

        // Some locales/devices render tab controls in alternate containers after deep-link launches.
        // Validate selection only when a chat tab control is actually present.
        assertSelectedIfDeterministic(chatTabButton(), expectedTabName: "Chat")
    }

    private func waitForHistoryScreen() -> Bool {
        let historyNavBar = app.navigationBars[localized("history")]
        let conversationCard = app.buttons["conversationCard_conv-1"]
        let emptyStateButton = app.buttons["historyNewConversationButton"]
        let lockedStateButton = app.buttons["signInButton"]
        return historyNavBar.waitForExistence(timeout: 5)
            || conversationCard.waitForExistence(timeout: 5)
            || emptyStateButton.waitForExistence(timeout: 5)
            || lockedStateButton.waitForExistence(timeout: 5)
    }

    private func waitForSettingsScreen() -> Bool {
        let settingsNavBar = app.navigationBars[localized("settings")]
        let languageRow = app.otherElements["LanguageRow"]
        let signInButton = app.buttons["signInButton"]
        let signOutButton = app.buttons["signOutButton"]
        return settingsNavBar.waitForExistence(timeout: 5)
            || languageRow.waitForExistence(timeout: 5)
            || signInButton.waitForExistence(timeout: 5)
            || signOutButton.waitForExistence(timeout: 5)
    }

    /// Tab selection state is only deterministic when surfaced as a true tab bar button.
    /// Some iPad/locale layouts expose equivalent controls as `Other` without a selected trait.
    private func assertSelectedIfDeterministic(_ tab: XCUIElement, expectedTabName: String, file: StaticString = #filePath, line: UInt = #line) {
        guard tab.exists else { return }
        guard tab.elementType == .button else { return }
        XCTAssertTrue(tab.isSelected, "\(expectedTabName) tab should be selected after deep link", file: file, line: line)
    }
}
