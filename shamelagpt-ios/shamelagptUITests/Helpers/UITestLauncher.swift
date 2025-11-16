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
        overrides: [String: String] = [:],
        appearance: String? = nil
    ) {
        app.terminate()
        // Give SpringBoard/CoreSimulator a brief settle window between relaunches.
        // This reduces launch-time simulator instability during rapid UI test loops.
        Thread.sleep(forTimeInterval: 0.35)
        app.launchArguments = ["-UI-Testing"]
        var environment = NetworkMockHelper.baseUITestEnvironment(
            delay: 0.1,
            includeReset: includeReset,
            overrides: overrides
        )

        // Propagate requested appearance (light/dark) if provided by caller or env
        if let appearance = appearance ?? UITestEnvironment.value("UITEST_APPEARANCE") {
            let normalized = appearance.lowercased() == "dark" ? "Dark" : "Light"
            app.launchArguments += ["-AppleInterfaceStyle", normalized, "-uiuserinterfacestyle", normalized]
            environment["UITEST_APPEARANCE"] = normalized.lowercased()
        }
        
        // Propagate forced language if present in the test process (e.g. from LocalizedUITestCase).
        // Keep locale forcing app-scoped only; global simulator locale overrides
        // (AppleLanguages/AppleLocale) can destabilize SpringBoard on some runtimes.
        if let forcedLanguage = UITestLanguageContext.forcedLanguage() {
            environment["FORCED_LANGUAGE"] = forcedLanguage
            app.launchArguments += ["-Language", forcedLanguage]
        } else {
            // Auto-detect from XCTest environment or system locale as fallback
            let locale = UITestEnvironment.value("XCTEST_APPLE_LOCALE") ??
                         UITestEnvironment.value("APPLE_LOCALE") ??
                         Locale.current.identifier
            let lang = String(locale.prefix(2)).lowercased()
            app.launchArguments += ["-Language", lang]
        }
        
        app.launchEnvironment = environment
        // Additional pacing before launch avoids occasional simulator-side races.
        Thread.sleep(forTimeInterval: 0.15)
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

    /// Helper to safely type text in a text input, retrying focus when keyboard is not active.
    /// - Parameters:
    ///   - textField: The text field or text view to type into.
    ///   - text: The text to type.
    /// - Returns: true if text was typed successfully, false otherwise.
    @discardableResult
    static func safeTypeText(in textField: XCUIElement, text: String) -> Bool {
        guard textField.waitForExistence(timeout: 5) else { return false }

        let app = XCUIApplication()

        func focusInput() -> Bool {
            if textField.isHittable {
                textField.tap()
            } else {
                let center = textField.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
            }
            return app.keyboards.firstMatch.waitForExistence(timeout: 1.5)
        }

        var focused = app.keyboards.firstMatch.exists
        if !focused {
            focused = focusInput()
        }
        if !focused {
            focused = focusInput()
        }
        if !focused {
            return false
        }

        textField.typeText(text)
        return true
    }
}
