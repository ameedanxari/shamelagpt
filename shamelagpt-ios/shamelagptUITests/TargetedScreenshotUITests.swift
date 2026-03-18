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
    private var currentLocale: String = "en"

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
                    NetworkMockHelper.LaunchEnvironmentKeys.mockHistory: historyListResponseJSON(),
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
        // UITestLauncher applies the simulator appearance via launch arguments.
    }

    private var appearanceArgument: String {
        currentAppearance == .dark ? "dark" : "light"
    }

    private func setLocale(_ locale: String) {
        currentLocale = locale
        UITestLanguageContext.set(locale)
    }

    private func assertNoErrorBanners(context: String) {
        let errorBanner = app.otherElements["errorBanner"]
        if errorBanner.exists {
            XCTFail("Error banner found \(context)")
        }
    }

    private func captureScreenshot(name: String) throws {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let outputPath = UITestEnvironment.value("SCREENSHOT_OUTPUT_DIR") ?? "/tmp/screenshots"
        let deviceName = UITestEnvironment.value("SCREENSHOT_DEVICE") ??
            UITestEnvironment.value("SIMULATOR_DEVICE_NAME") ??
            "iPhone"
        let safeDevice = deviceName.replacingOccurrences(of: " ", with: "_")
        let fileName = "\(safeDevice)_\(name).png"
        let fullPath = (outputPath as NSString).appendingPathComponent(fileName)

        do {
            let fileURL = URL(fileURLWithPath: fullPath)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try screenshot.pngRepresentation.write(to: fileURL, options: .atomic)
            print("SCREENSHOT_PATH: \(fullPath)")
        } catch {
            XCTFail("Failed to save screenshot: \(error)")
        }
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
        let payload: [String: Any] = [
            "answer": "Start by summing all zakatable assets (cash, gold/silver, trading inventory, and trade-intent stocks). Subtract short-term payable debts. If the net value is at or above nisab for one lunar year, pay 2.5%.",
            "conversation_id": "targeted-screenshot-conversation",
            "thread_id": "targeted-screenshot-thread"
        ]
        return jsonString(payload)
    }

    private func preferencesJSON() -> String {
        let payload: [String: Any] = [
            "language_preference": currentLocale,
            "response_preferences": [
                "length": "detailed",
                "style": "academic",
                "focus": "evidence_first"
            ]
        ]
        return jsonString(payload)
    }

    private func historyListResponseJSON() -> String {
        let title: String
        switch currentLocale {
        case "ar":
            title = "أشراط الساعة: الفرق بين العلامات الصغرى والكبرى"
        case "ur":
            title = "قیامت کی نشانیاں: صغریٰ اور کبریٰ میں فرق"
        default:
            title = "Signs of the Hour: Difference Between Minor and Major"
        }

        let nowMs = Date().timeIntervalSince1970 * 1000
        let payload: [[String: Any]] = [
            [
                "id": "targeted-conv-1",
                "title": title,
                "updated_at": nowMs,
                "messages": [
                    ["id": "m1", "content": localizedChatQuestion(), "is_user_message": true]
                ]
            ]
        ]
        return jsonString(payload)
    }

    private func jsonString(_ object: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []),
              let json = String(data: data, encoding: .utf8) else {
            XCTFail("Failed to serialize JSON fixture")
            return "{}"
        }
        return json
    }
}
