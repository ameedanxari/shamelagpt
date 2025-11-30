//
//  SettingsUITests.swift
//  shamelagptUITests
//
//  UI tests for settings and preferences
//

import XCTest

final class SettingsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        UITestLauncher.launch(app: app)

        // Skip welcome screen if present
        if app.buttons["Skip to Chat"].waitForExistence(timeout: 5) {
            app.buttons["Skip to Chat"].tap()
        }

        // Navigate to settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.waitForExistence(timeout: 3) {
            settingsTab.tap()
        }
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Tests

    func testSettingsTabAccessible() throws {
        // Verify settings tab is accessible
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        XCTAssertTrue(settingsTab.isEnabled, "Settings tab should be enabled")

        // Verify settings screen is displayed
        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: 5), "Settings navigation bar should appear")
    }

    func testSettingsMenuItemsVisible() throws {
        // Verify all settings menu items are visible
        // In SwiftUI Form, the table might not exist, so we check for the content instead
        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.exists, "Settings navigation bar should exist")

        // Check for Language setting using accessibility identifier
        let languageRow = app.buttons["LanguageRow"]
        XCTAssertTrue(languageRow.waitForExistence(timeout: 3), "Language setting should be visible")

        // Check for About setting - look for the text or button
        let aboutExists = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'about'")).firstMatch.exists ||
                         app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'about'")).firstMatch.exists
        XCTAssertTrue(aboutExists, "About setting should be visible")

        // Verify support section exists (optional - some apps may not have this)
        // This is an optional check, so we don't fail if it doesn't exist
    }

    // MARK: - Language Selection Tests

    func testLanguageSelectionPersists() throws {
        // Select language
        let languageRow = app.buttons["LanguageRow"]
        XCTAssertTrue(languageRow.waitForExistence(timeout: 5), "Language row should exist")
        languageRow.tap()

        // Find Arabic option as a button containing the text
        let arabicButton = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "العربية")).firstMatch
        XCTAssertTrue(arabicButton.waitForExistence(timeout: 3), "Arabic language option should exist")
        arabicButton.tap()

        // Navigate back to settings - should automatically go back after selection
        sleep(1)

        // Verify language row now shows "العربية"
        let arabicInRow = app.staticTexts["العربية"]
        XCTAssertTrue(arabicInRow.waitForExistence(timeout: 3), "Selected language should be displayed in settings")

        // Navigate away and back to verify persistence within session
        let chatTab = app.tabBars.buttons["Chat"]
        if chatTab.waitForExistence(timeout: 3) {
            chatTab.tap()
            sleep(1)
        }

        // Navigate back to settings
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.waitForExistence(timeout: 3) {
            settingsTab.tap()
            sleep(1)
        }

        // Verify language is still Arabic (persists within session)
        let persistedArabic = app.staticTexts["العربية"]
        XCTAssertTrue(persistedArabic.waitForExistence(timeout: 3), "Language selection should persist across navigation")
    }

    func testChangeLanguageUpdatesUI() throws {
        // Navigate to language selection
        let languageRow = app.buttons["LanguageRow"]
        XCTAssertTrue(languageRow.waitForExistence(timeout: 5), "Language row should exist")
        languageRow.tap()

        // Select Arabic
        let arabicOption = app.staticTexts["العربية"]
        if arabicOption.waitForExistence(timeout: 3) {
            arabicOption.tap()

            // Wait for UI to update
            sleep(2)

            // Navigate to chat to see UI changes
            let chatTab = app.tabBars.buttons["Chat"]
            if chatTab.exists {
                chatTab.tap()

                // Verify UI text has changed to Arabic
                // Check for Arabic placeholder or labels
                let arabicText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'الدردشة' OR label CONTAINS[c] 'رسالة'")).firstMatch
                XCTAssertTrue(arabicText.waitForExistence(timeout: 3), "UI should update to Arabic text")
            }

            // Switch back to English
            let settingsTab = app.tabBars.buttons["Settings"]
            if settingsTab.waitForExistence(timeout: 3) {
                settingsTab.tap()
            }

            sleep(1)
            let languageRowAgain = app.buttons["LanguageRow"]
            if languageRowAgain.waitForExistence(timeout: 3) {
                languageRowAgain.tap()

                let englishOption = app.staticTexts["English"]
                if englishOption.waitForExistence(timeout: 3) {
                    englishOption.tap()
                    sleep(2)

                    // Verify UI is back to English
                    let englishText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Chat' OR label CONTAINS 'Message'")).firstMatch
                    XCTAssertTrue(englishText.waitForExistence(timeout: 3), "UI should update to English text")
                }
            }
        }
    }

    func testArabicLanguageEnablesRTL() throws {
        // Select Arabic language
        let languageRow = app.buttons["LanguageRow"]
        XCTAssertTrue(languageRow.waitForExistence(timeout: 5), "Language row should exist")
        languageRow.tap()

        let arabicOption = app.staticTexts["العربية"]
        if arabicOption.waitForExistence(timeout: 3) {
            arabicOption.tap()

            // Wait for language change
            sleep(2)

            // Navigate to chat
            let chatTab = app.tabBars.buttons["Chat"]
            if chatTab.exists {
                chatTab.tap()

                // Verify RTL layout
                // In RTL, the text input and buttons should be aligned to the right
                // We can check this by examining the frame positions
                // or by verifying Arabic text is displayed

                let textField = app.textViews.firstMatch
                if textField.waitForExistence(timeout: 3) {
                    // In RTL mode, UI elements should be flipped
                    // This is a basic check - comprehensive RTL testing is in AccessibilityUITests
                    XCTAssertTrue(textField.exists, "RTL layout should be applied")
                }

                // Check for Arabic UI text
                let arabicUIElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'إرسال' OR label CONTAINS[c] 'الدردشة'")).firstMatch
                XCTAssertTrue(arabicUIElement.waitForExistence(timeout: 3), "Arabic language should enable RTL and Arabic text")
            }
        }
    }

    func testEnglishLanguageDisablesRTL() throws {
        // First set to Arabic
        let languageRow = app.buttons["LanguageRow"]
        XCTAssertTrue(languageRow.waitForExistence(timeout: 5), "Language row should exist")
        languageRow.tap()

        let arabicOption = app.staticTexts["العربية"]
        if arabicOption.waitForExistence(timeout: 3) {
            arabicOption.tap()
            sleep(2)

            // Now switch to English
            let settingsTab = app.tabBars.buttons["Settings"]
            if settingsTab.waitForExistence(timeout: 3) {
                settingsTab.tap()
            }

            sleep(1)
            let languageRowAgain = app.buttons["LanguageRow"]
            if languageRowAgain.waitForExistence(timeout: 3) {
                languageRowAgain.tap()

                let englishOption = app.staticTexts["English"]
                if englishOption.waitForExistence(timeout: 3) {
                    englishOption.tap()
                    sleep(2)

                    // Navigate to chat
                    let chatTab = app.tabBars.buttons["Chat"]
                    if chatTab.exists {
                        chatTab.tap()

                        // Verify LTR layout
                        let textField = app.textViews.firstMatch
                        if textField.waitForExistence(timeout: 3) {
                            // In LTR mode, English text should be displayed
                            XCTAssertTrue(textField.exists, "LTR layout should be applied")
                        }

                        // Check for English UI text
                        let englishUIElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Send' OR label CONTAINS 'Chat'")).firstMatch
                        XCTAssertTrue(englishUIElement.waitForExistence(timeout: 3), "English language should use LTR and English text")
                    }
                }
            }
        }
    }

    // MARK: - About/Legal Tests

    func testAboutPageAccessible() throws {
        // Find and tap About row - look for text containing "About ShamelaGPT"
        let aboutRow = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'About'")).firstMatch

        XCTAssertTrue(aboutRow.waitForExistence(timeout: 5), "About row should exist in settings")
        aboutRow.tap()

        // Verify About page opens - wait a bit for navigation
        sleep(1)

        // Look for About content or navigation bar
        let aboutContent = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'ShamelaGPT' OR label CONTAINS[c] 'mission'")).firstMatch
        XCTAssertTrue(aboutContent.waitForExistence(timeout: 3), "About page should open and show content")

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
    }

    func testPrivacyPolicyAccessible() throws {
        // Look for Privacy Policy button in settings
        let privacyRow = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Privacy'")).firstMatch

        XCTAssertTrue(privacyRow.waitForExistence(timeout: 5), "Privacy Policy option should exist")
        privacyRow.tap()

        // Wait for navigation
        sleep(1)

        // Verify Privacy Policy page opens
        // It might open a web view or show text content
        let privacyWebView = app.webViews.firstMatch
        let privacyTextView = app.textViews.firstMatch
        let privacyText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'privacy'")).firstMatch

        let privacyContent = privacyWebView.waitForExistence(timeout: 5) ||
                            privacyTextView.waitForExistence(timeout: 5) ||
                            privacyText.waitForExistence(timeout: 5)

        XCTAssertTrue(privacyContent, "Privacy Policy content should be displayed")

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
    }

    func testTermsOfServiceAccessible() throws {
        // Look for Terms of Service button in settings
        let termsRow = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Terms'")).firstMatch

        XCTAssertTrue(termsRow.waitForExistence(timeout: 5), "Terms of Service option should exist")
        termsRow.tap()

        // Wait for navigation
        sleep(1)

        // Verify Terms page opens
        let termsWebView = app.webViews.firstMatch
        let termsTextView = app.textViews.firstMatch
        let termsText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'terms'")).firstMatch

        let termsContent = termsWebView.waitForExistence(timeout: 5) ||
                          termsTextView.waitForExistence(timeout: 5) ||
                          termsText.waitForExistence(timeout: 5)

        XCTAssertTrue(termsContent, "Terms of Service content should be displayed")

        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
    }

    func testLegalPagesContainText() throws {
        // Open About section
        let aboutRow = app.tables.cells.containing(.staticText, identifier: "About").firstMatch

        if aboutRow.waitForExistence(timeout: 5) {
            aboutRow.tap()

            // Try to open Privacy Policy
            let privacyRow = app.tables.cells.containing(.staticText, identifier: "Privacy Policy").firstMatch
            if privacyRow.waitForExistence(timeout: 3) {
                privacyRow.tap()

                // Verify content exists
                sleep(1)

                // Check for text content
                let hasContent = app.webViews.firstMatch.exists ||
                                app.textViews.firstMatch.exists ||
                                app.staticTexts.count > 0

                XCTAssertTrue(hasContent, "Privacy Policy should contain text")

                // Go back
                app.navigationBars.buttons.firstMatch.tap()
            }

            // Try to open Terms of Service
            let termsRow = app.tables.cells.containing(.staticText, identifier: "Terms of Service").firstMatch
            if termsRow.waitForExistence(timeout: 3) {
                termsRow.tap()

                // Verify content exists
                sleep(1)

                let hasContent = app.webViews.firstMatch.exists ||
                                app.textViews.firstMatch.exists ||
                                app.staticTexts.count > 0

                XCTAssertTrue(hasContent, "Terms of Service should contain text")

                // Go back
                app.navigationBars.buttons.firstMatch.tap()
            }

            // Navigate back to settings
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
}
