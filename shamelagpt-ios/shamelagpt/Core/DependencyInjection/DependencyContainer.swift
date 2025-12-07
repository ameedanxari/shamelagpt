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
        let isUITesting = UserDefaults.standard.bool(forKey: "isUITesting")

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
        let sessionManager = SessionManager()
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

        if isUITesting {
            // Create a URLSession with mock protocol for testing
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let mockSession = URLSession(configuration: configuration)
            AppLogger.network.logInfo("Using MockURLProtocol for URLSession")
            apiClient = APIClient(
                session: mockSession,
                authTokenProvider: { self.resolve(SessionManager.self)?.token() }
            )
        } else {
            apiClient = APIClient(
                authTokenProvider: { self.resolve(SessionManager.self)?.token() }
            )
        }
        register(APIClientProtocol.self, instance: apiClient)
    }

    /// Detects UI test environment (arguments, env, or runner bundle path)
    private static func isUITestEnvironment() -> Bool {
        let argsContainFlag = CommandLine.arguments.contains("UI-Testing")
        let env = ProcessInfo.processInfo.environment
        let hasXCTestConfig = env["XCTestConfigurationFilePath"] != nil
        let bundlePathContainsRunner = Bundle.main.bundlePath.contains("ShamelaGPTUITests-Runner")
        let hasUITestingEnv = env["UI_TESTING"] == "1"
        return argsContainFlag || hasXCTestConfig || bundlePathContainsRunner || hasUITestingEnv || UserDefaults.standard.bool(forKey: "isUITesting")
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
    func makeChatViewModel(conversationId: String) -> ChatViewModel {
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
            ocrManager: OCRManager()
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
