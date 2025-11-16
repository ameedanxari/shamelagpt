//
//  AccessibilityUITests.swift
//  shamelagptUITests
//
//  Deterministic accessibility UI tests.
//

import XCTest

final class AccessibilityUITests: LocalizedUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        launchToChat()
    }

    func testInputControlsExposeLocalizedAccessibilityLabels() throws {
        let sendButton = app.buttons[UITestID.Chat.sendButton]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5), "Send button should exist")
        XCTAssertEqual(sendButton.label, localized("chat.send"), "Send button label should match current locale")

        let micButton = app.buttons[UITestID.Chat.micButton]
        XCTAssertTrue(micButton.waitForExistence(timeout: 5), "Microphone button should exist")
        let micLabels = Set([localized("accessibility.microphoneStart"), localized("accessibility.microphoneStop")])
        XCTAssertTrue(
            micLabels.contains(micButton.label),
            "Microphone label should match current locale"
        )

        let cameraButton = app.buttons[UITestID.Chat.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5), "Camera button should exist")
        XCTAssertEqual(cameraButton.label, localized("accessibility.camera"), "Camera label should match current locale")
    }

    func testOptimisticUserMessageIsAccessible() throws {
        let message = "Accessibility check message"
        let input = app.textViews[UITestID.Chat.messageInputField]
        XCTAssertTrue(input.waitForExistence(timeout: 5), "Input field should exist")
        XCTAssertTrue(UITestLauncher.safeTypeText(in: input, text: message), "Should be able to type into chat input")

        let sendButton = app.buttons[UITestID.Chat.sendButton]
        XCTAssertTrue(sendButton.isEnabled, "Send button should be enabled after typing")
        sendButton.tap()

        let userMessage = app.staticTexts[message]
        XCTAssertTrue(userMessage.waitForExistence(timeout: 5), "Sent message should be rendered for accessibility")
        XCTAssertFalse(userMessage.label.isEmpty, "Rendered message should expose an accessibility label")
    }

    func testInputBarAccessibleAtExtremeDynamicTypeSizes() throws {
        let categories = [
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "UICTContentSizeCategoryExtraSmall"
        ]

        for category in categories {
            launchToChat(overrides: ["UIPreferredContentSizeCategory": category], includeReset: false)

            let input = app.textViews[UITestID.Chat.messageInputField]
            XCTAssertTrue(input.waitForExistence(timeout: 5), "Input should remain visible for category: \(category)")

            let micButton = app.buttons[UITestID.Chat.micButton]
            XCTAssertTrue(micButton.waitForExistence(timeout: 5), "Microphone should remain visible for category: \(category)")
            XCTAssertTrue(micButton.isHittable, "Microphone should remain tappable for category: \(category)")

            let sendButton = app.buttons[UITestID.Chat.sendButton]
            XCTAssertTrue(sendButton.waitForExistence(timeout: 5), "Send button should remain visible for category: \(category)")
        }
    }

    func testInputSupportsCurrentLocaleTextEntry() throws {
        let sample: String
        switch currentLanguage {
        case "ar":
            sample = "مرحبا"
        case "ur":
            sample = "ہیلو"
        default:
            sample = "Hello"
        }

        let input = app.textViews[UITestID.Chat.messageInputField]
        XCTAssertTrue(input.waitForExistence(timeout: 5), "Input should exist for locale test")
        XCTAssertTrue(UITestLauncher.safeTypeText(in: input, text: sample), "Should type localized text into input")

        let sendButton = app.buttons[UITestID.Chat.sendButton]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3), "Send button should exist")
        XCTAssertTrue(sendButton.isEnabled, "Typing localized text should enable sending")
    }

    private func launchToChat(overrides: [String: String] = [:], includeReset: Bool = true) {
        UITestLauncher.launch(app: app, includeReset: includeReset, overrides: overrides)
        skipWelcomeIfNeeded(navigateToChat: true)
        XCTAssertTrue(
            app.textViews[UITestID.Chat.messageInputField].waitForExistence(timeout: 6),
            "Chat input should be visible before running accessibility flow"
        )
    }
}
