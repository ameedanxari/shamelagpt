//
//  SettingsUITests.swift
//  shamelagptUITests
//
//  UI tests for settings and preferences
//

import XCTest
@testable import ShamelaGPT

final class SettingsUITests: LocalizedUITestCase {
    private let scenario = NetworkMockHelper.MockScenarioID.success.rawValue

    // MARK: - Navigation Tests

    private func launchToSettings(includeReset: Bool = true, overrides: [String: String] = [:]) {
        UITestLauncher.launch(app: app, includeReset: includeReset, overrides: overrides)
        skipWelcomeIfNeeded()
        // Navigate to settings tab
        let settingsTab = settingsTabButton()
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab should exist")
        settingsTab.tap()
    }

    func testSettingsMenuItemsVisible() throws {
        launchToSettings()
        // Verify all settings menu items are visible
        // Do not rely on navigation bar title here. On iPad split/stack variants,
        // the localized nav title can be hidden while settings content is present.

        // Check for Language setting using accessibility identifier
        let languageRow = app.buttons[UITestID.Settings.languageRow]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                languageRow,
                timeout: 3,
                selector: UITestID.Settings.languageRow,
                scenario: scenario,
                observedState: "settings_screen_loaded"
            ),
            "Language setting should be visible"
        )

        // Check for About setting using accessibility identifier (row label differs from header text)
        let aboutRow = app.buttons[UITestID.Settings.aboutRow]
        XCTAssertTrue(scrollToElement(aboutRow), "About setting should be visible")

        let privacyRow = app.buttons[UITestID.Settings.privacyRow]
        XCTAssertTrue(scrollToElement(privacyRow), "Privacy Policy setting should be visible")

        let termsRow = app.buttons[UITestID.Settings.termsRow]
        XCTAssertTrue(scrollToElement(termsRow), "Terms of Service setting should be visible")

        // Verify support section exists (optional - some apps may not have this)
        // This is an optional check, so we don't fail if it doesn't exist
    }

    private func scrollToElement(_ element: XCUIElement, maxSwipes: Int = 6) -> Bool {
        if element.waitForExistence(timeout: 1), element.isHittable {
            return true
        }
        for _ in 0..<maxSwipes {
            app.swipeUp()
            if element.exists, element.isHittable {
                return true
            }
        }
        return element.exists
    }

    private func openLanguageSelection() {
        let languageRow = app.buttons[UITestID.Settings.languageRow]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                languageRow,
                selector: UITestID.Settings.languageRow,
                scenario: scenario,
                observedState: "settings_screen_loaded"
            ),
            "Language row should exist"
        )
        languageRow.tap()
    }

    private func selectLanguage(code: String) {
        let languageOption = app.buttons[languageOptionIdentifier(code)].firstMatch
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                languageOption,
                selector: languageOptionIdentifier(code),
                scenario: scenario,
                observedState: "language_sheet_opened"
            ),
            "Language option \(code) should exist"
        )
        languageOption.tap()
    }

    private func openSettingsRow(identifier: String, expectedNavTitleKey: String) {
        let row = app.buttons[identifier]
        XCTAssertTrue(scrollToElement(row), "\(identifier) should exist in settings")
        row.tap()

        let navTitle = localized(expectedNavTitleKey)
        let navBar = app.navigationBars[navTitle]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                navBar,
                selector: identifier,
                scenario: scenario,
                observedState: "settings_row_opened",
                failureClass: "render_timing"
            ),
            "\(identifier) destination should load"
        )

        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 3) {
            backButton.tap()
            return
        }

        // On split-view layouts there may be no explicit back button; ensure settings content is still visible.
        XCTAssertTrue(
            app.buttons[UITestID.Settings.languageRow].waitForExistence(timeout: 3),
            "Should return to settings context after opening \(identifier)"
        )
    }

    private func localized(_ key: String, language: String) -> String {
        UITestLocalization.localizedString(for: key, language: language)
    }

    private func targetLanguageCodeForSwitch() -> String {
        switch currentLanguage.lowercased() {
        case "ar", "ur":
            return "en"
        default:
            return "ar"
        }
    }

    private func languageOptionIdentifier(_ code: String) -> String {
        UITestID.Settings.languageOption(code)
    }

    private func languageSelectedCheckmarkIdentifier(_ code: String) -> String {
        UITestID.Settings.languageCheckmark(code)
    }

    // MARK: - Language Selection Tests

    func testLanguageSwitchUpdatesUIAndPersists() throws {
        launchToSettings()

        let targetLanguage = targetLanguageCodeForSwitch()

        openLanguageSelection()
        selectLanguage(code: targetLanguage)

        let languageRow = app.buttons[UITestID.Settings.languageRow]
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                languageRow,
                selector: UITestID.Settings.languageRow,
                scenario: scenario,
                observedState: "language_selected"
            ),
            "Language row should exist after selection"
        )

        openLanguageSelection()
        let checkmarkIdentifier = languageSelectedCheckmarkIdentifier(targetLanguage)
        var selectedCheckmark = app.images[checkmarkIdentifier]
        if !selectedCheckmark.exists {
            selectedCheckmark = app.otherElements[checkmarkIdentifier]
        }
        XCTAssertTrue(
            assertElementExistsWithDiagnostics(
                selectedCheckmark,
                timeout: 3,
                selector: checkmarkIdentifier,
                scenario: scenario,
                observedState: "language_selection_confirmed"
            ),
            "Selected language should show a checkmark without relaunch"
        )

        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 3) {
            backButton.tap()
            return
        }

        XCTAssertTrue(
            app.buttons[UITestID.Settings.languageRow].waitForExistence(timeout: 3),
            "Language row should remain visible after closing language selection"
        )
    }

    // MARK: - About/Legal Tests

    func testLegalPagesAccessible() throws {
        launchToSettings()

        openSettingsRow(identifier: UITestID.Settings.aboutRow, expectedNavTitleKey: "settings.about")
        openSettingsRow(identifier: UITestID.Settings.privacyRow, expectedNavTitleKey: "settings.privacyPolicy")
        openSettingsRow(identifier: UITestID.Settings.termsRow, expectedNavTitleKey: "settings.termsOfService")
    }
}
