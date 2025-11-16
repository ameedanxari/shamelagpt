//
//  HistoryUITests.swift
//  shamelagptUITests
//
//  UI tests for conversation history functionality
//

import XCTest

final class HistoryUITests: LocalizedUITestCase {
    private let scenario = NetworkMockHelper.MockScenarioID.success.rawValue

    private let baseOverrides = [
        NetworkMockHelper.LaunchEnvironmentKeys.skipWelcome: "1",
        NetworkMockHelper.LaunchEnvironmentKeys.mockDelay: "0.05"
    ]

    private let mockHistory = """
    [
        {
            "id": "conv-1",
            "title": "Signs of the Day of Judgment",
            "updated_at": 1705000000000,
            "messages": [
                {"id": "m1", "content": "What are the major signs of the Day of Judgment?", "is_user_message": true},
                {"id": "m2", "content": "The major signs include the appearance of the Dajjal...", "is_user_message": false}
            ]
        },
        {
            "id": "conv-2",
            "title": "How to perform Wudu",
            "updated_at": 1704000000000,
            "messages": [
                {"id": "m3", "content": "Can you explain the steps of Wudu?", "is_user_message": true},
                {"id": "m4", "content": "Wudu consists of washing the hands, mouth, nose, face...", "is_user_message": false}
            ]
        }
    ]
    """

    // MARK: - Helper Methods

    private func launchWithHistory(_ historyJSON: String) {
        UITestLauncher.launch(
            app: app,
            includeReset: true,
            overrides: baseOverrides.merging(
                [NetworkMockHelper.LaunchEnvironmentKeys.mockHistory: historyJSON],
                uniquingKeysWith: { $1 }
            )
        )
    }

    private func openHistory(with historyJSON: String) {
        launchWithHistory(historyJSON)
        navigateToHistory()
        waitForHistoryLoaded()
    }

    private func conversationButton() -> XCUIElement {
        app.buttons[UITestID.History.conversationCard("conv-1")]
    }

    private func conversationContainer() -> XCUIElement {
        let cell = app.cells.containing(NSPredicate(format: "identifier == %@", UITestID.History.conversationCard("conv-1"))).firstMatch
        return cell.exists ? cell : conversationButton()
    }

    private func navigateToHistory() {
        let historyTab = historyTabButton()
        XCTAssertTrue(waitForElement(historyTab))
        historyTab.tap()
        let historyNavBar = app.navigationBars[localized("history")]
        _ = waitForElement(historyNavBar)
    }

    private func waitForHistoryLoaded() {
        let conversationCard = app.buttons[UITestID.History.conversationCard("conv-1")]
        let emptyStateButton = app.buttons[UITestID.History.newConversationButton]
        let lockedStateButton = app.buttons[UITestID.Auth.signInButton]
        let loaded = conversationCard.waitForExistence(timeout: 3)
            || emptyStateButton.waitForExistence(timeout: 5)
            || lockedStateButton.waitForExistence(timeout: 5)
        XCTAssertTrue(loaded, "History view should load")
    }

    // MARK: - Conversation List Tests

    func testHistoryListAndTapConversationNavigatesToChat() throws {
        openHistory(with: mockHistory)

        let historyNavBar = app.navigationBars[localized("history")]
        XCTAssertTrue(historyNavBar.waitForExistence(timeout: 5), "History navigation bar should appear")

        let conversationElement = conversationButton()
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                conversationElement,
                selector: UITestID.History.conversationCard("conv-1"),
                scenario: scenario,
                observedState: "history_loaded_with_conversations"
            ),
            "Should show conversations if any exist"
        )
        conversationElement.tap()

        let textField = app.textViews[UITestID.Chat.messageInputField]
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 3) || backButton.exists,
                     "Should navigate to chat view")
    }

    func testHistoryShowsEmptyStateWhenNoConversations() throws {
        openHistory(with: "[]")

        let emptyStateButton = app.buttons[UITestID.History.newConversationButton]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                emptyStateButton,
                selector: UITestID.History.newConversationButton,
                scenario: scenario,
                observedState: "history_empty_state"
            ),
            "Empty state should show new conversation button"
        )
    }

    // MARK: - New Conversation Tests

    func testNewConversationStartsEmpty() throws {
        openHistory(with: mockHistory)

        let newChatButton = app.buttons[UITestID.History.newChatButton]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                newChatButton,
                selector: UITestID.History.newChatButton,
                scenario: scenario,
                observedState: "history_loaded_with_conversations"
            )
        )
        newChatButton.tap()

        let textField = app.textViews[UITestID.Chat.messageInputField]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                textField,
                timeout: 3,
                selector: UITestID.Chat.messageInputField,
                scenario: scenario,
                observedState: "history_new_chat_opened"
            ),
            "Chat input should be available"
        )

        let messageBubbles = app.otherElements.matching(identifier: UITestID.Chat.messageBubble)
        XCTAssertEqual(messageBubbles.count, 0, "New conversation should start empty")
    }

    // MARK: - Delete Tests

    func testSwipeActionsShareAndDeleteFlow() throws {
        openHistory(with: mockHistory)

        var conversationElement = conversationButton()
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                conversationElement,
                selector: UITestID.History.conversationCard("conv-1"),
                scenario: scenario,
                observedState: "history_loaded_with_conversations"
            ),
            "Conversation should exist for swipe actions"
        )

        let actions = revealSwipeActions(for: conversationContainer())
        XCTAssertTrue(actions.delete.waitForExistence(timeout: 1), "Delete button should appear after swipe")
        XCTAssertTrue(actions.share.waitForExistence(timeout: 1), "Share button should appear after swipe")

        actions.share.tap()
        let shareSheet = app.sheets.firstMatch
        let activityView = app.otherElements[UITestID.History.activityListView]
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 5) || activityView.exists, "Share sheet should appear")

        let dismissed = dismissShareSheetIfNeeded()
        if !dismissed {
            openHistory(with: mockHistory)
            conversationElement = conversationButton()
            XCTAssertTrue(conversationElement.waitForExistence(timeout: 5), "Conversation should still be available after relaunch")
        }

        var deleteActions = revealSwipeActions(for: conversationContainer())
        XCTAssertTrue(deleteActions.delete.waitForExistence(timeout: 3), "Delete action should be available")
        deleteActions.delete.tap()

        let confirmationAlert = app.alerts.firstMatch
        XCTAssertTrue(confirmationAlert.waitForExistence(timeout: 3), "Delete confirmation should appear")

        let cancelPredicate = NSPredicate(format: "label CONTAINS[c] %@", localized("common.cancel"))
        let cancelAlertButton = confirmationAlert.buttons.matching(cancelPredicate).firstMatch
        XCTAssertTrue(cancelAlertButton.exists, "Cancel button should exist in confirmation alert")
        cancelAlertButton.tap()
        XCTAssertTrue(conversationElement.exists, "Cancelled conversation should still exist")

        deleteActions = revealSwipeActions(for: conversationContainer())
        XCTAssertTrue(deleteActions.delete.waitForExistence(timeout: 3), "Delete action should be available")
        deleteActions.delete.tap()

        let confirmAlert = app.alerts.firstMatch
        XCTAssertTrue(confirmAlert.waitForExistence(timeout: 3), "Delete confirmation should appear again")

        let confirmPredicate = NSPredicate(format: "label CONTAINS[c] %@", localized("common.delete"))
        let confirmButton = confirmAlert.buttons.matching(confirmPredicate).firstMatch
        XCTAssertTrue(confirmButton.exists, "Confirm delete button should exist")
        confirmButton.tap()

        let emptyState = app.buttons[UITestID.History.newConversationButton]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 3) || !conversationElement.exists,
                     "Conversation should be removed from list")
    }

    func testDeleteAllConversationsWorks() throws {
        openHistory(with: mockHistory)

        let deleteAllButton = app.buttons[UITestID.History.clearAllButton]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                deleteAllButton,
                timeout: 3,
                selector: UITestID.History.clearAllButton,
                scenario: scenario,
                observedState: "history_loaded_with_conversations"
            ),
            "Delete all button should exist in History view"
        )
        deleteAllButton.tap()

        let confirmationAlert = app.alerts.firstMatch
        XCTAssertTrue(confirmationAlert.waitForExistence(timeout: 3), "Confirmation alert should appear for delete all")

        let clearAllLabel = localized("history.clearAll")
        let confirmButton = confirmationAlert.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", clearAllLabel)).firstMatch
        XCTAssertTrue(confirmButton.exists, "Confirm button should exist in alert")
        confirmButton.tap()

        let emptyState = app.buttons[UITestID.History.newConversationButton]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                emptyState,
                timeout: 3,
                selector: UITestID.History.newConversationButton,
                scenario: scenario,
                observedState: "history_cleared_all"
            ),
            "Empty state should be shown after deleting all conversations"
        )
    }

    // MARK: - Swipe Helpers

    private func revealSwipeActions(for element: XCUIElement) -> (delete: XCUIElement, share: XCUIElement) {
        let deleteIdentifier = UITestID.History.deleteConversationButton
        let shareIdentifier = UITestID.History.shareConversationButton
        let deleteLabel = localized("common.delete")
        let shareLabel = localized("common.share")
        let deletePredicate = NSPredicate(format: "identifier == %@ OR label CONTAINS[c] %@", deleteIdentifier, deleteLabel)
        let sharePredicate = NSPredicate(format: "identifier == %@ OR label CONTAINS[c] %@", shareIdentifier, shareLabel)

        performSwipe(on: element)
        var deleteButton = app.buttons.matching(deletePredicate).firstMatch
        var shareButton = app.buttons.matching(sharePredicate).firstMatch
        if deleteButton.waitForExistence(timeout: 1) || shareButton.waitForExistence(timeout: 1) {
            return (deleteButton, shareButton)
        }

        performSwipe(on: element)
        deleteButton = app.buttons.matching(deletePredicate).firstMatch
        shareButton = app.buttons.matching(sharePredicate).firstMatch
        if deleteButton.waitForExistence(timeout: 1) || shareButton.waitForExistence(timeout: 1) {
            return (deleteButton, shareButton)
        }

        performDragSwipe(on: element)
        deleteButton = app.buttons.matching(deletePredicate).firstMatch
        shareButton = app.buttons.matching(sharePredicate).firstMatch
        _ = deleteButton.waitForExistence(timeout: 1)
        _ = shareButton.waitForExistence(timeout: 1)
        return (deleteButton, shareButton)
    }

    private func dismissShareSheetIfNeeded() -> Bool {
        guard let sheetElement = currentShareSheetElement() else { return true }

        let candidateLabels = [
            localized("common.cancel"),
            "Cancel",
            "Close",
            "Done",
            "OK"
        ]

        for label in candidateLabels {
            let button = app.buttons[label]
            if button.exists {
                button.tap()
                return didElementDisappear(sheetElement, timeout: 3)
            }
        }

        if sheetElement.exists {
            sheetElement.swipeDown()
            if didElementDisappear(sheetElement, timeout: 3) {
                return true
            }
        }

        app.swipeDown()
        if didElementDisappear(sheetElement, timeout: 2) {
            return true
        }

        let topTap = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02))
        topTap.tap()
        return didElementDisappear(sheetElement, timeout: 2)
    }

    private func currentShareSheetElement() -> XCUIElement? {
        let sheet = app.sheets.firstMatch
        if sheet.exists {
            return sheet
        }
        let activityView = app.otherElements[UITestID.History.activityListView]
        if activityView.exists {
            return activityView
        }
        return nil
    }

    private func didElementDisappear(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        if !element.exists {
            return true
        }
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func performSwipe(on element: XCUIElement) {
        if isRTLLanguage {
            element.swipeRight()
        } else {
            element.swipeLeft()
        }
    }

    private func performDragSwipe(on element: XCUIElement) {
        let startX: CGFloat = isRTLLanguage ? 0.05 : 0.95
        let endX: CGFloat = isRTLLanguage ? 0.95 : 0.05
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: startX, dy: 0.5))
        let end = element.coordinate(withNormalizedOffset: CGVector(dx: endX, dy: 0.5))
        start.press(forDuration: 0.2, thenDragTo: end)
    }

    private var isRTLLanguage: Bool {
        switch currentLanguage.lowercased() {
        case "ar", "ur":
            return true
        default:
            return false
        }
    }
}
