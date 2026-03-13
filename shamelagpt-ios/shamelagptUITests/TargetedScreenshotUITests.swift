//
//  TargetedScreenshotUITests.swift
//  shamelagptUITests
//
//  Targeted UI tests for generating specific screenshots
//

import XCTest
import UIKit

final class TargetedScreenshotUITests: LocalizedUITestCase {

    private var currentAppearance: UIUserInterfaceStyle = .light

    // MARK: - Targeted Screenshot Tests

    /// Generates screenshots for authentication screens
    func test_captureAuthScreenshots() throws {
        try runAuthScreenshots(appearance: .light)
        try runAuthScreenshots(appearance: .dark)
    }

    /// Generates screenshots for chat screens
    func test_captureChatScreenshots() throws {
        try runChatScreenshots(appearance: .light)
        try runChatScreenshots(appearance: .dark)
    }

    /// Generates screenshots for settings screens
    func test_captureSettingsScreenshots() throws {
        try runSettingsScreenshots(appearance: .light)
        try runSettingsScreenshots(appearance: .dark)
    }

    /// Generates screenshots for history screens
    func test_captureHistoryScreenshots() throws {
        try runHistoryScreenshots(appearance: .light)
        try runHistoryScreenshots(appearance: .dark)
    }

    /// Generates screenshots for welcome screens
    func test_captureWelcomeScreenshots() throws {
        try runWelcomeScreenshots(appearance: .light)
        try runWelcomeScreenshots(appearance: .dark)
    }

    /// Generates targeted screenshots based on environment variables
    func test_captureTargetedScreenshots() throws {
        let appearance: UIUserInterfaceStyle = ProcessInfo.processInfo.environment["DARK_MODE"] == "true" ? .dark : .light
        setAppearance(appearance)

        // Get target parameters from environment
        let targetScreen = ProcessInfo.processInfo.environment["TARGET_SCREEN"]?.lowercased()
        let targetLocale = ProcessInfo.processInfo.environment["TARGET_LOCALE"]
        let targetScenario = ProcessInfo.processInfo.environment["TARGET_SCENARIO"]

        print("Generating targeted screenshots:")
        print("- Screen: \(targetScreen ?? "all")")
        print("- Locale: \(targetLocale ?? "all")")
        print("- Scenario: \(targetScenario ?? "all")")
        print("- Appearance: \(appearance == .dark ? "dark" : "light")")

        switch targetScreen {
        case "auth":
            try runAuthScreenshots(appearance: appearance, locale: targetLocale)
        case "chat":
            try runChatScreenshots(appearance: appearance, locale: targetLocale)
        case "settings":
            try runSettingsScreenshots(appearance: appearance, locale: targetLocale)
        case "history":
            try runHistoryScreenshots(appearance: appearance, locale: targetLocale)
        case "welcome":
            try runWelcomeScreenshots(appearance: appearance, locale: targetLocale)
        default:
            // Run all if no specific target
            try runAuthScreenshots(appearance: appearance, locale: targetLocale)
            try runChatScreenshots(appearance: appearance, locale: targetLocale)
            try runSettingsScreenshots(appearance: appearance, locale: targetLocale)
            try runHistoryScreenshots(appearance: appearance, locale: targetLocale)
            try runWelcomeScreenshots(appearance: appearance, locale: targetLocale)
        }
    }

    // MARK: - Private Helper Methods

    private func runAuthScreenshots(appearance: UIUserInterfaceStyle, locale: String? = nil) throws {
        setAppearance(appearance)
        
        let locales = locale != nil ? [locale!] : ["en", "ar", "ur"]
        
        for currentLocale in locales {
            setLocale(currentLocale)
            
            // Test login screen
            UITestLauncher.launch(
                app: app,
                includeReset: true,
                overrides: [
                    "SKIP_WELCOME": "1",
                    "FORCE_AUTH_SCREEN": "login"
                ],
                appearance: appearanceArgument
            )
            
            try captureScreenshot(name: "auth_login_\(currentLocale)_\(appearance == .dark ? "dark" : "light")")
            app.terminate()

            // Test signup screen
            UITestLauncher.launch(
                app: app,
                includeReset: true,
                overrides: [
                    "SKIP_WELCOME": "1",
                    "FORCE_AUTH_SCREEN": "signup"
                ],
                appearance: appearanceArgument
            )
            
            try captureScreenshot(name: "auth_signup_\(currentLocale)_\(appearance == .dark ? "dark" : "light")")
            app.terminate()

            // Test auth error screen
            UITestLauncher.launch(
                app: app,
                includeReset: true,
                overrides: [
                    "SKIP_WELCOME": "1",
                    "FORCE_AUTH_SCREEN": "login",
                    NetworkMockHelper.LaunchEnvironmentKeys.mockAuthError: "invalid_credentials"
                ],
                appearance: appearanceArgument
            )
            
            try captureScreenshot(name: "auth_error_\(currentLocale)_\(appearance == .dark ? "dark" : "light")")
            app.terminate()
        }
    }

    private func runChatScreenshots(appearance: UIUserInterfaceStyle, locale: String? = nil) throws {
        setAppearance(appearance)
        
        let locales = locale != nil ? [locale!] : ["en", "ar", "ur"]
        
        for currentLocale in locales {
            setLocale(currentLocale)
            
            UITestLauncher.launch(
                app: app,
                includeReset: true,
                overrides: [
                    NetworkMockHelper.LaunchEnvironmentKeys.mockChatResponse: chatHappyResponseJSON(),
                    NetworkMockHelper.LaunchEnvironmentKeys.mockPreferences: preferencesJSON(),
                    "SKIP_WELCOME": "1"
                ],
                appearance: appearanceArgument
            )
            
            assertNoErrorBanners(context: "after launch")

            let chatTab = chatTabButton()
            if chatTab.waitForExistence(timeout: 5) {
                chatTab.tap()
            }
            
            // Wait for chat view to load
            let chatView = app.textViews["messageInputField"]
            XCTAssertTrue(chatView.waitForExistence(timeout: 5))

            chatView.tap()
            chatView.typeText(localizedChatQuestion())

            let sendButton = app.buttons["sendButton"]
            XCTAssertTrue(sendButton.waitForExistence(timeout: 5))
            
            try captureScreenshot(name: "chat_happy_\(currentLocale)_\(appearance == .dark ? "dark" : "light")")
            app.terminate()
        }
    }

    private func runSettingsScreenshots(appearance: UIUserInterfaceStyle, locale: String? = nil) throws {
        setAppearance(appearance)
        
        let locales = locale != nil ? [locale!] : ["en", "ar", "ur"]
        
        for currentLocale in locales {
            setLocale(currentLocale)
            
            UITestLauncher.launch(
                app: app,
                includeReset: true,
                overrides: [
                    NetworkMockHelper.LaunchEnvironmentKeys.mockPreferences: preferencesJSON(),
                    "SKIP_WELCOME": "1"
                ],
                appearance: appearanceArgument
            )
            
            assertNoErrorBanners(context: "after launch")

            let settingsTab = settingsTabButton()
            if settingsTab.waitForExistence(timeout: 5) {
                settingsTab.tap()
            }
            
            // Wait for settings view to load
            let settingsView = app.scrollViews["settingsView"]
            XCTAssertTrue(settingsView.waitForExistence(timeout: 5))
            
            try captureScreenshot(name: "settings_main_\(currentLocale)_\(appearance == .dark ? "dark" : "light")")
            app.terminate()
        }
    }

    private func runHistoryScreenshots(appearance: UIUserInterfaceStyle, locale: String? = nil) throws {
        setAppearance(appearance)
        
        let locales = locale != nil ? [locale!] : ["en", "ar", "ur"]
        
        for currentLocale in locales {
            setLocale(currentLocale)
            
            UITestLauncher.launch(
                app: app,
                includeReset: true,
                overrides: [
                    NetworkMockHelper.LaunchEnvironmentKeys.mockHistoryResponse: historyListResponseJSON(),
                    NetworkMockHelper.LaunchEnvironmentKeys.mockPreferences: preferencesJSON(),
                    "SKIP_WELCOME": "1"
                ],
                appearance: appearanceArgument
            )
            
            assertNoErrorBanners(context: "after launch")

            let historyTab = historyTabButton()
            if historyTab.waitForExistence(timeout: 5) {
                historyTab.tap()
            }
            
            // Wait for history view to load
            let historyView = app.scrollViews["historyView"]
            XCTAssertTrue(historyView.waitForExistence(timeout: 5))
            
            try captureScreenshot(name: "history_list_\(currentLocale)_\(appearance == .dark ? "dark" : "light")")
            app.terminate()
        }
    }

    private func runWelcomeScreenshots(appearance: UIUserInterfaceStyle, locale: String? = nil) throws {
        setAppearance(appearance)
        
        let locales = locale != nil ? [locale!] : ["en", "ar", "ur"]
        
        for currentLocale in locales {
            setLocale(currentLocale)
            
            UITestLauncher.launch(
                app: app,
                includeReset: true,
                overrides: [
                    NetworkMockHelper.LaunchEnvironmentKeys.mockPreferences: preferencesJSON()
                ],
                appearance: appearanceArgument
            )
            
            assertNoErrorBanners(context: "after launch")
            
            // Wait for welcome view to load
            let welcomeView = app.scrollViews["welcomeView"]
            XCTAssertTrue(welcomeView.waitForExistence(timeout: 5))
            
            try captureScreenshot(name: "welcome_main_\(currentLocale)_\(appearance == .dark ? "dark" : "light")")
            app.terminate()
        }
    }

    // MARK: - Helper Methods (reuse from StoreScreenshotUITests)

    private func setAppearance(_ appearance: UIUserInterfaceStyle) {
        currentAppearance = appearance
        app.launchArguments.append(appearanceArgument)
    }

    private var appearanceArgument: String {
        switch currentAppearance {
        case .light:
            return "-AppleAppearanceOverride"
        case .dark:
            return "-AppleInterfaceStyle"
        case .unspecified:
            return "-AppleAppearanceOverride"
        @unknown default:
            return "-AppleAppearanceOverride"
        }
    }

    private func setLocale(_ locale: String) {
        app.launchArguments.removeAll { $0.hasPrefix("-AppleLanguages") }
        app.launchArguments.append("-AppleLanguages")
        app.launchArguments.append("(\(locale))")
    }

    private func assertNoErrorBanners(context: String) {
        let errorBanner = app.otherElements["errorBanner"]
        if errorBanner.exists {
            XCTFail("Error banner found \(context)")
        }
    }

    private func chatTabButton() -> XCUIElement {
        return app.tabBars.buttons["chat"]
    }

    private func settingsTabButton() -> XCUIElement {
        return app.tabBars.buttons["settings"]
    }

    private func historyTabButton() -> XCUIElement {
        return app.tabBars.buttons["history"]
    }

    private func localizedChatQuestion() -> String {
        switch currentLocale {
        case "ar":
            return "لدي مدخرات واستثمارات متفرقة، كيف أحسب زكاة المال بدقة بطريقة عملية؟"
        case "ur":
            return "میرے پاس بچت اور مختلف سرمایہ کاری ہے، زکوٰۃ المال صحیح طور پر کیسے نکالوں؟"
        default:
            return "I have savings and mixed investments. What is a practical way to calculate Zakat al-Mal accurately?"
        }
    }

    // MARK: - Mock Response Helpers (reuse from StoreScreenshotUITests)

    private func chatHappyResponseJSON() -> String {
        return """
        {
            "choices": [{
                "message": {
                    "content": "Start by summing all zakatable assets (cash, gold/silver, trading inventory, and trade-intent stocks). Subtract short-term payable debts. If the net value is at or above nisab for one lunar year, pay 2.5%.",
                    "sources": [
                        {
                            "book_name": "Ibn Qudamah - Al-Mughni (Book of Zakat)",
                            "source_url": "https://shamela.ws/book/8463"
                        }
                    ]
                }
            }]
        }
        """
    }

    private func preferencesJSON() -> String {
        return """
        {
            "language": "\(currentLocale ?? "en")",
            "response_preferences": {
                "length": "detailed",
                "style": "academic",
                "focus": "evidence_first"
            }
        }
        """
    }

    private func historyListResponseJSON() -> String {
        return """
        {
            "conversations": [
                {
                    "id": "1",
                    "title": "\(currentLocale == "ar" ? "أشراط الساعة: الفرق بين العلامات الصغرى والكبرى" : currentLocale == "ur" ? "قیامت کی نشانیاں: صغریٰ اور کبریٰ میں فرق" : "Signs of the Hour: Difference Between Minor and Major")",
                    "created_at": "2024-01-15T10:30:00Z",
                    "updated_at": "2024-01-15T11:30:00Z"
                }
            ]
        }
        """
    }
}
