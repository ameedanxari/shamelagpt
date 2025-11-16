//
//  ShamelaGPTApp.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 04/11/2025.
//

import SwiftUI
import UIKit

@main
struct ShamelaGPTApp: App {
    // MARK: - Properties

    /// App coordinator for navigation management
    @StateObject private var coordinator: AppCoordinator
    @StateObject private var chatSessionState: ChatSessionState

    /// Dependency container
    private let container: DependencyContainer
    private let sessionManager: SessionManager
    private let authRepository: AuthRepository
    @StateObject private var startupViewModel: AppStartupViewModel
    private let forcedColorScheme: ColorScheme?

    @State private var isAuthenticated: Bool
    @State private var isGuest: Bool = false
    @StateObject private var shakeDetector = ShakeDetector()
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showFeedbackPrompt = false
    @State private var hasStartedStartupGate = false
    @State private var hasMetMinimumStartupDuration = false
    
    private func presentAuth() {
        isAuthenticated = false
        isGuest = false
        self.sessionManager.setGuest(false)
        chatSessionState.resetToNew()
        coordinator.shouldShowWelcome = false
        coordinator.resetTabSelectionToChat()
    }

    private var shouldShowStartupRestore: Bool {
        !isGuest && (!hasMetMinimumStartupDuration || startupViewModel.isBootstrapping)
    }

    private func beginStartupGateIfNeeded() {
        guard !hasStartedStartupGate else { return }
        hasStartedStartupGate = true

        if Self.isUITestEnvironment() {
            hasMetMinimumStartupDuration = true
            return
        }

        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                hasMetMinimumStartupDuration = true
            }
        }
    }

    // MARK: - Initialization

    init() {
        let isUITesting = Self.isUITestEnvironment()
        let environment = ProcessInfo.processInfo.environment
        AppLogger.app.logInfo("App init - UI-Testing detected: \(isUITesting)")
        self.forcedColorScheme = Self.uiTestForcedColorScheme(isUITesting: isUITesting)
        // Keep tab ordering semantic (Chat, History, Settings) independent of RTL mirroring.
        UITabBar.appearance().semanticContentAttribute = .forceLeftToRight

        // Handle test mode
        if isUITesting {
            // Check for app state reset flag
            let shouldResetAppState = environment["RESET_APP_STATE"] == "1" || environment["resetAppState"] == "1"
            
            if shouldResetAppState {
                AppLogger.app.logInfo("UI_TESTING: Resetting app state")
                // Clear UserDefaults completely for test isolation
                if let bundleID = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: bundleID)
                }
                
                // Explicitly clear session keys to ensure no stale tokens persist
                let explicitKeys = [
                    "mock_keychain_id_token",
                    "mock_keychain_refresh_token", 
                    "mock_keychain_auth_email",
                    "mock_keychain_auth_password",
                    "expires_at",
                    "is_guest",
                    "guest_session_id"
                ]
                explicitKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
                
                // Re-apply UI testing flags after reset
                UserDefaults.standard.set(true, forKey: "isUITesting")
            } else {
                // Clear only specific keys to maintain some state between tests
                let keysToClear = [
                    "mockChatResponse",
                    "mockChatError", 
                    "mockNetworkError",
                    "mockTimeoutError",
                    "mockDelay"
                ]
                for key in keysToClear {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }

            // Keep welcome flow consistent with real app
            // Session state is handled by DependencyContainer seeding
            // UserDefaults.standard.set(true, forKey: "hasSeenWelcome")

            // Set flag for CoreData to use in-memory store
            UserDefaults.standard.set(true, forKey: "isUITesting")

            // Configure network mocking based on launch environment
            Self.configureMockNetworking()
        } else {
            // Ensure no mock flags persist in normal simulator runs
            Self.clearMockNetworking()
        }

        // Initialize dependency container
        self.container = DependencyContainer.shared
        let resolvedSessionManager = container.resolve(SessionManager.self)!
        let resolvedAuthRepository = container.resolve(AuthRepository.self)!
        self.sessionManager = resolvedSessionManager
        self.authRepository = resolvedAuthRepository

        // Determine persisted auth/guest state up front so ChatSessionState and coordinator stay in sync
        let persistedGuest = resolvedSessionManager.isGuest()
        let initialAuthState = resolvedSessionManager.isLoggedIn()
        let initialGuestState = initialAuthState ? false : persistedGuest

        // Keep SessionManager's guest flag aligned with what we will render
        resolvedSessionManager.setGuest(initialGuestState)

        let shouldShowWelcome = !(initialAuthState || initialGuestState)
        let initialSelectedTab = (initialAuthState || initialGuestState) ? 0 : nil
        let chatSessionState = ChatSessionState(sessionManager: resolvedSessionManager)
        _chatSessionState = StateObject(wrappedValue: chatSessionState)
        let coordinator = AppCoordinator(
            chatSessionState: chatSessionState,
            shouldShowWelcome: shouldShowWelcome,
            initialSelectedTab: initialSelectedTab
        )
        _coordinator = StateObject(wrappedValue: coordinator)

        if isUITesting {
             // State is already determined by SessionManager (seeded or empty) logic above
             self._isAuthenticated = State(initialValue: initialAuthState)
             self._isGuest = State(initialValue: initialGuestState)
             // sessionManager.setGuest is already called above
        } else {
            self._isAuthenticated = State(initialValue: initialAuthState)
            self._isGuest = State(initialValue: initialGuestState)
            resolvedSessionManager.setGuest(initialGuestState)
        }

        _startupViewModel = StateObject(
            wrappedValue: AppStartupViewModel(
                authRepository: resolvedAuthRepository,
                sessionManager: resolvedSessionManager,
                initiallyAuthenticated: initialAuthState
            )
        )
    }

    private static func isUITestEnvironment() -> Bool {
        // Use inclusive check for any argument containing "UI-Testing"
        let argsContainFlag = CommandLine.arguments.contains { $0.contains("UI-Testing") }
        let env = ProcessInfo.processInfo.environment
        let hasXCTestConfig = env["XCTestConfigurationFilePath"] != nil
        let bundlePathContainsRunner = Bundle.main.bundlePath.contains("ShamelaGPTUITests-Runner")
        let hasUITestingEnv = env["UI_TESTING"] == "1"
        return argsContainFlag || hasXCTestConfig || bundlePathContainsRunner || hasUITestingEnv
    }

    private static func uiTestForcedColorScheme(isUITesting: Bool) -> ColorScheme? {
        guard isUITesting else { return nil }

        func map(_ raw: String) -> ColorScheme? {
            switch raw.lowercased() {
            case "dark": return .dark
            case "light": return .light
            default: return nil
            }
        }

        let env = ProcessInfo.processInfo.environment
        if let appearance = env["UITEST_APPEARANCE"], let scheme = map(appearance) {
            return scheme
        }

        let args = CommandLine.arguments
        if let idx = args.firstIndex(of: "-uiuserinterfacestyle"), idx + 1 < args.count,
           let scheme = map(args[idx + 1]) {
            return scheme
        }
        if let idx = args.firstIndex(of: "-AppleInterfaceStyle"), idx + 1 < args.count,
           let scheme = map(args[idx + 1]) {
            return scheme
        }
        return nil
    }

    private static func clearMockNetworking() {
        let mockKeys = [
            "isUITesting",
            "mockScenarioId",
            "mockChatResponse",
            "mockChatError",
            "mockNetworkError",
            "mockTimeoutError",
            "mockDelay",
            "mockChatStream",
            "mockChatStreamDelay",
            "mockHistory",
            "mockPreferences"
        ]
        for key in mockKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        AppLogger.app.logInfo("Mock networking state cleared for normal launch")
    }

    private static func configureMockNetworking() {
        // Store mock configuration in UserDefaults for MockURLProtocol to access
        let environment = ProcessInfo.processInfo.environment

        // Check for error simulation flags (supports both MOCK_ and SIMULATE_ prefixes)
        let hasNetworkError = environment["MOCK_NETWORK_ERROR"] == "1" ||
                            environment["SIMULATE_NETWORK_ERROR"] == "true" ||
                            environment["SIMULATE_NETWORK_ERROR"] == "1"

        let hasAPIError = environment["SIMULATE_API_ERROR"] == "true" ||
                         environment["SIMULATE_API_ERROR"] == "1"
        let scenarioId = environment["MOCK_SCENARIO_ID"]?.lowercased()

        // DEBUG: Log mock configuration for debugging
        AppLogger.app.logDebug("MOCK_CONFIG: hasNetworkError=\(hasNetworkError), hasAPIError=\(hasAPIError), scenario=\(scenarioId ?? "nil")")
        
        // Clear any existing mock configuration first to prevent state leakage
        let mockKeys = [
            "mockScenarioId",
            "mockChatResponse",
            "mockChatError",
            "mockNetworkError",
            "mockTimeoutError",
            "mockDelay",
            "mockChatStream",
            "mockChatStreamDelay",
            "mockHistory",
            "mockPreferences"
        ]
        for key in mockKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        AppLogger.app.logDebug("MOCK_CONFIG: Cleared existing mock configuration")

        if let scenarioId {
            applyMockScenario(id: scenarioId)
            UserDefaults.standard.set(scenarioId, forKey: "mockScenarioId")
            AppLogger.app.logDebug("MOCK_CONFIG: Applied scenario id: \(scenarioId)")
        }

        // Set default successful response if no specific mock is configured
        if environment["MOCK_CHAT_RESPONSE"] == nil &&
           environment["MOCK_CHAT_ERROR"] == nil &&
           !hasNetworkError &&
           !hasAPIError &&
           scenarioId == nil {
            // Default successful response
            let defaultResponse = """
            {
                "answer": "This is a test response from the mocked API.",
                "sources": [
                    {
                        "title": "Test Source 1",
                        "url": "https://example.com/source1",
                        "excerpt": "This is test excerpt 1"
                    },
                    {
                        "title": "Test Source 2",
                        "url": "https://example.com/source2",
                        "excerpt": "This is test excerpt 2"
                    }
                ],
                "conversation_id": "test-conversation-default",
                "thread_id": "test-thread-default"
            }
            """
            UserDefaults.standard.set(defaultResponse, forKey: "mockChatResponse")
            UserDefaults.standard.set(0.3, forKey: "mockDelay") // Short delay for tests
            AppLogger.app.logDebug("MOCK_CONFIG: Set default successful response")
        }

        // Handle network error simulation
        if hasNetworkError {
            UserDefaults.standard.set(true, forKey: "mockNetworkError")
            UserDefaults.standard.set(false, forKey: "mockTimeoutError")
            AppLogger.app.logInfo("MOCK_CONFIG: Mock network error enabled")
        } else {
            UserDefaults.standard.set(false, forKey: "mockNetworkError")
            if UserDefaults.standard.object(forKey: "mockTimeoutError") == nil {
                UserDefaults.standard.set(false, forKey: "mockTimeoutError")
            }
        }

        // Handle API error simulation
        if hasAPIError {
            let errorResponse = """
            {
                "error": "API Error",
                "message": "Simulated API error for testing"
            }
            """
            UserDefaults.standard.set(errorResponse, forKey: "mockChatError")
            AppLogger.app.logInfo("MOCK_CONFIG: Mock API error enabled")
        }

        // Handle custom mock responses
        if let mockResponse = environment["MOCK_CHAT_RESPONSE"] {
            UserDefaults.standard.set(mockResponse, forKey: "mockChatResponse")
            AppLogger.app.logDebug("MOCK_CONFIG: Set custom mock response")
        }

        if let mockError = environment["MOCK_CHAT_ERROR"] {
            UserDefaults.standard.set(mockError, forKey: "mockChatError")
            AppLogger.app.logDebug("MOCK_CONFIG: Set custom mock error")
        }

        if let delay = environment["MOCK_DELAY"], let delayValue = Double(delay) {
            UserDefaults.standard.set(delayValue, forKey: "mockDelay")
            AppLogger.app.logDebug("MOCK_CONFIG: Set mock delay: \(delayValue)")
        }

        if let streamEvents = environment["MOCK_CHAT_STREAM"] {
            UserDefaults.standard.set(streamEvents, forKey: "mockChatStream")
            AppLogger.app.logDebug("MOCK_CONFIG: Set mock chat stream events")
        }

        if let streamDelay = environment["MOCK_CHAT_STREAM_DELAY"], let streamDelayValue = Double(streamDelay) {
            UserDefaults.standard.set(streamDelayValue, forKey: "mockChatStreamDelay")
            AppLogger.app.logDebug("MOCK_CONFIG: Set mock chat stream delay: \(streamDelayValue)")
        }

        if let mockHistory = environment["MOCK_HISTORY"] {
            UserDefaults.standard.set(mockHistory, forKey: "mockHistory")
            AppLogger.app.logDebug("MOCK_CONFIG: Set mock history")
        } else {
            UserDefaults.standard.removeObject(forKey: "mockHistory")
        }

        if let mockPreferences = environment["MOCK_PREFERENCES"] {
            UserDefaults.standard.set(mockPreferences, forKey: "mockPreferences")
            AppLogger.app.logDebug("MOCK_CONFIG: Set mock preferences")
        } else {
            let defaultPreferences = """
            {
                "language_preference": "en",
                "custom_system_prompt": "Be concise.",
                "response_preferences": {
                    "length": "short",
                    "style": "academic",
                    "focus": "historical"
                }
            }
            """
            UserDefaults.standard.set(defaultPreferences, forKey: "mockPreferences")
            AppLogger.app.logDebug("MOCK_CONFIG: Set default mock preferences")
        }
        
        // Log final configuration for debugging
        let finalConfig: [String: Any] = [
            "mockNetworkError": UserDefaults.standard.bool(forKey: "mockNetworkError"),
            "mockTimeoutError": UserDefaults.standard.bool(forKey: "mockTimeoutError"),
            "mockChatError": UserDefaults.standard.string(forKey: "mockChatError") ?? "nil",
            "mockChatResponse": UserDefaults.standard.string(forKey: "mockChatResponse")?.prefix(100) ?? "nil",
            "mockDelay": UserDefaults.standard.double(forKey: "mockDelay"),
            "mockChatStream": UserDefaults.standard.string(forKey: "mockChatStream")?.prefix(100) ?? "nil",
            "mockChatStreamDelay": UserDefaults.standard.double(forKey: "mockChatStreamDelay"),
            "mockHistory": UserDefaults.standard.string(forKey: "mockHistory")?.prefix(100) ?? "nil",
            "mockPreferences": UserDefaults.standard.string(forKey: "mockPreferences")?.prefix(100) ?? "nil"
        ]
        AppLogger.app.logDebug("MOCK_CONFIG: Final configuration: \(finalConfig)")
    }

    private static func applyMockScenario(id: String) {
        let code: Int?
        switch id {
        case "success":
            code = nil
        case "http_400":
            code = 400
        case "http_401":
            code = 401
        case "http_403":
            code = 403
        case "http_404":
            code = 404
        case "http_429":
            code = 429
        case "http_500":
            code = 500
        case "timeout":
            UserDefaults.standard.set(true, forKey: "mockTimeoutError")
            return
        case "offline":
            UserDefaults.standard.set(true, forKey: "mockNetworkError")
            UserDefaults.standard.set(false, forKey: "mockTimeoutError")
            return
        default:
            AppLogger.app.logWarning("MOCK_CONFIG: Unknown scenario id: \(id)")
            return
        }

        guard let code else { return }
        let errorPayload = """
        {"error":"Scenario \(id)","status_code":\(code)}
        """
        UserDefaults.standard.set(errorPayload, forKey: "mockChatError")
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ZStack {
                if shouldShowStartupRestore {
                    StartupRestoreView()
                        .transition(.opacity)
                        .zIndex(2)
                } else if coordinator.shouldShowWelcome && !isAuthenticated && !isGuest {
                    // Determine which view to show
                    WelcomeView(
                        onGetStarted: {
                            coordinator.dismissWelcome()
                            // coordinator.dismissWelcome() already sets flag, view will recompose
                            // If user was not authenticated, they will see AuthView next
                        },
                        onSkipToChat: {
                            // Enable guest mode and dismiss welcome
                            isGuest = true
                            self.sessionManager.setGuest(true)
                            chatSessionState.resetToNew()
                            coordinator.dismissWelcome()
                        }
                    )
                    .transition(.opacity)
                    .zIndex(1)
                } else if isAuthenticated || isGuest {
                    // Main tab view
                    MainTabView(
                        coordinator: coordinator,
                        chatSessionState: chatSessionState,
                        container: container,
                        isAuthenticated: isAuthenticated,
                        isGuest: isGuest,
                        onLogout: {
                            authRepository.logout()
                            isAuthenticated = false
                            isGuest = false
                            self.sessionManager.setGuest(false)
                            chatSessionState.resetToNew()
                            coordinator.shouldShowWelcome = true
                            coordinator.resetTabSelectionToChat()
                        },
                        onRequireAuth: {
                            presentAuth()
                        }
                    )
                } else {
                    // Auth overlay
                    AuthView(
                        viewModel: AuthViewModel(authRepository: authRepository),
                        onAuthenticated: {
                            isAuthenticated = true
                            self.sessionManager.setGuest(false)
                            chatSessionState.refreshFromStorage()
                            coordinator.shouldShowWelcome = false
                            coordinator.resetTabSelectionToChat()
                            coordinator.start()
                        },
                        onContinueAsGuest: {
                            isGuest = true
                            self.sessionManager.setGuest(true)
                            chatSessionState.resetToNew()
                            coordinator.shouldShowWelcome = false
                            coordinator.resetTabSelectionToChat()
                            coordinator.start()
                        }
                    )
                }
            }
            .overlay(alignment: .topLeading) {
                if Self.isUITestEnvironment() {
                    Text(" ")
                        .font(.system(size: 1))
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .allowsHitTesting(false)
                        .accessibilityIdentifier(AccessibilityID.Debug.languageProbe(languageManager.currentLanguage.rawValue))
                        .accessibilityLabel(languageManager.currentLanguage.rawValue)
                }
            }
            .id(languageManager.currentLanguage.rawValue)
            .preferredColorScheme(forcedColorScheme)
            .environment(\.locale, Locale(identifier: languageManager.currentLanguage.localeIdentifier))
            .environment(
                \.layoutDirection,
                (languageManager.currentLanguage == .arabic || languageManager.currentLanguage == .urdu) ? .rightToLeft : .leftToRight
            )
            .onOpenURL { url in
                // Handle deep links (custom URL schemes / onOpenURL)
                _ = coordinator.handleDeepLink(url)
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                // Handle universal links (browsing web activity)
                if let url = activity.webpageURL {
                    _ = coordinator.handleDeepLink(url)
                }
            }
            .onAppear {
                if !isGuest {
                    beginStartupGateIfNeeded()
                    startupViewModel.bootstrap()
                }
                coordinator.start()
                shakeDetector.onShake = { showFeedbackPrompt = true }
                shakeDetector.start()
            }
            .onChange(of: startupViewModel.isBootstrapping) { doneBootstrapping in
                guard !doneBootstrapping else { return }
                guard !isGuest else { return }
                if startupViewModel.isAuthenticated {
                    isAuthenticated = true
                    isGuest = false
                    self.sessionManager.setGuest(false)
                    chatSessionState.refreshFromStorage()
                    coordinator.shouldShowWelcome = false
                    coordinator.resetTabSelectionToChat()
                } else if !isGuest {
                    isAuthenticated = false
                    coordinator.shouldShowWelcome = true
                    coordinator.resetTabSelectionToChat()
                }
            }
            .onDisappear {
                shakeDetector.stop()
            }
            .alert(LocalizationKeys.feedbackPromptTitle.localizedKey, isPresented: $showFeedbackPrompt) {
                Button(LocalizationKeys.feedbackSend.localizedKey, role: .none) {
                    openFeedbackEmail()
                }
                Button(LocalizationKeys.cancel.localizedKey, role: .cancel) { }
            } message: {
                Text(LocalizationKeys.feedbackPromptMessage.localizedKey)
            }
        }
    }

    private func openFeedbackEmail() {
        let subjectRaw = LanguageManager.shared.localizedString(forKey: LocalizationKeys.feedbackEmailSubject)
        let device = UIDevice.current
        let body = """
        Please describe your feedback above this line.

        ---
        Debug Info:
        App Version: \(Bundle.main.appVersionString)
        Device: \(device.model) (\(device.systemName) \(device.systemVersion))
        Locale: \(Locale.current.identifier)
        App Language: \(LanguageManager.shared.currentLanguage.rawValue)
        Session: \(isAuthenticated ? "authenticated" : (isGuest ? "guest" : "unauthenticated"))
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "contact@creatrixe.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: subjectRaw),
            URLQueryItem(name: "body", value: body)
        ]

        guard let mailURL = components.url else {
            AppLogger.app.logWarning("Failed to compose feedback mailto URL")
            return
        }
        UIApplication.shared.open(mailURL)
    }
}
