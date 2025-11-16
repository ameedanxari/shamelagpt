//
//  VoiceInputUITests.swift
//  shamelagptUITests
//
//  Deterministic UI tests for voice input functionality.
//

import XCTest

final class VoiceInputUITests: LocalizedUITestCase {

    private var okLabel: String { localized("common.ok") }
    private var micStartLabel: String { localized("accessibility.microphoneStart") }
    private var micStopLabel: String { localized("accessibility.microphoneStop") }

    override func setUpWithError() throws {
        try super.setUpWithError()
        launchToChat()
    }

    func testMicrophoneButtonVisibleAndAccessible() throws {
        let micButton = app.buttons[UITestID.Chat.micButton]
        XCTAssertTrue(micButton.waitForExistence(timeout: 5), "Microphone button should be visible")
        XCTAssertTrue(micButton.isHittable, "Microphone button should be tappable")
        XCTAssertTrue(
            micButton.label == micStartLabel || micButton.label == micStopLabel,
            "Microphone button should expose localized label for current locale"
        )
    }

    func testPermissionDeniedShowsVoiceErrorAlert() throws {
        relaunchToChat(overrides: ["SIMULATE_SPEECH_PERMISSION_DENIED": "true"])

        let micButton = app.buttons[UITestID.Chat.micButton]
        XCTAssertTrue(micButton.waitForExistence(timeout: 5))
        micButton.tap()

        assertVoiceErrorAlertVisible()
    }

    func testSimulatedTranscriptionFillsInput() throws {
        let transcript = "Hello voice transcription"
        relaunchToChat(
            overrides: [
                "SIMULATE_SPEECH_PERMISSION_GRANTED": "true",
                "SIMULATE_SPEECH_TRANSCRIPTION": transcript
            ]
        )

        let micButton = app.buttons[UITestID.Chat.micButton]
        XCTAssertTrue(micButton.waitForExistence(timeout: 5))
        micButton.tap()

        let input = app.textViews[UITestID.Chat.messageInputField]
        XCTAssertTrue(input.waitForExistence(timeout: 3), "Message input should exist")
        let value = input.value as? String ?? ""
        XCTAssertTrue(value.contains(transcript), "Simulated transcription should be written to input")
    }

    func testSimulatedRecordingStartAndStopFlow() throws {
        relaunchToChat(
            overrides: [
                "SIMULATE_SPEECH_PERMISSION_GRANTED": "true",
                "SIMULATE_SPEECH_TRANSCRIPTION": "recording test",
                "SIMULATE_SPEECH_AUTO_STOP": "false"
            ]
        )

        let micButton = app.buttons[UITestID.Chat.micButton]
        XCTAssertTrue(micButton.waitForExistence(timeout: 5))

        micButton.tap()
        XCTAssertEqual(micButton.label, micStopLabel, "Microphone label should switch to localized stop state")

        micButton.tap()
        XCTAssertEqual(micButton.label, micStartLabel, "Microphone label should switch back to localized start state")
    }

    func testRecognitionErrorScenariosShowAlert() throws {
        let scenarios: [[String: String]] = [
            [
                "SIMULATE_SPEECH_PERMISSION_GRANTED": "true",
                "SIMULATE_SPEECH_LANGUAGE_UNAVAILABLE": "true"
            ],
            [
                "SIMULATE_SPEECH_PERMISSION_GRANTED": "true",
                "SIMULATE_SPEECH_ERROR": "true"
            ]
        ]

        for scenario in scenarios {
            relaunchToChat(overrides: scenario)
            let micButton = app.buttons[UITestID.Chat.micButton]
            XCTAssertTrue(micButton.waitForExistence(timeout: 5))
            micButton.tap()
            assertVoiceErrorAlertVisible()
        }
    }

    private func launchToChat(overrides: [String: String] = [:], includeReset: Bool = true) {
        UITestLauncher.launch(app: app, includeReset: includeReset, overrides: overrides)
        skipWelcomeIfNeeded(navigateToChat: true)
        XCTAssertTrue(
            app.textViews[UITestID.Chat.messageInputField].waitForExistence(timeout: 6),
            "Chat input should be visible before running voice flow"
        )
    }

    private func relaunchToChat(overrides: [String: String]) {
        launchToChat(overrides: overrides)
    }

    private func assertVoiceErrorAlertVisible(file: StaticString = #filePath, line: UInt = #line) {
        let alert = app.alerts.firstMatch
        let errorText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'permission denied' OR label CONTAINS[c] 'recognizer' OR label CONTAINS[c] 'recognition failed'")
        ).firstMatch

        let alertVisible = alert.waitForExistence(timeout: 5) || errorText.waitForExistence(timeout: 5)
        XCTAssertTrue(alertVisible, "Voice error alert should be displayed", file: file, line: line)

        let scopedOkButton = alert.buttons[okLabel]
        let globalOkButton = app.buttons[okLabel]
        let okButton: XCUIElement
        if scopedOkButton.exists {
            okButton = scopedOkButton
        } else if globalOkButton.exists {
            okButton = globalOkButton
        } else {
            okButton = alert.buttons.firstMatch
        }

        XCTAssertTrue(okButton.waitForExistence(timeout: 3), "Voice alert should provide dismiss action", file: file, line: line)
        okButton.tap()
        XCTAssertFalse(alert.exists || errorText.exists, "Voice error alert should dismiss", file: file, line: line)
    }
}
