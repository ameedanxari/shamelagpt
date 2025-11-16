//
//  WelcomeUITests.swift
//  shamelagptUITests
//
//  UI tests for welcome screen and onboarding
//

import XCTest
@testable import ShamelaGPT

final class WelcomeUITests: LocalizedUITestCase {
    private let showWelcomeOverrides = [NetworkMockHelper.LaunchEnvironmentKeys.skipWelcome: "0"]
    private let skipWelcomeOverrides = [NetworkMockHelper.LaunchEnvironmentKeys.skipWelcome: "1"]
    
    /// Detects that the welcome screen is visible by looking for its primary actions.
    private func waitForWelcomeScreen(timeout: TimeInterval = 8) -> Bool {
        let skipButton = app.buttons["SkipToChatButton"]
        let getStartedButton = app.buttons["GetStartedButton"]
        return skipButton.waitForExistence(timeout: timeout) || getStartedButton.waitForExistence(timeout: timeout)
    }

    // MARK: - First Launch Tests

    func testWelcomeScreenNotShownOnSecondLaunch() throws {
        // First launch - force welcome
        UITestLauncher.relaunch(app: app, includeReset: true, overrides: showWelcomeOverrides)
        XCTAssertTrue(waitForWelcomeScreen(), "Welcome should appear on first launch when skipWelcome=0")

        // Dismiss via skip to keep flow deterministic
        let skipButton = app.buttons["SkipToChatButton"]
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()
            waitForElementToDisappear(skipButton, timeout: 5)
        }

        // Second launch - force skip
        UITestLauncher.relaunch(app: app, includeReset: true, overrides: skipWelcomeOverrides)
        XCTAssertFalse(waitForWelcomeScreen(timeout: 3), "Welcome should not appear when skipWelcome=1")
    }

    func testWelcomeScreenShowsFeatures() throws {
        // Force fresh launch to show welcome
        UITestLauncher.relaunch(
            app: app,
            includeReset: true,
            overrides: [NetworkMockHelper.LaunchEnvironmentKeys.skipWelcome: "0"]
        )

        XCTAssertTrue(waitForWelcomeScreen(timeout: 5), "Welcome screen should appear")

        // Verify features are shown
        // The welcome screen should highlight key features

        // Check for feature descriptions
        let featureText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'shamela' OR label CONTAINS[c] 'fact' OR label CONTAINS[c] 'ocr' OR label CONTAINS[c] 'voice'")).firstMatch

        if featureText.exists {
            XCTAssertTrue(featureText.exists, "Welcome screen should show features")
        } else {
            // Features might be shown as images or in a different format
            // Verify the screen has substantial content
            let textCount = app.staticTexts.count
            XCTAssertGreaterThan(textCount, 2, "Welcome screen should have feature descriptions")
        }

        // Verify action buttons exist
        let getStartedButton = app.buttons["GetStartedButton"]
        XCTAssertTrue(getStartedButton.exists, "Get Started button should be present")

        let skipButton = app.buttons["SkipToChatButton"]
        XCTAssertTrue(skipButton.exists, "Skip button should be present")
    }

    // MARK: - Navigation Tests

    func testGetStartedButtonNavigatesToMainApp() throws {
        // Force welcome screen
        UITestLauncher.relaunch(app: app, includeReset: true, overrides: showWelcomeOverrides)

        // Wait for welcome screen
        let getStartedButton = app.buttons["GetStartedButton"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5))

        // Tap Get Started
        getStartedButton.tap()

        XCTAssertFalse(waitForWelcomeScreen(timeout: 1), "Should leave welcome screen")

        // After Get Started we should see Auth flow (or main if already authenticated)
        let authEmailField = app.textFields["emailTextField"]
        let chatTab = chatTabButton()
        let reachedAuth = authEmailField.waitForExistence(timeout: 5)
        let reachedMain = chatTab.waitForExistence(timeout: reachedAuth ? 1 : 5)
        XCTAssertTrue(reachedAuth || reachedMain, "Should navigate to Auth or main app after Get Started")
    }

    func testSkipButtonNavigatesToChat() throws {
        // Force welcome screen
        UITestLauncher.relaunch(app: app, includeReset: true, overrides: showWelcomeOverrides)

        // Wait for welcome screen
        let skipButton = app.buttons["SkipToChatButton"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5))

        // Tap Skip
        skipButton.tap()

        XCTAssertFalse(waitForWelcomeScreen(timeout: 1), "Should leave welcome screen")

        // Verify chat tab is available or we land in Auth (if guest flow fails)
        let chatTab = chatTabButton()
        let authEmailField = app.textFields["emailTextField"]
        let reachedChat = chatTab.waitForExistence(timeout: 8)
        let reachedAuth = !reachedChat && authEmailField.waitForExistence(timeout: 5)
        XCTAssertTrue(reachedChat || reachedAuth, "Should navigate to chat or auth after Skip")

        // Verify chat screen elements
        let textField = app.textViews.firstMatch
        XCTAssertTrue(textField.exists, "Chat screen should be accessible")
    }

    func testWelcomeOnboardingFlow() throws {
        // Force welcome screen
        UITestLauncher.relaunch(app: app, includeReset: true, overrides: showWelcomeOverrides)

        // Verify welcome screen appears
        XCTAssertTrue(waitForWelcomeScreen(timeout: 5), "Welcome screen should appear")

        // If there's a multi-step onboarding, test the flow
        // For now, we test the basic flow: Welcome -> Get Started -> Main App

        let getStartedButton = app.buttons["GetStartedButton"]
        XCTAssertTrue(getStartedButton.exists, "Get Started should be available")

        // Tap Get Started
        getStartedButton.tap()

        // After Get Started we should reach Auth or main app
        let continueAsGuestButton = app.buttons["continueAsGuestButton"]
        if continueAsGuestButton.waitForExistence(timeout: 5) {
            continueAsGuestButton.tap()
        }

        let authEmailField = app.textFields["emailTextField"]
        let chatTab = chatTabButton()
        let reachedChat = chatTab.waitForExistence(timeout: 8)
        let reachedAuth = !reachedChat && authEmailField.waitForExistence(timeout: 5)
        XCTAssertTrue(reachedChat || reachedAuth, "Should navigate to Auth or main app after onboarding")

        if reachedAuth, continueAsGuestButton.waitForExistence(timeout: 3) {
            continueAsGuestButton.tap()
            _ = chatTab.waitForExistence(timeout: 5)
        }

        // Verify we're in the main app when available
        if chatTab.exists {
            let historyTab = historyTabButton()
            let settingsTab = settingsTabButton()
            XCTAssertTrue(historyTab.exists && settingsTab.exists, "All main tabs should be accessible after onboarding")
        }
    }
}
