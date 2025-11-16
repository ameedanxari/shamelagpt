//
//  ChatFlowUITests.swift
//  shamelagptUITests
//
//  Consolidated chat flow UI coverage with deterministic waits.
//

import XCTest

final class ChatFlowUITests: LocalizedUITestCase {

    private let chatNetworkDelay: Double = 1.0
    private let successScenario = NetworkMockHelper.MockScenarioID.success.rawValue
    private let offlineScenario = NetworkMockHelper.MockScenarioID.offline.rawValue

    private func chatLaunchOverrides(_ extra: [String: String] = [:]) -> [String: String] {
        var overrides = extra
        overrides[NetworkMockHelper.LaunchEnvironmentKeys.mockChatStreamDelay] = String(chatNetworkDelay)
        overrides[NetworkMockHelper.LaunchEnvironmentKeys.mockDelay] = String(chatNetworkDelay)
        return overrides
    }

    private func launchWithChatMock(includeReset: Bool = true) {
        guard let mockResponse = NetworkMockHelper.loadFixture(named: "chat_success_response"),
              let streamEvents = NetworkMockHelper.loadFixture(named: "chat_success_stream") else {
            XCTFail("Missing chat success fixtures")
            return
        }

        let streamDelay = 0.5

        UITestLauncher.launch(
            app: app,
            includeReset: includeReset,
            overrides: chatLaunchOverrides([
                NetworkMockHelper.LaunchEnvironmentKeys.mockChatResponse: mockResponse,
                NetworkMockHelper.LaunchEnvironmentKeys.mockChatStreamEvents: streamEvents,
                NetworkMockHelper.LaunchEnvironmentKeys.mockChatStreamDelay: String(streamDelay)
            ])
        )
        skipWelcomeIfNeeded()
    }

    // MARK: - Debug Helpers

    private func logUIState(_ testName: String, _ step: String) {
        withDebugUI {
            print("\n=== UI DEBUG: \(testName) - \(step) ===")
            print("App state: \(app.state)")
            print("App debug description: \(app.debugDescription)")
            
            // Log all available elements
            logAllAvailableElements(testName, step)
        }
    }

    private func logAllAvailableElements(_ testName: String, _ step: String) {
        withDebugUI {
            print("\n--- Available Elements for \(testName) - \(step) ---")

            let isRunning = app.state == .runningForeground || app.state == .runningBackground
            guard isRunning else {
                print("App not running. Skipping element dump.")
                print("--- End Available Elements ---\n")
                return
            }
            
            // Log all buttons
            let buttons = app.buttons.allElementsBoundByIndex
            print("Buttons (\(buttons.count)):")
            for (index, button) in buttons.enumerated() {
                print("  [\(index)] ID: '\(button.identifier)', Label: '\(button.label)', Enabled: \(button.isEnabled), Visible: \(button.isHittable)")
            }
            
            // Log all text views
            let textViews = app.textViews.allElementsBoundByIndex
            print("Text Views (\(textViews.count)):")
            for (index, textView) in textViews.enumerated() {
                print("  [\(index)] ID: '\(textView.identifier)', Label: '\(textView.label)', Value: '\(textView.value as? String ?? "nil")', Visible: \(textView.isHittable)")
            }
            
            // Log all static texts
            let staticTexts = app.staticTexts.allElementsBoundByIndex
            print("Static Texts (\(staticTexts.count)):")
            for (index, staticText) in staticTexts.enumerated() {
                print("  [\(index)] ID: '\(staticText.identifier)', Label: '\(staticText.label)', Value: '\(staticText.value as? String ?? "nil")', Visible: \(staticText.isHittable)")
            }
            
            print("--- End Available Elements ---\n")
        }
    }

    private func logElementSearch(_ testName: String, _ step: String, _ elementType: String, _ identifier: String) {
        withDebugUI {
            print("\n--- Element Search: \(testName) - \(step) ---")
            print("Searching for \(elementType) with identifier: '\(identifier)'")
        
            switch elementType {
            case "button":
                let buttons = app.buttons.matching(identifier: identifier)
                print("Found \(buttons.count) buttons matching '\(identifier)'")
                for (index, button) in buttons.allElementsBoundByIndex.enumerated() {
                    print("  [\(index)] ID: '\(button.identifier)', Label: '\(button.label)', Enabled: \(button.isEnabled), Visible: \(button.isHittable)")
                }
                
            case "textView":
                let textViews = app.textViews.matching(identifier: identifier)
                print("Found \(textViews.count) textViews matching '\(identifier)'")
                for (index, textView) in textViews.allElementsBoundByIndex.enumerated() {
                    print("  [\(index)] ID: '\(textView.identifier)', Label: '\(textView.label)', Value: '\(textView.value as? String ?? "nil")', Visible: \(textView.isHittable)")
                }
                
            case "staticText":
                let staticTexts = app.staticTexts.matching(identifier: identifier)
                print("Found \(staticTexts.count) staticTexts matching '\(identifier)'")
                for (index, staticText) in staticTexts.allElementsBoundByIndex.enumerated() {
                    print("  [\(index)] ID: '\(staticText.identifier)', Label: '\(staticText.label)', Value: '\(staticText.value as? String ?? "nil")', Visible: \(staticText.isHittable)")
                }
                
            default:
                print("Unknown element type: \(elementType)")
            }
            
            print("--- End Element Search ---\n")
        }
    }

    private func waitForElementWithDebug(_ element: XCUIElement, timeout: TimeInterval = 10.0, testName: String = "", step: String = "") -> Bool {
        logDebugUI("\n--- Waiting for Element: \(testName) - \(step) ---")
        logDebugUI("Waiting for element: ID='\(element.identifier)', Type='\(type(of: element))'")

        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let startTime = Date()
        let waiter = XCTWaiter()
        let result = waiter.wait(for: [expectation], timeout: timeout)
        let waitTime = Date().timeIntervalSince(startTime)

        let success = (result == .completed)
        logDebugUI("Wait result: \(success) (\(result)), Time: \(String(format: "%.2f", waitTime))s")

        if !success {
            logUIState(testName, "\(step) - Element Not Found")
        }

        logDebugUI("--- End Wait ---\n")
        return success
    }

    private func typeTextWithDebug(_ text: String, into element: XCUIElement, testName: String = "", step: String = "") {
        logDebugUI("\n--- Typing Text: \(testName) - \(step) ---")
        logDebugUI("Typing '\(text)' into element: ID='\(element.identifier)', Label='\(element.label)'")
        
        let typed = UITestLauncher.safeTypeText(in: element, text: text)
        XCTAssertTrue(typed, "Failed to focus input and type text for step '\(step)'")
        
        logDebugUI("Typed text. Element value: '\(element.value as? String ?? "nil")'")
        logDebugUI("--- End Typing ---\n")
    }

    private func tapWithDebug(_ element: XCUIElement, testName: String = "", step: String = "") {
        logDebugUI("\n--- Tapping Element: \(testName) - \(step) ---")
        logDebugUI("Tapping element: ID='\(element.identifier)', Label='\(element.label)', Enabled=\(element.isEnabled), Visible=\(element.isHittable)")
        
        element.tap()
        
        logDebugUI("Tapped element")
        logDebugUI("--- End Tap ---\n")
    }

    private func waitForElementWithDebug(
        _ query: XCUIElementQuery,
        timeout: TimeInterval = 10.0,
        testName: String = "",
        step: String = ""
    ) -> XCUIElement? {
        logDebugUI("\n--- Waiting for Element: \(testName) - \(step) ---")
        logDebugUI("Waiting for element query: \(query)")

        let predicate = NSPredicate(format: "count > 0")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: query)
        let startTime = Date()
        let waiter = XCTWaiter()
        let result = waiter.wait(for: [expectation], timeout: timeout)
        let waitTime = Date().timeIntervalSince(startTime)

        let success = (result == .completed)
        logDebugUI("Wait result: \(success) (\(result)), Time: \(String(format: "%.2f", waitTime))s")

        if !success {
            logUIState(testName, "\(step) - Element Not Found")
            logDebugUI("--- End Wait ---\n")
            return nil
        }

        logDebugUI("--- End Wait ---\n")
        return query.firstMatch
    }

    func testSendMessageShowsAssistantAndSources() throws {
        launchWithChatMock()
        logUIState("testSendMessageShowsAssistantAndSources", "Start")
        navigateToChat()

        logUIState("testSendMessageShowsAssistantAndSources", "After navigateToChat")

        let textField = app.textViews[UITestID.Chat.messageInputField]
        logElementSearch("testSendMessageShowsAssistantAndSources", "Finding text input", "textView", UITestID.Chat.messageInputField)
        let textFieldFound = waitForElementWithDebug(textField, testName: "testSendMessageShowsAssistantAndSources", step: "Wait for text input")
        XCTAssertTrue(textFieldFound, "Text input should be visible")
        
        typeTextWithDebug("What is Islam?", into: textField, testName: "testSendMessageShowsAssistantAndSources", step: "Type message")
        
        let sendButton = app.buttons[UITestID.Chat.sendButton]
        logElementSearch("testSendMessageShowsAssistantAndSources", "Finding send button", "button", UITestID.Chat.sendButton)
        let sendButtonFound = waitForElementWithDebug(sendButton, testName: "testSendMessageShowsAssistantAndSources", step: "Wait for send button")
        XCTAssertTrue(sendButtonFound, "Send button should be visible")
        
        tapWithDebug(sendButton, testName: "testSendMessageShowsAssistantAndSources", step: "Tap send button")

        let typingIndicator = app.otherElements[UITestID.Chat.typingIndicator]
        let typingIndicatorFound = waitForElementWithDebug(
            typingIndicator,
            timeout: 5,
            testName: "testSendMessageShowsAssistantAndSources",
            step: "Wait for typing indicator"
        )
        XCTAssertTrue(typingIndicatorFound, "Typing indicator should appear while streaming")

        let thinkingBubble = app.otherElements[UITestID.Chat.thinkingBubble]
        let thinkingBubbleFound = waitForElementWithDebug(
            thinkingBubble,
            timeout: 5,
            testName: "testSendMessageShowsAssistantAndSources",
            step: "Wait for thinking bubble"
        )
        XCTAssertTrue(thinkingBubbleFound, "Thinking bubble should appear during stream")

        waitForElementToDisappear(thinkingBubble, timeout: 10)
    }

    func testSendEmptyMessageDisablesSendButton() throws {
        launchWithChatMock()
        logUIState("testSendEmptyMessageDisablesSendButton", "Start")
        navigateToChat()

        logUIState("testSendEmptyMessageDisablesSendButton", "After navigateToChat")

        let sendButton = app.buttons[UITestID.Chat.sendButton]
        logElementSearch("testSendEmptyMessageDisablesSendButton", "Finding send button", "button", UITestID.Chat.sendButton)
        let sendButtonFound = waitForElementWithDebug(sendButton, testName: "testSendEmptyMessageDisablesSendButton", step: "Wait for send button")
        XCTAssertTrue(sendButtonFound, "Send button should be visible")
        XCTAssertFalse(sendButton.isEnabled, "Send button should be disabled with empty input")

        let textField = app.textViews[UITestID.Chat.messageInputField]
        logElementSearch("testSendEmptyMessageDisablesSendButton", "Finding text input", "textView", UITestID.Chat.messageInputField)
        let textFieldFound = waitForElementWithDebug(textField, testName: "testSendEmptyMessageDisablesSendButton", step: "Wait for text input")
        XCTAssertTrue(textFieldFound, "Text input should be visible")
        
        typeTextWithDebug("Hello", into: textField, testName: "testSendEmptyMessageDisablesSendButton", step: "Type text")
        XCTAssertTrue(sendButton.isEnabled, "Send button should enable when text is entered")

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 5)
        textField.typeText(deleteString)
        XCTAssertFalse(sendButton.isEnabled, "Send button should disable after clearing text")
        
        logUIState("testSendEmptyMessageDisablesSendButton", "After clearing text")
    }

    func testNetworkErrorShowsRetryBanner() throws {
        UITestLauncher.launch(
            app: app,
            includeReset: true,
            overrides: chatLaunchOverrides(
                NetworkMockHelper.setupScenario(.offline)
            )
        )
        skipWelcomeIfNeeded()
        logUIState("testNetworkErrorShowsRetryBanner", "Start - Network Error Simulation")
        navigateToChat()

        logUIState("testNetworkErrorShowsRetryBanner", "After navigateToChat - Network Error Mode")

        let textField = app.textViews[UITestID.Chat.messageInputField]
        logElementSearch("testNetworkErrorShowsRetryBanner", "Finding text input", "textView", UITestID.Chat.messageInputField)
        let textFieldFound = waitForElementWithDebug(textField, testName: "testNetworkErrorShowsRetryBanner", step: "Wait for text input")
        XCTAssertTrue(textFieldFound, "Text input should be visible")
        
        typeTextWithDebug("Trigger network error", into: textField, testName: "testNetworkErrorShowsRetryBanner", step: "Type error message")

        let sendButton = app.buttons[UITestID.Chat.sendButton]
        logElementSearch("testNetworkErrorShowsRetryBanner", "Finding send button", "button", UITestID.Chat.sendButton)
        let sendButtonFound = waitForElementWithDebug(sendButton, testName: "testNetworkErrorShowsRetryBanner", step: "Wait for send button")
        XCTAssertTrue(sendButtonFound, "Send button should be visible")
        
        tapWithDebug(sendButton, testName: "testNetworkErrorShowsRetryBanner", step: "Tap send button")
        
        logUIState("testNetworkErrorShowsRetryBanner", "After sending error message")
        
        let errorBanner = app.otherElements[UITestID.Chat.errorBanner]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                errorBanner,
                timeout: 8,
                selector: UITestID.Chat.errorBanner,
                scenario: NetworkMockHelper.MockScenarioID.offline.rawValue,
                observedState: "after_send_network_error"
            ),
            "Error banner should appear"
        )

        let retryButton = app.buttons[UITestID.Chat.errorBannerRetryButton]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                retryButton,
                timeout: 5,
                selector: UITestID.Chat.errorBannerRetryButton,
                scenario: NetworkMockHelper.MockScenarioID.offline.rawValue,
                observedState: "error_banner_visible"
            ),
            "Retry button should be visible in error banner"
        )
    }

    func testOptimisticMessageRemovedAfterError() throws {
        UITestLauncher.launch(
            app: app,
            includeReset: true,
            overrides: chatLaunchOverrides(
                NetworkMockHelper.setupScenario(.offline)
            )
        )
        skipWelcomeIfNeeded()
        navigateToChat()

        let textField = app.textViews[UITestID.Chat.messageInputField]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                textField,
                selector: UITestID.Chat.messageInputField,
                scenario: offlineScenario,
                observedState: "chat_ready_offline"
            )
        )
        textField.tap()
        let testMessage = "Optimistic removal"
        textField.typeText(testMessage)

        let sendButton = app.buttons[UITestID.Chat.sendButton]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                sendButton,
                selector: UITestID.Chat.sendButton,
                scenario: offlineScenario,
                observedState: "chat_message_typed"
            )
        )
        sendButton.tap()

        let userMessage = app.staticTexts[testMessage]
        XCTAssertTrue(waitForElement(userMessage), "Optimistic message should appear")

        let retryButton = app.buttons[UITestID.Chat.errorBannerRetryButton]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                retryButton,
                timeout: 5,
                selector: UITestID.Chat.errorBannerRetryButton,
                scenario: offlineScenario,
                observedState: "error_banner_rendered"
            ),
            "Error banner should appear"
        )

        waitForElementToDisappear(userMessage, timeout: 5)
        XCTAssertTrue(app.textViews[UITestID.Chat.messageInputField].exists, "Chat input should remain available after rollback")
    }

    // MARK: - Helpers

    private func navigateToChat() {
        let messageInput = app.textViews[UITestID.Chat.messageInputField]
        if messageInput.waitForExistence(timeout: 2) {
            return
        }

        let chatTab = chatTabButton()
        if chatTab.waitForExistence(timeout: 5) {
            chatTab.tap()
        }

        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                messageInput,
                selector: UITestID.Chat.messageInputField,
                scenario: successScenario,
                observedState: "chat_tab_navigation_complete"
            )
        )
    }
}
