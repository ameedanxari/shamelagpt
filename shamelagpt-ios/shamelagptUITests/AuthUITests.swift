//
//  AuthUITests.swift
//  shamelagptUITests
//
//  Created by AI Agent on 12/01/2026.
//

import XCTest


final class AuthUITests: LocalizedUITestCase {
    private let scenario = NetworkMockHelper.MockScenarioID.success.rawValue

    private func launchToAuth() {
        UITestLauncher.launch(
            app: app,
            includeReset: true,
            overrides: [
                NetworkMockHelper.LaunchEnvironmentKeys.skipWelcome: "0",
                "FORCE_AUTH_SCREEN": "1"
            ]
        )

        let getStartedButton = app.buttons[UITestID.Welcome.getStartedButton]
        if getStartedButton.waitForExistence(timeout: 5) {
            getStartedButton.tap()
        }
    }

    func testAuthScreenElementsVisible() throws {
        launchToAuth()

        let emailField = app.textFields[UITestID.Auth.emailTextField]
        let passwordField = app.secureTextFields[UITestID.Auth.passwordTextField]
        let signInButton = app.buttons[UITestID.Auth.signInButton]
        let toggleButton = app.buttons[UITestID.Auth.toggleModeButton]
        let continueAsGuestButton = app.buttons[UITestID.Auth.continueAsGuestButton]

        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                emailField,
                selector: UITestID.Auth.emailTextField,
                scenario: scenario,
                observedState: "auth_screen_loaded"
            ),
            "Email field should exist"
        )
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                passwordField,
                selector: UITestID.Auth.passwordTextField,
                scenario: scenario,
                observedState: "auth_screen_loaded"
            ),
            "Password field should exist"
        )
        XCTAssertTrue(signInButton.exists, "Sign In button should exist")
        XCTAssertTrue(toggleButton.exists, "Toggle mode button should exist")
        XCTAssertTrue(continueAsGuestButton.exists, "Continue as Guest button should exist")
    }

    func testToggleToSignUpShowsDisplayName() throws {
        launchToAuth()

        let toggleButton = app.buttons[UITestID.Auth.toggleModeButton]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                toggleButton,
                selector: UITestID.Auth.toggleModeButton,
                scenario: scenario,
                observedState: "auth_screen_loaded"
            ),
            "Toggle mode button should exist"
        )
        toggleButton.tap()

        let displayNameField = app.textFields[UITestID.Auth.displayNameTextField]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                displayNameField,
                selector: UITestID.Auth.displayNameTextField,
                scenario: scenario,
                observedState: "sign_up_mode_toggled"
            ),
            "Display name field should appear in sign up mode"
        )

        let signUpButton = app.buttons[UITestID.Auth.signUpButton]
        XCTAssertTrue(signUpButton.exists, "Sign Up button should exist in sign up mode")
    }

    func testContinueAsGuestNavigatesToChat() throws {
        launchToAuth()

        let continueAsGuestButton = app.buttons[UITestID.Auth.continueAsGuestButton]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                continueAsGuestButton,
                selector: UITestID.Auth.continueAsGuestButton,
                scenario: scenario,
                observedState: "auth_screen_loaded"
            ),
            "Continue as Guest button should exist"
        )
        continueAsGuestButton.tap()

        let chatTab = chatTabButton()
        let messageInput = app.textViews[UITestID.Chat.messageInputField]
        let reachedMain = chatTab.waitForExistence(timeout: 5) || messageInput.waitForExistence(timeout: 8)
        XCTAssertTrue(reachedMain, "Should navigate to main app after continuing as guest")
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                messageInput,
                selector: UITestID.Chat.messageInputField,
                scenario: scenario,
                observedState: "guest_navigation_complete"
            ),
            "Chat input should be visible for guest"
        )
    }

    func testEmptyCredentialsShowsError() throws {
        launchToAuth()

        let signInButton = app.buttons[UITestID.Auth.signInButton]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                signInButton,
                selector: UITestID.Auth.signInButton,
                scenario: scenario,
                observedState: "auth_screen_loaded"
            ),
            "Sign In button should exist"
        )
        signInButton.tap()

        let errorLabel = app.staticTexts[UITestID.Auth.errorLabel]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                errorLabel,
                selector: UITestID.Auth.errorLabel,
                scenario: scenario,
                observedState: "empty_sign_in_submitted",
                failureClass: "render_timing"
            ),
            "Error label should appear for empty credentials"
        )
    }
}
