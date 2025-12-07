//
//  ShamelaGPTApp.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 04/11/2025.
//

import SwiftUI

@main
struct ShamelaGPTApp: App {
    // MARK: - Properties

    /// App coordinator for navigation management
    @StateObject private var coordinator: AppCoordinator

    /// Dependency container
    private let container: DependencyContainer
    private let sessionManager: SessionManager
    private let authRepository: AuthRepository

    @State private var isAuthenticated: Bool
    @State private var isGuest: Bool = false
    
    private func presentAuth() {
        isAuthenticated = false
        isGuest = false
        self.sessionManager.setGuest(false)
        coordinator.shouldShowWelcome = false
        coordinator.resetTabSelectionToChat()
    }

    // MARK: - Initialization

    init() {
        let isUITesting = Self.isUITestEnvironment()
        let env = ProcessInfo.processInfo.environment
        AppLogger.app.logInfo("App init - UI-Testing detected: \(isUITesting)")

        // Handle test mode
        if isUITesting {
            // Clear UserDefaults for test isolation
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }

            // Keep welcome flow consistent with real app
            UserDefaults.standard.set(false, forKey: "hasSeenWelcome")

            // Set flag for CoreData to use in-memory store
            UserDefaults.standard.set(true, forKey: "isUITesting")

            // Configure network mocking based on launch environment
            Self.configureMockNetworking()
        }

        // Initialize coordinator after defaults are set
        _coordinator = StateObject(wrappedValue: AppCoordinator())

        // Initialize dependency container
        self.container = DependencyContainer.shared
        self.sessionManager = container.resolve(SessionManager.self)!
        self.authRepository = container.resolve(AuthRepository.self)!

        let initialAuthState = sessionManager.isLoggedIn()
        if isUITesting {
            self._isAuthenticated = State(initialValue: true)
            self._isGuest = State(initialValue: true)
            self.sessionManager.setGuest(true)
        } else {
            self._isAuthenticated = State(initialValue: initialAuthState)
            self._isGuest = State(initialValue: false)
            self.sessionManager.setGuest(false)
        }
        
        // Drive welcome visibility from auth state
        if initialAuthState {
            _coordinator.wrappedValue.shouldShowWelcome = false
            _coordinator.wrappedValue.resetTabSelectionToChat()
        } else if !isUITesting {
            _coordinator.wrappedValue.shouldShowWelcome = true
        }
    }

    /// Detects whether the app is running under UI tests (arguments, env, or runner bundle path)
    private static func isUITestEnvironment() -> Bool {
        let argsContainFlag = CommandLine.arguments.contains("UI-Testing")
        let env = ProcessInfo.processInfo.environment
        let hasXCTestConfig = env["XCTestConfigurationFilePath"] != nil
        let bundlePathContainsRunner = Bundle.main.bundlePath.contains("ShamelaGPTUITests-Runner")
        let hasUITestingEnv = env["UI_TESTING"] == "1"
        return argsContainFlag || hasXCTestConfig || bundlePathContainsRunner || hasUITestingEnv
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

        // Set default successful response if no specific mock is configured
        if environment["MOCK_CHAT_RESPONSE"] == nil &&
           environment["MOCK_CHAT_ERROR"] == nil &&
           !hasNetworkError &&
           !hasAPIError {
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
        }

        // Handle network error simulation
        if hasNetworkError {
            UserDefaults.standard.set(true, forKey: "mockNetworkError")
            // Clear any success responses when simulating errors
            UserDefaults.standard.removeObject(forKey: "mockChatResponse")
            AppLogger.app.logInfo("Mock network error enabled")
        } else {
            UserDefaults.standard.set(false, forKey: "mockNetworkError")
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
            // Clear any success responses when simulating errors
            UserDefaults.standard.removeObject(forKey: "mockChatResponse")
            AppLogger.app.logInfo("Mock API error enabled")
        }

        // Handle custom mock responses
        if let mockResponse = environment["MOCK_CHAT_RESPONSE"] {
            UserDefaults.standard.set(mockResponse, forKey: "mockChatResponse")
        }

        if let mockError = environment["MOCK_CHAT_ERROR"] {
            UserDefaults.standard.set(mockError, forKey: "mockChatError")
        }

        if let delay = environment["MOCK_DELAY"], let delayValue = Double(delay) {
            UserDefaults.standard.set(delayValue, forKey: "mockDelay")
        }
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Determine which view to show
                if coordinator.shouldShowWelcome && !isAuthenticated && !isGuest {
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
                            coordinator.dismissWelcome()
                        }
                    )
                    .transition(.opacity)
                    .zIndex(1)
                } else if isAuthenticated || isGuest {
                    // Main tab view
                    MainTabView(
                        coordinator: coordinator,
                        container: container,
                        isAuthenticated: isAuthenticated,
                        isGuest: isGuest,
                        onLogout: {
                            authRepository.logout()
                            isAuthenticated = false
                            isGuest = false
                            self.sessionManager.setGuest(false)
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
                            coordinator.shouldShowWelcome = false
                            coordinator.resetTabSelectionToChat()
                            coordinator.start()
                        },
                        onContinueAsGuest: {
                            isGuest = true
                            self.sessionManager.setGuest(true)
                            coordinator.shouldShowWelcome = false
                            coordinator.resetTabSelectionToChat()
                            coordinator.start()
                        }
                    )
                }
            }
            .preferredColorScheme(.none) // Support both light and dark mode
            .onOpenURL { url in
                // Handle deep links
                _ = coordinator.handleDeepLink(url)
            }
            .onAppear {
                coordinator.start()
            }
        }
    }
}
