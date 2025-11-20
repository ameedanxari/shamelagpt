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
        let apiClient: APIClientProtocol = APIClient()
        register(APIClientProtocol.self, instance: apiClient)
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
        return ChatViewModel(
            conversationId: conversationId,
            sendMessageUseCase: resolve(SendMessageUseCase.self)!,
            chatRepository: resolve(ChatRepository.self)!,
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
