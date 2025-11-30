//
//  UITestLauncher.swift
//  shamelagptUITests
//
//  Provides a consistent launcher for UI tests with mocked networking.
//

import XCTest

enum UITestLauncher {
    /// Launches the app with UI-testing arguments and a base mocked environment.
    /// - Parameters:
    ///   - app: The application instance to launch.
    ///   - includeReset: Whether to include RESET_APP_STATE in the environment.
    ///   - overrides: Additional environment overrides for a specific scenario.
    static func launch(
        app: XCUIApplication,
        includeReset: Bool = true,
        overrides: [String: String] = [:]
    ) {
        app.terminate()
        app.launchArguments = ["UI-Testing"]
        app.launchEnvironment = NetworkMockHelper.baseUITestEnvironment(
            delay: 0.1,
            includeReset: includeReset,
            overrides: overrides
        )
        app.launch()
    }

    /// Relaunches the app with a fresh mocked environment and optional overrides.
    static func relaunch(
        app: XCUIApplication,
        includeReset: Bool = true,
        overrides: [String: String] = [:]
    ) {
        launch(app: app, includeReset: includeReset, overrides: overrides)
    }

    /// Helper to safely type text in a text field, handling system paste menus
    /// - Parameters:
    ///   - textField: The text field or text view to type into
    ///   - text: The text to type
    static func safeTypeText(in textField: XCUIElement, text: String) {
        textField.tap()

        // Wait a moment for any system menus to appear
        sleep(1)

        // Dismiss any paste menu if it appears by tapping the field again
        if textField.exists {
            textField.typeText(text)
        }
    }
}
