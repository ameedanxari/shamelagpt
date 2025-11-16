//
//  StoreScreenshotUITests.swift
//  shamelagptUITests
//
//  UI tests for generating app store screenshots
//

import XCTest
import UIKit

final class StoreScreenshotUITests: LocalizedUITestCase {

    private var currentAppearance: UIUserInterfaceStyle = .light

    // MARK: - Store Screenshot Tests

    /// Generates screenshots for chat interface and settings
    func test_storeScreenshots_chatAndSettings() throws {
        try runChatAndSettings(appearance: .light)
        try runChatAndSettings(appearance: .dark)
    }

    private func runChatAndSettings(appearance: UIUserInterfaceStyle) throws {
        setAppearance(appearance)

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
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))
        sendButton.tap()
        assertNoErrorBanners(context: "after send")

        // Wait for assistant response then capture parity screenshot.
        let assistantResponse = app.scrollViews.firstMatch.staticTexts.firstMatch
        _ = assistantResponse.waitForExistence(timeout: 10)
        takeScreenshot(name: "chat_happy")

        let settingsTab = settingsTabButton()
        if settingsTab.waitForExistence(timeout: 5) {
            settingsTab.tap()
        }

        var settingsLoaded = false
        let settingsView = app.scrollViews.firstMatch
        if settingsView.waitForExistence(timeout: 3) {
            settingsLoaded = true
        } else if app.tables.firstMatch.waitForExistence(timeout: 3) {
            settingsLoaded = true
        } else if app.collectionViews.firstMatch.waitForExistence(timeout: 3) {
            settingsLoaded = true
        }
        
        XCTAssertTrue(settingsLoaded, "Settings view should load")
        takeScreenshot(name: "settings_main")

        UITestLauncher.launch(
            app: app,
            includeReset: true,
            overrides: [
                NetworkMockHelper.LaunchEnvironmentKeys.mockChatError: """
                {"error":"Network error","status_code":500}
                """,
                "SKIP_WELCOME": "1"
            ],
            appearance: appearanceArgument
        )

        let errorChatInput = app.textViews["messageInputField"]
        XCTAssertTrue(errorChatInput.waitForExistence(timeout: 5))
        errorChatInput.tap()
        errorChatInput.typeText(localizedChatErrorPrompt())
        let errorSendButton = app.buttons["sendButton"]
        XCTAssertTrue(errorSendButton.waitForExistence(timeout: 3))
        errorSendButton.tap()
        sleep(1)
        takeScreenshot(name: "chat_error")
    }

    private func assertNoErrorBanners(context: String) {
        let errorBanners = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'error' OR label CONTAINS[c] 'retry'"))
        if errorBanners.count > 0 {
            print("❌ Found \(errorBanners.count) error banners \(context):")
            for i in 0..<errorBanners.count {
                let banner = errorBanners.element(boundBy: i)
                print("   - Banner \(i): '\(banner.label)'")
            }
        }
        XCTAssertEqual(errorBanners.count, 0, "No error banners should be visible \(context)")
    }

    /// Generates screenshots for history/conversation list
    func test_storeScreenshots_history() throws {
        try runHistory(appearance: .light)
        try runHistory(appearance: .dark)
    }

    private func runHistory(appearance: UIUserInterfaceStyle) throws {
        setAppearance(appearance)
        UITestLauncher.launch(
            app: app,
            includeReset: true,
            overrides: [
                "SKIP_WELCOME": "1",
                NetworkMockHelper.LaunchEnvironmentKeys.mockHistory: historyJSON()
            ],
            appearance: appearanceArgument
        )

        // Navigate to history tab.
        // Prefer stable accessibility identifiers/labels over SF Symbol names
        // because iPad tab presentations can expose duplicate "clock.fill" buttons.
        let historyTab = historyTabButton()
        if historyTab.waitForExistence(timeout: 5) {
            historyTab.tap()
        } else {
            let fallbackHistoryTab = app.buttons.matching(
                NSPredicate(format: "identifier == %@ OR label == %@", "HistoryTab", localized("history"))
            ).firstMatch
            XCTAssertTrue(fallbackHistoryTab.waitForExistence(timeout: 5), "History tab should be visible")
            fallbackHistoryTab.tap()
        }
        
        // Wait for history view to load
        let conversationButton = app.buttons["conversationCard_conv-1"]
        let emptyStateButton = app.buttons["historyNewConversationButton"]
        let lockedStateButton = app.buttons["signInButton"]
        let historyLoaded = conversationButton.waitForExistence(timeout: 5)
            || emptyStateButton.waitForExistence(timeout: 5)
            || lockedStateButton.waitForExistence(timeout: 5)
        XCTAssertTrue(historyLoaded)
        takeScreenshot(name: "history_list")
    }

    /// Generates screenshots for welcome/onboarding flow
    func test_storeScreenshots_welcome() throws {
        try runWelcome(appearance: .light)
        try runWelcome(appearance: .dark)
    }

    private func runWelcome(appearance: UIUserInterfaceStyle) throws {
        setAppearance(appearance)
        UITestLauncher.launch(
            app: app,
            includeReset: true,
            overrides: [
                NetworkMockHelper.LaunchEnvironmentKeys.mockChatResponse: chatHappyResponseJSON(),
                NetworkMockHelper.LaunchEnvironmentKeys.skipWelcome: "0"
            ],
            appearance: appearanceArgument
        )
        
        let getStartedButton = app.buttons["GetStartedButton"]
        let logo = app.images["welcomeLogo"]
        _ = logo.waitForExistence(timeout: 10)
        takeScreenshot(name: "welcome_main")
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5))
    }

    /// Generates screenshots for login and signup authentication screens
    func test_storeScreenshots_auth() throws {
        try runAuth(appearance: .light)
        try runAuth(appearance: .dark)
    }

    private func runAuth(appearance: UIUserInterfaceStyle) throws {
        setAppearance(appearance)
        UITestLauncher.launch(
            app: app,
            includeReset: true,
            overrides: [
                NetworkMockHelper.LaunchEnvironmentKeys.skipWelcome: "0"
            ],
            appearance: appearanceArgument
        )
        
        let authGetStartedButton = app.buttons["GetStartedButton"]
        if !authGetStartedButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(authGetStartedButton.waitForExistence(timeout: 5))
        authGetStartedButton.tap()
        
        let emailField = app.textFields["emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(localizedLoginEmail())
        
        let passwordField = app.secureTextFields["passwordTextField"]
        if passwordField.waitForExistence(timeout: 2) {
            passwordField.tap()
            passwordField.typeText("12345678")
        }
        
        takeScreenshot(name: "auth_login")

        let toggleButton = app.buttons["toggleModeButton"]
        XCTAssertTrue(toggleButton.waitForExistence(timeout: 3))
        toggleButton.tap()
        
        let displayNameField = app.textFields["displayNameTextField"]
        XCTAssertTrue(displayNameField.waitForExistence(timeout: 3))

        if emailField.exists {
            emailField.tap()
            emailField.press(forDuration: 1.0)
            let selectAll = app.menuItems["Select All"]
            if selectAll.waitForExistence(timeout: 1) {
                selectAll.tap()
            }
            emailField.typeText("abdullah.khan@shamela.app")
        }
        
        displayNameField.tap()
        displayNameField.typeText(localizedSignupDisplayName())
        takeScreenshot(name: "auth_signup")

        UITestLauncher.launch(
            app: app,
            includeReset: true,
            overrides: [
                NetworkMockHelper.LaunchEnvironmentKeys.skipWelcome: "0",
                NetworkMockHelper.LaunchEnvironmentKeys.mockNetworkError: "1"
            ],
            appearance: appearanceArgument
        )

        let errorGetStartedButton = app.buttons["GetStartedButton"]
        if !errorGetStartedButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(errorGetStartedButton.waitForExistence(timeout: 5))
        errorGetStartedButton.tap()

        let errorEmailField = app.textFields["emailTextField"]
        XCTAssertTrue(errorEmailField.waitForExistence(timeout: 5))
        errorEmailField.tap()
        errorEmailField.typeText(localizedLoginEmail())

        let errorPasswordField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(errorPasswordField.waitForExistence(timeout: 3))
        errorPasswordField.tap()
        errorPasswordField.typeText("12345678")

        let signInButton = app.buttons["signInButton"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 3))
        signInButton.tap()

        let errorLabel = app.staticTexts["errorLabel"]
        XCTAssertTrue(errorLabel.waitForExistence(timeout: 5))
        takeScreenshot(name: "auth_error")
    }

    // MARK: - Helper Methods

    private var appearanceArgument: String {
        currentAppearance == .dark ? "dark" : "light"
    }

    private var appearanceSuffix: String {
        currentAppearance == .dark ? "_dark" : ""
    }

    private func setAppearance(_ appearance: UIUserInterfaceStyle) {
        currentAppearance = appearance
        // Rely on launch arguments (-AppleInterfaceStyle) for simulator appearance;
        // avoid setValue KVC which can throw on newer runtimes.
    }

    private func takeScreenshot(name: String) {
        // Take screenshot with proper naming for app store
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(name)\(appearanceSuffix)"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Detect locale for naming - prioritize the forced language from our base class
        let locale = UITestLanguageContext.forcedLanguage() ??
                     UITestEnvironment.value("APPLE_LOCALE") ??
                     UITestEnvironment.value("XCTEST_APPLE_LOCALE") ??
                     Locale.current.identifier
                     
        // Detect language code (e.g. "ar")
        let language = locale.prefix(2).lowercased()
        
        // Final output path - pull from env or fallback to a predictable location
        // The script now passes SCREENSHOT_OUTPUT_DIR in xcodebuild command
        let outputPath = UITestEnvironment.value("SCREENSHOT_OUTPUT_DIR") ?? "/tmp/screenshots"
        
        let deviceName = UITestEnvironment.value("SCREENSHOT_DEVICE") ??
                         UITestEnvironment.value("SIMULATOR_DEVICE_NAME") ??
                         "iPhone"
        
        let safeDevice = deviceName.replacingOccurrences(of: " ", with: "_")
        let fileName = "\(safeDevice)_\(locale)_\(name)\(appearanceSuffix).png"
        let fullPath = (outputPath as NSString).appendingPathComponent(fileName)
        
        do {
            let fileURL = URL(fileURLWithPath: fullPath)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try screenshot.pngRepresentation.write(to: fileURL, options: .atomic)
            print("SCREENSHOT_PATH: \(fullPath)")
        } catch {
            print("ERROR: Failed to save screenshot: \(error)")
        }
    }

    private func localizedChatQuestion() -> String {
        switch currentLanguage {
        case "ar":
            return "لدي مدخرات واستثمارات متفرقة، كيف أحسب زكاة المال بدقة بطريقة عملية؟"
        case "ur":
            return "میرے پاس بچت اور مختلف سرمایہ کاری ہے، زکوٰۃ المال صحیح طور پر کیسے نکالوں؟"
        default:
            return "I have savings and mixed investments. What is a practical way to calculate Zakat al-Mal accurately?"
        }
    }

    private func localizedChatErrorPrompt() -> String {
        switch currentLanguage {
        case "ar":
            return "أعد المحاولة من فضلك، هناك مشكلة في الاتصال"
        case "ur":
            return "براہ کرم دوبارہ کوشش کریں، کنکشن میں مسئلہ ہے"
        default:
            return "Please check connection"
        }
    }

    private func localizedChatAnswerWithSources() -> String {
        let answer: String
        let sourceOne: String
        let sourceTwo: String
        switch currentLanguage {
        case "ar":
            answer = "اجمع جميع الأموال الزكوية أولاً (النقد، الذهب/الفضة، عروض التجارة، الأسهم المعدّة للتداول). ثم اطرح الديون المستحقة خلال الفترة القريبة. إذا بلغ الصافي نصاب الذهب ومرّ عليه الحول القمري فأخرج 2.5٪. في المحافظ المختلطة: زكِّ الجزء النقدي والتجاري كاملاً، وأما الاستثمار الطويل فبحسب العائد أو التقييم السنوي المعتمد عندك."
            sourceOne = "ابن قدامة - المغني (كتاب الزكاة)"
            sourceTwo = "القرضاوي - فقه الزكاة"
        case "ur":
            answer = "پہلے تمام قابلِ زکوٰۃ اموال جمع کریں (نقدی، سونا/چاندی، تجارتی مال، ٹریڈنگ شیئرز)۔ پھر قریب الادا واجب قرض منہا کریں۔ اگر خالص مال نصاب تک پہنچ جائے اور قمری سال گزر جائے تو 2.5٪ زکوٰۃ ادا کریں۔ مکس پورٹ فولیو میں نقدی اور تجارتی حصے کی مکمل زکوٰۃ نکالیں، جبکہ طویل مدتی سرمایہ کاری میں اپنے مسلک کے مطابق سالانہ اندازہ یا منافع کے اصول پر عمل کریں۔"
            sourceOne = "ابن قدامہ - المغنی (کتاب الزکوٰۃ)"
            sourceTwo = "یوسف القرضاوی - فقہ الزکوٰۃ"
        default:
            answer = "Start by summing all zakatable assets (cash, gold/silver, trading inventory, and trade-intent stocks). Subtract short-term payable debts. If the net value is at or above nisab for one lunar year, pay 2.5%. For mixed portfolios, treat cash and trading positions as fully zakatable; long-term holdings can be handled using your adopted fiqh method (annual valuation or yield-based approach)."
            sourceOne = "Ibn Qudamah - Al-Mughni (Book of Zakat)"
            sourceTwo = "Yusuf al-Qaradawi - Fiqh al-Zakat"
        }

        return """
        \(answer)

        Sources:

        * **book_name:** \(sourceOne), **source_url:** https://shamela.ws/book/8463
        * **book_name:** \(sourceTwo), **source_url:** https://shamela.ws/book/12785
        """
    }

    private func chatHappyResponseJSON() -> String {
        let payload: [String: Any] = [
            "answer": localizedChatAnswerWithSources(),
            "conversation_id": "screenshot-conversation",
            "thread_id": "screenshot-thread"
        ]
        return jsonString(payload)
    }

    private func preferencesJSON() -> String {
        let prompt: String
        switch currentLanguage {
        case "ar":
            prompt = "قدّم خلاصة عملية أولاً، ثم اذكر الدليل من كتب التراث مع التنبيه على صحة الحديث عند الحاجة."
        case "ur":
            prompt = "پہلے عملی خلاصہ دیں، پھر معتبر کتب کے حوالہ جات کے ساتھ مختصر توضیح پیش کریں۔"
        default:
            prompt = "Start with a practical summary, then cite classical sources and note hadith grading when relevant."
        }
        let payload: [String: Any] = [
            "language_preference": currentLanguage,
            "custom_system_prompt": prompt,
            "response_preferences": [
                "length": "detailed",
                "style": "academic",
                "focus": "evidence_first"
            ]
        ]
        return jsonString(payload)
    }

    private func historyJSON() -> String {
        let titles: [String]
        switch currentLanguage {
        case "ar":
            titles = [
                "أشراط الساعة: الفرق بين العلامات الصغرى والكبرى",
                "صفة الوضوء مع السنن والأخطاء الشائعة",
                "زكاة المال: النصاب، الحول، وطريقة الحساب"
            ]
        case "ur":
            titles = [
                "قیامت کی نشانیاں: صغریٰ اور کبریٰ میں فرق",
                "وضو کا مسنون طریقہ اور عام غلطیاں",
                "زکوٰۃ المال: نصاب، سال کی شرط اور حساب"
            ]
        default:
            titles = [
                "Signs of the Hour: Difference Between Minor and Major",
                "Wudu Guide: Sunnah Steps and Common Mistakes",
                "Zakat al-Mal: Nisab, Hawl, and Step-by-Step Calculation"
            ]
        }

        let nowMs = Date().timeIntervalSince1970 * 1000
        let history: [[String: Any]] = [
            [
                "id": "conv-1",
                "title": titles[0],
                "updated_at": nowMs - 3_600_000,
                "messages": [
                    ["id": "m1", "content": localizedChatQuestion(), "is_user_message": true],
                    ["id": "m2", "content": localizedChatAnswerWithSources(), "is_user_message": false]
                ]
            ],
            [
                "id": "conv-2",
                "title": titles[1],
                "updated_at": nowMs - 86_400_000,
                "messages": []
            ],
            [
                "id": "conv-3",
                "title": titles[2],
                "updated_at": nowMs - 345_600_000,
                "messages": []
            ]
        ]
        return jsonString(history)
    }

    private func localizedLoginEmail() -> String {
        switch currentLanguage {
        case "ar":
            return "support.ar@shamela.app"
        case "ur":
            return "support.ur@shamela.app"
        default:
            return "support@shamela.app"
        }
    }

    private func localizedSignupDisplayName() -> String {
        switch currentLanguage {
        case "ar":
            return "عبدالله السلمي"
        case "ur":
            return "عبداللہ خان"
        default:
            return "Abdullah Khan"
        }
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
