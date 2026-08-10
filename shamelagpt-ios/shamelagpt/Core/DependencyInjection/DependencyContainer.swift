//
//  DependencyContainer.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 04/11/2025.
//

import Foundation
// TODO: Add Swinject package dependency from https://github.com/Swinject/Swinject
// import Swinject

/// Main dependency injection container for the app
/// This is a simple implementation. Once Swinject is added, uncomment the Swinject code
class DependencyContainer {
    static let shared = DependencyContainer()

    // Simple dictionary-based DI (replace with Swinject Container later)
    private var services: [String: Any] = [:]

    private init() {
        registerDependencies()
    }

    private func registerDependencies() {
        _ = UserDefaults.standard.bool(forKey: "isUITesting")

        // MARK: - Core Layer
        registerCore()

        // MARK: - Data Layer
        registerDataLayer()

        // MARK: - Domain Layer
        registerDomainLayer()

        // MARK: - Presentation Layer
        registerPresentationLayer()
    }

    private func registerCore() {
        // Core Data Stack
        let coreDataStack = CoreDataStack.shared
        register(CoreDataStack.self, instance: coreDataStack)

        // Session Manager
        // Session Manager
        let isUITesting = Self.isUITestEnvironment()
        let sessionManager = SessionManager(useKeychain: !isUITesting)
        AppLogger.app.logInfo("DependencyContainer.registerCore - SessionManager initialized (useKeychain: \(!isUITesting))")
        
        // In UI Testing, properly mock/seed the session state
        // This avoids having test-specific logic in the main App struct
        if Self.isUITestEnvironment() {
            let env = ProcessInfo.processInfo.environment
            let forceAuthScreen = env["FORCE_AUTH_SCREEN"] == "1" || env["FORCE_AUTH_SCREEN"]?.lowercased() == "true"
            // Default to true for backward compatibility with tests that expect to be logged in
            // unless explicitly set to 0/false (or if we are testing authentication flow)
            let shouldSkipWelcome = env["SKIP_WELCOME"] == "1" || env["SKIP_WELCOME"]?.lowercased() == "true"
            
            if forceAuthScreen {
                AppLogger.app.logInfo("DependencyContainer - UI Test: Forcing auth screen (clearing session)")
                sessionManager.clearSession()
                sessionManager.setGuest(false)
            } else if shouldSkipWelcome {
                AppLogger.app.logInfo("DependencyContainer - UI Test: Seeding authenticated session")
                sessionManager.saveSession(
                    token: "mock_test_token",
                    refreshToken: "mock_refresh_token",
                    expiresInSeconds: 3600
                )
                sessionManager.setGuest(false)
            } else {
                AppLogger.app.logInfo("DependencyContainer - UI Test: Clearing session for Welcome/Auth flow")
                sessionManager.clearSession()
                sessionManager.setGuest(false)
            }
        }
        
        register(SessionManager.self, instance: sessionManager)

        // Network Layer
        registerNetworkLayer()

        // Utilities
        registerUtilities()
    }

    private func registerUtilities() {
        // Voice Input Manager and OCR Manager are created on demand
        // since they are @MainActor isolated
        // They will be created in the factory methods
    }

    private func registerNetworkLayer() {
        // Network Monitor
        let networkMonitor = NetworkMonitor.shared
        register(NetworkMonitor.self, instance: networkMonitor)

        // API Client
        // In UI testing mode, use a mock URLSession
        let apiClient: APIClientProtocol
        let isUITesting = Self.isUITestEnvironment()
        AppLogger.network.logInfo("DependencyContainer.registerNetworkLayer - isUITesting: \(isUITesting)")

        // Base URL must match APIClient's own default so the refresh call lands on the
        // same host as everything else.
        let baseURL = URL(string: "https://shamelagpt.com")!

        if isUITesting {
            // Create a URLSession with mock protocol for testing
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let mockSession = URLSession(configuration: configuration)
            AppLogger.network.logInfo("Using MockURLProtocol for URLSession")
            apiClient = APIClient(
                session: mockSession,
                tokenProvider: sessionManagerBackedTokenProvider(baseURL: baseURL, session: mockSession)
            )
        } else {
            apiClient = APIClient(
                tokenProvider: sessionManagerBackedTokenProvider(baseURL: baseURL, session: .shared)
            )
        }
        register(APIClientProtocol.self, instance: apiClient)
    }

    /// Builds the token provider backed by the registered `SessionManager`.
    ///
    /// Falls back to a non-refreshing provider if the session manager is somehow missing,
    /// so a DI ordering mistake degrades to the old behaviour rather than crashing.
    private func sessionManagerBackedTokenProvider(
        baseURL: URL,
        session: URLSession
    ) -> AuthTokenProviding {
        guard let sessionManager = resolve(SessionManager.self) else {
            AppLogger.network.logWarning("SessionManager unavailable - token refresh disabled")
            return StaticTokenProvider { nil }
        }
        return SessionTokenProvider(
            sessionManager: sessionManager,
            baseURL: baseURL,
            session: session
        )
    }

    /// Detects UI test environment (arguments, env, or runner bundle path)
    private static func isUITestEnvironment() -> Bool {
        let argsContainFlag = CommandLine.arguments.contains("UI-Testing") || CommandLine.arguments.contains("-UI-Testing")
        let env = ProcessInfo.processInfo.environment
        let hasXCTestConfig = env["XCTestConfigurationFilePath"] != nil
        let bundlePathContainsRunner = Bundle.main.bundlePath.contains("ShamelaGPTUITests-Runner")
        let hasUITestingEnv = env["UI_TESTING"] == "1"
        return argsContainFlag || hasXCTestConfig || bundlePathContainsRunner || hasUITestingEnv
    }

    private func registerDataLayer() {
        // Data Access Objects
        let conversationDAO = ConversationDAO(coreDataStack: resolve(CoreDataStack.self)!)
        let messageDAO = MessageDAO(coreDataStack: resolve(CoreDataStack.self)!)
        register(ConversationDAO.self, instance: conversationDAO)
        register(MessageDAO.self, instance: messageDAO)

        // Repositories
        let chatRepository: ChatRepository = ChatRepositoryImpl(
            coreDataStack: resolve(CoreDataStack.self)!,
            conversationDAO: conversationDAO,
            messageDAO: messageDAO,
            apiClient: resolve(APIClientProtocol.self),
            networkMonitor: resolve(NetworkMonitor.self)
        )
        register(ChatRepository.self, instance: chatRepository)

        // Auth Repository
        if let apiClient = resolve(APIClientProtocol.self), let sessionManager = resolve(SessionManager.self) {
            let authRepository = AuthRepositoryImpl(
                apiClient: apiClient,
                sessionManager: sessionManager
            )
            register(AuthRepository.self, instance: authRepository)
        }

        // Preferences Repository
        if let apiClient = resolve(APIClientProtocol.self) {
            let preferencesRepo = PreferencesRepositoryImpl(apiClient: apiClient)
            register(PreferencesRepository.self, instance: preferencesRepo)
        }
    }

    private func registerDomainLayer() {
        // Use Cases
        let sendMessageUseCase = SendMessageUseCase(
            chatRepository: resolve(ChatRepository.self)!,
            apiClient: resolve(APIClientProtocol.self)!,
            networkMonitor: resolve(NetworkMonitor.self)!
        )
        register(SendMessageUseCase.self, instance: sendMessageUseCase)

        let getConversationsUseCase = GetConversationsUseCase(
            chatRepository: resolve(ChatRepository.self)!
        )
        register(GetConversationsUseCase.self, instance: getConversationsUseCase)

        let deleteConversationUseCase = DeleteConversationUseCase(
            chatRepository: resolve(ChatRepository.self)!
        )
        register(DeleteConversationUseCase.self, instance: deleteConversationUseCase)
    }

    private func registerPresentationLayer() {
        // ViewModels are created on demand via factory methods
        // since they require specific parameters like conversationId
    }

    /// Factory method to create a ChatViewModel for a specific conversation
    @MainActor
    func makeChatViewModel(
        conversationId: String?,
        onConversationChange: ((String?) -> Void)? = nil
    ) -> ChatViewModel {
        let sessionManager = resolve(SessionManager.self)
        let guestSessionId = sessionManager?.getOrCreateGuestSessionId()
        return ChatViewModel(
            conversationId: conversationId,
            sendMessageUseCase: resolve(SendMessageUseCase.self)!,
            chatRepository: resolve(ChatRepository.self)!,
            apiClient: resolve(APIClientProtocol.self),
            isGuest: sessionManager?.isGuest() ?? false,
            guestSessionId: guestSessionId,
            voiceInputManager: VoiceInputManager(),
            ocrManager: OCRManager(),
            onConversationIdChange: onConversationChange
        )
    }

    /// Factory method to create a HistoryViewModel
    @MainActor
    func makeHistoryViewModel() -> HistoryViewModel {
        return HistoryViewModel(
            getConversationsUseCase: resolve(GetConversationsUseCase.self)!,
            deleteConversationUseCase: resolve(DeleteConversationUseCase.self)!,
            chatRepository: resolve(ChatRepository.self)!
        )
    }

    /// Registers a service in the container
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        services[key] = instance
    }

    /// Resolves a dependency from the container
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return services[key] as? T
    }
}
