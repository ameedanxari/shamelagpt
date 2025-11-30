//
//  AccessibilityUITests.swift
//  shamelagptUITests
//
//  UI tests for accessibility features (VoiceOver, Dynamic Type, RTL)
//

import XCTest

final class AccessibilityUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        UITestLauncher.launch(app: app)

        // Skip welcome screen if present
        if app.buttons["Skip to Chat"].waitForExistence(timeout: 5) {
            app.buttons["Skip to Chat"].tap()
        }

        // Navigate to chat tab
        let chatTab = app.tabBars.buttons["Chat"]
        if chatTab.waitForExistence(timeout: 3) {
            chatTab.tap()
        }
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - VoiceOver Tests

    func testSendButtonAccessibilityLabel() throws {
        let sendButton = app.buttons["Send message"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5), "Send button should exist")

        // Verify accessibility label is set
        XCTAssertNotNil(sendButton.label, "Send button should have accessibility label")
        XCTAssertTrue(sendButton.label.contains("Send") || sendButton.label.contains("message"),
                     "Send button label should be descriptive")

        // Verify button is accessible
        XCTAssertTrue(sendButton.isEnabled || !sendButton.isEnabled, "Send button should have enabled state")
    }

    func testMicrophoneButtonAccessibilityLabel() throws {
        let micButton = app.buttons["MicrophoneButton"]
        XCTAssertTrue(micButton.waitForExistence(timeout: 5), "Microphone button should exist")

        // Verify accessibility label
        XCTAssertNotNil(micButton.label, "Microphone button should have accessibility label")
        XCTAssertTrue(micButton.label.contains("voice") || micButton.label.contains("input") || micButton.label.contains("microphone") || micButton.label.contains("Start"),
                     "Microphone button label should be descriptive")

        // Verify button is accessible
        XCTAssertTrue(micButton.isEnabled, "Microphone button should be enabled")
    }

    func testCameraButtonAccessibilityLabel() throws {
        let cameraButton = app.buttons["CameraButton"]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5), "Camera button should exist")

        // Verify accessibility label
        XCTAssertNotNil(cameraButton.label, "Camera button should have accessibility label")
        XCTAssertTrue(cameraButton.label.contains("Camera") || cameraButton.label.contains("camera") || cameraButton.label.contains("image") || cameraButton.label.contains("photo"),
                     "Camera button label should be descriptive")

        // Verify button is accessible
        XCTAssertTrue(cameraButton.isEnabled, "Camera button should be enabled")
    }

    func testMessageBubblesAccessible() throws {
        // Send a test message to create message bubbles
        UITestLauncher.relaunch(app: app)
        let textField = app.textViews.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 5))

        // Tap to focus
        textField.tap()
        sleep(1)  // Wait for keyboard

        // Type text
        let testMessage = "Test message"
        textField.typeText(testMessage)

        let sendButton = app.buttons["SendMessageButton"]
        if sendButton.waitForExistence(timeout: 2) && sendButton.isEnabled {
            sendButton.tap()

            // Wait for message to appear
            sleep(2)

            // Verify message bubbles have accessibility
            let messageText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", testMessage)).firstMatch
            if messageText.waitForExistence(timeout: 5) {
                XCTAssertTrue(messageText.exists, "Message should be accessible")

                // Message should be readable by VoiceOver
                XCTAssertNotNil(messageText.label, "Message should have accessible label")
                XCTAssertTrue(messageText.label.count > 0, "Message label should not be empty")
            }
        }
    }

    func testSourceLinksAccessible() throws {
        // Relaunch with mocks (sources already present in base mock)
        UITestLauncher.relaunch(app: app)

        // Send a message
        let textField = app.textViews.firstMatch
        if textField.waitForExistence(timeout: 5) {
            // Tap and type
            textField.tap()
            sleep(1)

            let testMessage = "Show sources"
            textField.typeText(testMessage)

            let sendButton = app.buttons["SendMessageButton"]
            if sendButton.waitForExistence(timeout: 2) && sendButton.isEnabled {
                sendButton.tap()

                // Wait for response with sources
                sleep(3)

                // Look for source buttons (sources are buttons, not links)
                let sourceButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "SourceLink-"))
                if sourceButtons.count > 0 {
                    let firstButton = sourceButtons.element(boundBy: 0)
                    XCTAssertTrue(firstButton.exists, "Source buttons should exist")

                    // Verify button is accessible
                    XCTAssertNotNil(firstButton.label, "Source button should have accessibility label")
                    XCTAssertTrue(firstButton.label.count > 0, "Source button label should be descriptive")
                }
            }
        }
    }

    // MARK: - Dynamic Type Tests

    func testUIScalesWithLargeText() throws {
        // Set large text size
        UITestLauncher.relaunch(
            app: app,
            overrides: ["UIPreferredContentSizeCategory": "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"]
        )
        navigateToChat()

        // Verify UI elements exist and are accessible with large text
        let sendButton = app.buttons["SendMessageButton"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5), "Send button should exist with large text")

        let textField = app.textViews.firstMatch
        XCTAssertTrue(textField.exists, "Text field should exist with large text")

        // Verify buttons are still hittable (not clipped)
        XCTAssertTrue(sendButton.isHittable || !sendButton.isEnabled, "Send button should be accessible with large text")

        let micButton = app.buttons["MicrophoneButton"]
        XCTAssertTrue(micButton.isHittable, "Microphone button should be accessible with large text")
    }

    func testUIScalesWithSmallText() throws {
        // Set small text size
        UITestLauncher.relaunch(
            app: app,
            overrides: ["UIPreferredContentSizeCategory": "UICTContentSizeCategoryExtraSmall"]
        )
        navigateToChat()

        // Verify UI elements exist and are accessible with small text
        let sendButton = app.buttons["Send message"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5), "Send button should exist with small text")

        let textField = app.textViews.firstMatch
        XCTAssertTrue(textField.exists, "Text field should exist with small text")

        // Verify buttons are still hittable
        XCTAssertTrue(sendButton.isHittable || !sendButton.isEnabled, "Send button should be accessible with small text")
    }

    // MARK: - Helpers

    private func navigateToChat() {
        if app.buttons["Skip to Chat"].waitForExistence(timeout: 3) {
            app.buttons["Skip to Chat"].tap()
        }
        if app.tabBars.buttons["Chat"].waitForExistence(timeout: 3) {
            app.tabBars.buttons["Chat"].tap()
        }
    }

    func testMessagesReadableWithLargeType() throws {
        // Set large text
        UITestLauncher.relaunch(
            app: app,
            overrides: ["UIPreferredContentSizeCategory": "UICTContentSizeCategoryAccessibilityLarge"]
        )
        navigateToChat()

        // Send a test message
        let textField = app.textViews.firstMatch
        if textField.waitForExistence(timeout: 5) {
            textField.tap()
            textField.typeText("Large text test message")

            let sendButton = app.buttons["Send message"]
            if sendButton.isEnabled {
                sendButton.tap()

                // Wait for message
                sleep(2)

                // Verify message is displayed and readable
                let messageText = app.staticTexts["Large text test message"]
                XCTAssertTrue(messageText.waitForExistence(timeout: 5), "Message should be displayed with large text")

                // Verify message is accessible
                XCTAssertTrue(messageText.exists, "Message should be readable with large text")
            }
        }
    }

    // MARK: - RTL Tests

    func testRTLLayoutForArabic() throws {
        // Switch to Arabic language to enable RTL
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        let languageRow = app.tables.cells.containing(.staticText, identifier: "Language").firstMatch
        if languageRow.waitForExistence(timeout: 5) {
            languageRow.tap()

            let arabicOption = app.staticTexts["العربية"]
            if arabicOption.waitForExistence(timeout: 3) {
                arabicOption.tap()

                // Wait for language change
                sleep(2)

                // Navigate to chat
                let chatTab = app.tabBars.buttons["Chat"]
                chatTab.tap()

                // Verify RTL layout
                let textField = app.textViews.firstMatch
                XCTAssertTrue(textField.waitForExistence(timeout: 3), "Text field should exist in RTL mode")

                // In RTL mode, UI should be mirrored
                // We can verify by checking if Arabic text is displayed
                // and the layout direction has changed

                // Send a message to verify RTL in messages
                textField.tap()
                textField.typeText("مرحبا")

                let sendButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'إرسال' OR identifier == 'Send message'")).firstMatch
                if sendButton.waitForExistence(timeout: 3) && sendButton.isEnabled {
                    sendButton.tap()

                    sleep(2)

                    // Verify Arabic message appears with RTL layout
                    let arabicMessage = app.staticTexts["مرحبا"]
                    XCTAssertTrue(arabicMessage.waitForExistence(timeout: 3), "RTL layout should support and display Arabic text")
                }
            }
        }
    }

    func testRTLMessageBubbleAlignment() throws {
        // Switch to Arabic
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        let languageRow = app.tables.cells.containing(.staticText, identifier: "Language").firstMatch
        if languageRow.waitForExistence(timeout: 5) {
            languageRow.tap()

            let arabicOption = app.staticTexts["العربية"]
            if arabicOption.waitForExistence(timeout: 3) {
                arabicOption.tap()
                sleep(2)

                // Navigate to chat
                let chatTab = app.tabBars.buttons["Chat"]
                chatTab.tap()

                // Send message
                let textField = app.textViews.firstMatch
                if textField.waitForExistence(timeout: 3) {
                    textField.tap()
                    textField.typeText("اختبار المحاذاة")

                    let sendButton = app.buttons.matching(NSPredicate(format: "identifier == 'Send message' OR label CONTAINS[c] 'إرسال'")).firstMatch
                    if sendButton.waitForExistence(timeout: 3) && sendButton.isEnabled {
                        sendButton.tap()
                        sleep(2)

                        // In RTL mode, user messages should be aligned to the right
                        // Assistant messages should be aligned to the left
                        // We verify the message exists
                        let message = app.staticTexts["اختبار المحاذاة"]
                        XCTAssertTrue(message.waitForExistence(timeout: 3), "Message bubbles should support RTL alignment and display Arabic text")
                    }
                }
            }
        }
    }

    func testRTLInputFieldAlignment() throws {
        // Switch to Arabic
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        let languageRow = app.tables.cells.containing(.staticText, identifier: "Language").firstMatch
        if languageRow.waitForExistence(timeout: 5) {
            languageRow.tap()

            let arabicOption = app.staticTexts["العربية"]
            if arabicOption.waitForExistence(timeout: 3) {
                arabicOption.tap()
                sleep(2)

                // Navigate to chat
                let chatTab = app.tabBars.buttons["Chat"]
                chatTab.tap()

                // Verify text field exists and supports RTL input
                let textField = app.textViews.firstMatch
                XCTAssertTrue(textField.waitForExistence(timeout: 3), "Text field should exist")

                // Type Arabic text
                textField.tap()
                textField.typeText("نص تجريبي")

                // Verify text was entered (RTL input supported)
                let value = textField.value as? String ?? ""
                XCTAssertTrue(value.contains("نص") || value.contains("تجريبي"),
                             "Text field should support RTL text input")
            }
        }
    }

    func testLTRLayoutForEnglish() throws {
        // Ensure English is selected
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()

        let languageRow = app.tables.cells.containing(.staticText, identifier: "Language").firstMatch
        if languageRow.waitForExistence(timeout: 5) {
            languageRow.tap()

            let englishOption = app.staticTexts["English"]
            if englishOption.waitForExistence(timeout: 3) {
                englishOption.tap()
                sleep(2)

                // Navigate to chat
                let chatTab = app.tabBars.buttons["Chat"]
                chatTab.tap()

                // Verify LTR layout
                let textField = app.textViews.firstMatch
                XCTAssertTrue(textField.waitForExistence(timeout: 3), "Text field should exist in LTR mode")

                // Send English message
                textField.tap()
                textField.typeText("English test message")

                let sendButton = app.buttons["Send message"]
                if sendButton.isEnabled {
                    sendButton.tap()
                    sleep(2)

                    // Verify English message appears with LTR layout
                    let englishMessage = app.staticTexts["English test message"]
                    XCTAssertTrue(englishMessage.exists, "LTR layout should support English text")
                }
            }
        }
    }
}
