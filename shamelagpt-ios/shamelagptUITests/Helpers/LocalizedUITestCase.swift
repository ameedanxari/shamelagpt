//
//  LocalizedUITestCase.swift
//  shamelagptUITests
//
//  Base class for UI tests that need to run across multiple languages.
//

import XCTest

class LocalizedUITestCase: XCTestCase {
    
    /// The supported languages for localized testing
    class var supportedLanguages: [String] { ["en", "ar", "ur"] }
    
    /// The current language being tested in this invocation
    private(set) var currentLanguage: String = "en"
    private var didValidateLanguageProbe = false
    
    /// Shared application instance for UI tests
    var app: XCUIApplication!

    /// Toggle verbose UI debug logging (disabled by default).
    var isDebugUIEnabled: Bool {
        let raw = UITestEnvironment.value("UITEST_DEBUG_UI")?.lowercased()
        return raw == "1" || raw == "true" || raw == "yes"
    }

    func withDebugUI(_ block: () -> Void) {
        guard isDebugUIEnabled else { return }
        block()
    }

    func logDebugUI(_ message: @autoclosure () -> String) {
        guard isDebugUIEnabled else { return }
        print(message())
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        didValidateLanguageProbe = false
    }
    
    override func tearDownWithError() throws {
        if let app, app.state == .runningForeground || app.state == .runningBackground {
            assertLanguageApplied()
        }
        app = nil
        try super.tearDownWithError()
    }
    
    override func invokeTest() {
        let originalEnv = UITestEnvironment.value("FORCED_LANGUAGE")
        let originalOverride = UITestLanguageContext.current
        defer {
            if let originalOverride {
                UITestLanguageContext.set(originalOverride)
            } else {
                UITestLanguageContext.clear()
            }
            if let originalEnv {
                setenv("FORCED_LANGUAGE", originalEnv, 1)
            } else {
                unsetenv("FORCED_LANGUAGE")
            }
        }

        // Allow CI/dev to scope locale fan-out for stability/speed when needed.
        let rawLanguageOverride = UITestEnvironment.value("UITEST_LANGUAGES")
        let explicitLanguages = rawLanguageOverride?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        let languages = (explicitLanguages?.isEmpty == false) ? explicitLanguages! : Self.supportedLanguages

        // Run the test method once for each configured language
        for language in languages {
            // Avoid hammering simulator process transitions when tests fan out by locale.
            Thread.sleep(forTimeInterval: 0.2)
            // Set the language in the environment so UITestLauncher and tests can find it
            setenv("FORCED_LANGUAGE", language, 1)
            self.currentLanguage = language
            UITestLanguageContext.set(language)
            
            print("--- RUNNING TEST IN LANGUAGE: \(language.uppercased()) ---")
            
            // This calls setUp, the test method, and tearDown
            super.invokeTest()
        }
    }

    /// Returns a localized string from the app bundle for the current test language.
    func localized(_ key: String) -> String {
        UITestLocalization.localizedString(for: key, language: currentLanguage)
    }

    /// Returns ordered localized candidates for a key across supported locales.
    /// The current language is preferred, with English and other supported locales as fallback.
    func localizedCandidates(for key: String) -> [String] {
        var candidates: [String] = []

        func appendUnique(_ value: String) {
            guard !value.isEmpty else { return }
            guard !candidates.contains(value) else { return }
            candidates.append(value)
        }

        appendUnique(UITestLocalization.localizedString(for: key, language: currentLanguage))
        appendUnique(UITestLocalization.localizedString(for: key, language: "en"))

        for language in Self.supportedLanguages where language != currentLanguage && language != "en" {
            appendUnique(UITestLocalization.localizedString(for: key, language: language))
        }

        return candidates
    }
    
    /// Dismisses the welcome/onboarding screen when present and optionally navigates to chat.
    func skipWelcomeIfNeeded(navigateToChat: Bool = false) {
        assertLanguageApplied()

        let skipButton = app.buttons[UITestID.Welcome.skipToChatButton]
        let getStartedButton = app.buttons[UITestID.Welcome.getStartedButton]
        
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()
        } else if getStartedButton.waitForExistence(timeout: 3) {
            getStartedButton.tap()
        }
        
        if navigateToChat {
            let chatTab = tabButton(identifier: UITestID.Tab.chat, labelKey: "chat")
            if chatTab.exists {
                chatTab.tap()
            }
        }
    }

    func assertLanguageApplied(file: StaticString = #filePath, line: UInt = #line) {
        guard !didValidateLanguageProbe else { return }
        let normalizedLanguage = String(currentLanguage.prefix(2)).lowercased()
        let probeID = UITestID.Debug.languageProbe(normalizedLanguage)
        let probe = app.descendants(matching: .any).matching(identifier: probeID).firstMatch
        let exists = probe.waitForExistence(timeout: 3)
        XCTAssertTrue(
            exists,
            "App locale probe missing for expected language '\(normalizedLanguage)'. Expected id: \(probeID)",
            file: file,
            line: line
        )
        didValidateLanguageProbe = true
    }

    func tabButton(identifier: String, labelKey: String) -> XCUIElement {
        // Prefer stable accessibility identifier across container types.
        let identifierMatches: [XCUIElement] = [
            app.tabBars.buttons[identifier],
            app.buttons[identifier],
            app.otherElements[identifier],
            app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        ]

        for match in identifierMatches where match.exists {
            return match
        }

        let labels = localizedCandidates(for: labelKey)
        for label in labels {
            let labelMatches: [XCUIElement] = [
                app.tabBars.buttons[label],
                app.buttons[label],
                app.otherElements[label]
            ]

            for match in labelMatches where match.exists {
                return match
            }
        }

        return app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func chatTabButton() -> XCUIElement {
        tabButton(identifier: UITestID.Tab.chat, labelKey: "chat")
    }

    func historyTabButton() -> XCUIElement {
        tabButton(identifier: UITestID.Tab.history, labelKey: "history")
    }

    func settingsTabButton() -> XCUIElement {
        tabButton(identifier: UITestID.Tab.settings, labelKey: "settings")
    }

    @discardableResult
    func assertElementExistsWithDiagnostics(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        selector: String,
        scenario: String,
        observedState: String,
        failureClass: String = "selector_mismatch",
        testName: String = #function,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        guard !exists else { return true }

        UITestDiagnostics.emit(
            UITestDiagnosticEvent(
                testName: testName,
                platform: UITestDiagnostics.currentPlatformLabel(),
                locale: currentLanguage,
                selectorOrTag: selector,
                scenarioID: scenario,
                observedState: observedState,
                failureClass: failureClass
            )
        )
        XCTFail("Expected element does not exist: \(selector)", file: file, line: line)
        return false
    }
}
