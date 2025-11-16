//
//  ChatRepositoryImpl.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import CoreData
import Combine

/// Implementation of ChatRepository using Core Data
final class ChatRepositoryImpl: ChatRepository, @unchecked Sendable {

    // MARK: - Properties
    private let coreDataStack: CoreDataStackProtocol
    private let conversationDAO: ConversationDAO
    private let messageDAO: MessageDAO
    private let apiClient: APIClientProtocol?
    private let networkMonitor: NetworkMonitorProtocol?
    private let freshnessStore: ConversationSyncFreshnessStore

    private let conversationsSubject = CurrentValueSubject<[Conversation], Never>([])

    private func parseRemoteDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    // MARK: - Initialization
    init(
        coreDataStack: CoreDataStackProtocol = CoreDataStack.shared,
        conversationDAO: ConversationDAO = ConversationDAO(),
        messageDAO: MessageDAO = MessageDAO(),
        apiClient: APIClientProtocol? = nil,
        networkMonitor: NetworkMonitorProtocol? = nil,
        freshnessStore: ConversationSyncFreshnessStore = ConversationSyncFreshnessStore()
    ) {
        self.coreDataStack = coreDataStack
        self.conversationDAO = conversationDAO
        self.messageDAO = messageDAO
        self.apiClient = apiClient
        self.networkMonitor = networkMonitor
        self.freshnessStore = freshnessStore
    }

    // MARK: - Conversation Operations

    func createConversation(title: String, isLocalOnly: Bool = false) async throws -> Conversation {
        let context = coreDataStack.viewContext
        var remoteConversation: ConversationResponse?

        // Do not call remote API when conversation is marked local-only
        if !isLocalOnly,
           let apiClient = apiClient,
           let networkMonitor = networkMonitor,
           networkMonitor.isConnected {
            remoteConversation = try? await apiClient.createConversation(
                ConversationRequest(title: title)
            )
        }
        return try await context.perform {
            let id = remoteConversation?.id ?? UUID().uuidString
            let entity = self.conversationDAO.create(
                id: id,
                threadId: remoteConversation?.threadId,
                title: remoteConversation?.title ?? title,
                isLocalOnly: isLocalOnly,
                in: context
            )

            if let remote = remoteConversation {
                if let createdAt = self.parseRemoteDate(remote.createdAt) {
                    entity.createdAt = createdAt
                }
                if let updatedAt = self.parseRemoteDate(remote.updatedAt) {
                    entity.updatedAt = updatedAt
                }
            }

            try self.coreDataStack.save(context: context)

            let conversation = ConversationMapper.toDomainModel(entity)
            AppLogger.database.logInfo("Created conversation \(conversation.id) threadId:\(conversation.threadId ?? "nil") localOnly:\(conversation.isLocalOnly)")
            self.notifyConversationsChanged()
            return conversation
        }
    }

    func fetchAllConversations() async throws -> [Conversation] {
        let context = coreDataStack.viewContext

        return try await context.perform { [conversationDAO] in
            let entities = try conversationDAO.fetchAll(from: context)
            // Include messages so history and previews reflect accurate counts/content
            return ConversationMapper.toDomainModels(entities, includeMessages: true)
        }
    }

    func fetchConversation(byId id: String) async throws -> Conversation? {
        AppLogger.database.logDebug("Fetching conversation by ID: \(id)")
        let context = coreDataStack.viewContext

        return try await context.perform { [conversationDAO] in
            guard let entity = try conversationDAO.fetch(byId: id, from: context) else {
                AppLogger.database.logWarning("Conversation not found in database: \(id)")
                return nil
            }
            let domain = ConversationMapper.toDomainModel(entity, includeMessages: true)
            AppLogger.database.logDebug("Conversation found: \(domain.id) threadId:\(domain.threadId ?? "nil") localOnly:\(domain.isLocalOnly) messages:\(domain.messageCount)")
            return domain
        }
    }

    func fetchConversation(byThreadId threadId: String) async throws -> Conversation? {
        let context = coreDataStack.viewContext

        return try await context.perform { [conversationDAO] in
            guard let entity = try conversationDAO.fetch(byThreadId: threadId, from: context) else {
                return nil
            }
            return ConversationMapper.toDomainModel(entity, includeMessages: true)
        }
    }

    func fetchMostRecentEmptyConversation(includeLocalOnly: Bool = false) async throws -> Conversation? {
        AppLogger.database.logDebug("Fetching most recent empty conversation (includeLocalOnly=\(includeLocalOnly))")
        let context = coreDataStack.viewContext

        return try await context.perform { [conversationDAO] in
            guard let entity = try conversationDAO.fetchMostRecentEmpty(from: context, includeLocalOnly: includeLocalOnly) else {
                AppLogger.database.logInfo("No empty conversations found")
                return nil
            }
            AppLogger.database.logInfo("Found empty conversation: \(entity.id ?? "unknown")")
            return ConversationMapper.toDomainModel(entity, includeMessages: false)
        }
    }

    func updateConversationTitle(id: String, title: String) async throws {
        let context = coreDataStack.viewContext

        try await context.perform { [conversationDAO, coreDataStack] in
            guard let entity = try conversationDAO.fetch(byId: id, from: context) else {
                throw CoreDataError.notFound
            }

            conversationDAO.updateTitle(entity, title: title)
            try coreDataStack.save(context: context)
            self.notifyConversationsChanged()
        }
    }

    func updateConversationThreadId(id: String, threadId: String) async throws {
        let context = coreDataStack.viewContext

        try await context.perform { [conversationDAO, coreDataStack] in
            guard let entity = try conversationDAO.fetch(byId: id, from: context) else {
                throw CoreDataError.notFound
            }

            conversationDAO.updateThreadId(entity, threadId: threadId)
            try coreDataStack.save(context: context)
            AppLogger.database.logInfo("Updated conversation \(id) threadId to \(threadId)")
        }
    }

    func deleteConversation(id: String) async throws {
        let context = coreDataStack.viewContext

        try await context.perform { [conversationDAO, coreDataStack] in
            try conversationDAO.delete(byId: id, from: context)
            try coreDataStack.save(context: context)
            self.notifyConversationsChanged()
        }

        // Propagate delete to server when authenticated
        if let apiClient = apiClient,
           let networkMonitor = networkMonitor,
           networkMonitor.isConnected {
            _ = try? await apiClient.deleteConversation(id: id)
        }
    }

    func deleteAllConversations() async throws {
        let context = coreDataStack.viewContext

        try await context.perform { [conversationDAO, coreDataStack] in
            try conversationDAO.deleteAll(from: context)
            try coreDataStack.save(context: context)
            self.notifyConversationsChanged()
        }

        if let apiClient = apiClient,
           let networkMonitor = networkMonitor,
           networkMonitor.isConnected {
            _ = try? await apiClient.deleteAllConversations()
        }
    }

    func syncRemoteConversations(forceRefresh: Bool = false) async throws {
        guard let apiClient = apiClient,
              let networkMonitor = networkMonitor,
              networkMonitor.isConnected else { return }
        guard freshnessStore.shouldSyncConversations(forceRefresh: forceRefresh) else {
            return
        }

        let remoteConversations = try await apiClient.listConversations()
        let context = coreDataStack.viewContext

        try await context.perform { [conversationDAO, coreDataStack] in
            for remote in remoteConversations {
                // Upsert conversation using server id
                let entity = conversationDAO.upsert(
                    id: remote.id,
                    threadId: remote.threadId,
                    title: remote.title ?? "New Chat",
                    createdAt: self.parseRemoteDate(remote.createdAt) ?? Date(),
                    updatedAt: self.parseRemoteDate(remote.updatedAt) ?? Date(),
                    in: context
                )
                conversationDAO.markAsUpdated(entity)
            }
            try coreDataStack.save(context: context)
        }

        notifyConversationsChanged()
        freshnessStore.markConversationsSynced()

        // Hydrate messages for server conversations that are empty locally
        for remote in remoteConversations {
            do {
                if let local = try await fetchConversation(byId: remote.id), !local.messages.isEmpty {
                    continue
                }
                _ = try await fetchMessages(forConversation: remote.id, forceRefresh: forceRefresh)
            } catch {
                AppLogger.network.logWarning("Failed to hydrate messages for conversation \(remote.id): \(error)")
            }
        }
    }

    // MARK: - Message Operations

    func addMessage(
        toConversation conversationId: String,
        content: String,
        isUserMessage: Bool,
        sources: [Source]
    ) async throws -> Message {
        let context = coreDataStack.viewContext

        return try await context.perform { [conversationDAO, messageDAO, coreDataStack, self] in
            guard let conversationEntity = try conversationDAO.fetch(
                byId: conversationId,
                from: context
            ) else {
                throw CoreDataError.notFound
            }

            let id = UUID().uuidString
            let timestamp = Date()
            let sourcesJSON = MessageMapper.sourcesToJSON(sources)

            let entity = messageDAO.create(
                id: id,
                conversationId: conversationId,
                content: content,
                isUserMessage: isUserMessage,
                timestamp: timestamp,
                sources: sourcesJSON,
                conversation: conversationEntity,
                in: context
            )

            // Update conversation's updatedAt timestamp
            conversationDAO.markAsUpdated(conversationEntity)

            try coreDataStack.save(context: context)

            self.notifyConversationsChanged()
            return MessageMapper.toDomainModel(entity)
        }
    }

    func addFactCheckMessage(
        toConversation conversationId: String,
        content: String,
        isUserMessage: Bool,
        sources: [Source],
        imageData: Data?,
        detectedLanguage: String?,
        isFactCheckMessage: Bool
    ) async throws -> Message {
        let context = coreDataStack.viewContext

        return try await context.perform {
            guard let conversationEntity = try self.conversationDAO.fetch(
                byId: conversationId,
                from: context
            ) else {
                throw CoreDataError.notFound
            }

            let id = UUID().uuidString
            let timestamp = Date()
            let sourcesJSON = MessageMapper.sourcesToJSON(sources)

            let entity = self.messageDAO.create(
                id: id,
                conversationId: conversationId,
                content: content,
                isUserMessage: isUserMessage,
                timestamp: timestamp,
                sources: sourcesJSON,
                imageData: imageData,
                detectedLanguage: detectedLanguage,
                isFactCheckMessage: isFactCheckMessage,
                conversation: conversationEntity,
                in: context
            )

            // Ensure history can reliably label this conversation as fact-check.
            if isFactCheckMessage {
                conversationEntity.conversationType = ConversationType.factCheck.rawValue
            }

            // Update conversation's updatedAt timestamp
            self.conversationDAO.markAsUpdated(conversationEntity)

            try self.coreDataStack.save(context: context)

            self.notifyConversationsChanged()
            return MessageMapper.toDomainModel(entity)
        }
    }

    func fetchMessages(forConversation conversationId: String, forceRefresh: Bool = false) async throws -> [Message] {
        let context = coreDataStack.viewContext

        // First fetch locally
        let localMessages: [Message] = try await context.perform { [messageDAO] in
            let entities = try messageDAO.fetchAll(
                forConversationId: conversationId,
                from: context
            )
            let messages = MessageMapper.toDomainModels(entities)
            AppLogger.database.logDebug("Fetched messages from DB for conversation \(conversationId) - count: \(messages.count) ids: \(messages.map { $0.id })")
            return messages
        }

        // Fast path: if cache is fresh and not forced, keep local.
        let shouldSyncRemote = freshnessStore.shouldSyncMessages(
            conversationId: conversationId,
            forceRefresh: forceRefresh
        )
        if !shouldSyncRemote {
            return localMessages
        }

        // No network/API available, return local cache.
        guard let apiClient = apiClient,
              let networkMonitor = networkMonitor,
              networkMonitor.isConnected else {
            return localMessages
        }

        AppLogger.network.logInfo("Fetching remote messages for conversation \(conversationId)")
        do {
            let remoteResponse = try await apiClient.getMessages(conversationId: conversationId)
            AppLogger.network.logDebug("Remote messages received: \(remoteResponse.messages.count) for conversation \(conversationId) (response conversationId=\(remoteResponse.conversationId ?? "nil"))")

            // Persist remote messages locally for resume
            for msg in remoteResponse.messages {
                guard let content = msg.content, let role = msg.role else {
                    AppLogger.network.logWarning("Skipping remote message with missing content/role: \(msg)")
                    continue
                }
                let roleLower = role.lowercased()
                let isUser = roleLower == "user" || roleLower == "human"
                let parsed = ResponseParser.parseMarkdownResponse(content)

                // Persist raw content; extract sources for UI but avoid mutating payload
                _ = try? await addMessage(
                    toConversation: conversationId,
                    content: content,
                    isUserMessage: isUser,
                    sources: isUser ? [] : parsed.sources
                )
            }

            freshnessStore.markMessagesSynced(conversationId: conversationId)

            // Re-fetch now that we've hydrated
            return try await context.perform { [messageDAO] in
                let entities = try messageDAO.fetchAll(
                    forConversationId: conversationId,
                    from: context
                )
                let messages = MessageMapper.toDomainModels(entities)
                AppLogger.database.logDebug("Hydrated remote messages for conversation \(conversationId) - count: \(messages.count)")
                return messages
            }
        } catch {
            AppLogger.network.logError("Failed to fetch remote messages for conversation \(conversationId)", error: error)
            return localMessages
        }
    }

    func updateMessageContent(id: String, content: String) async throws {
        let context = coreDataStack.viewContext

        try await context.perform { [messageDAO, coreDataStack] in
            guard let entity = try messageDAO.fetch(byId: id, from: context) else {
                throw CoreDataError.notFound
            }

            messageDAO.updateContent(entity, content: content)
            try coreDataStack.save(context: context)
        }
    }

    func deleteMessage(id: String) async throws {
        let context = coreDataStack.viewContext

        try await context.perform { [messageDAO, coreDataStack] in
            try messageDAO.delete(byId: id, from: context)
            try coreDataStack.save(context: context)
        }
    }

    // MARK: - API Integration

    /// Sends a message to the API and saves the response
    /// - Parameters:
    ///   - conversationId: The conversation ID
    ///   - message: The user's message
    /// - Returns: Tuple of (user message, assistant message)
    /// - Throws: NetworkError or repository errors
    func sendMessageToAPI(
        conversationId: String,
        message: String
    ) async throws -> (userMessage: Message, assistantMessage: Message) {
        // Check network connectivity
        guard let networkMonitor = networkMonitor, networkMonitor.isConnected else {
            throw NetworkError.noConnection
        }

        guard let apiClient = apiClient else {
            throw NetworkError.unknown(NSError(
                domain: "ChatRepository",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "API client not configured"]
            ))
        }

        // Fetch the conversation to get thread ID
        guard let conversation = try await fetchConversation(byId: conversationId) else {
            throw ChatRepositoryError.conversationNotFound
        }

        // Save user message locally first
        let userMessage = try await addMessage(
            toConversation: conversationId,
            content: message,
            isUserMessage: true,
            sources: []
        )

        do {
            // Send message to API
            let request = ChatRequest(
                question: message,
                threadId: conversation.threadId,
                languagePreference: LanguageManager.shared.currentLanguage.rawValue
            )

            let response = try await apiClient.sendMessage(request)

            // Update thread ID if provided and this is the first message
            if conversation.threadId == nil, let newThreadId = response.threadId {
                try await updateConversationThreadId(
                    id: conversationId,
                    threadId: newThreadId
                )
            }

            // Parse the markdown response to extract content and sources
            let parsedResponse = ResponseParser.parseMarkdownResponse(response.answer)

            // Save assistant message with sources
            let assistantMessage = try await addMessage(
                toConversation: conversationId,
                content: response.answer,
                isUserMessage: false,
                sources: parsedResponse.sources
            )

            return (userMessage, assistantMessage)

        } catch {
            // If API call fails, the user message is already saved locally
            // This allows offline mode and retry capability
            throw error
        }
    }

    /// Checks if the API is available
    /// - Returns: True if the API is healthy and reachable
    func checkAPIHealth() async throws -> Bool {
        guard let apiClient = apiClient else {
            return false
        }

        guard let networkMonitor = networkMonitor, networkMonitor.isConnected else {
            return false
        }

        do {
            let response = try await apiClient.healthCheck()
            return response.status.lowercased() == "ok"
        } catch {
            return false
        }
    }

    func ocr(_ request: OCRRequest) async throws -> OCRResponse {
        guard let apiClient = apiClient else {
            throw ChatRepositoryError.apiClientNotConfigured
        }
        return try await apiClient.ocr(request)
    }

    func confirmFactCheck(_ request: ConfirmFactCheckRequest) async throws -> AsyncThrowingStream<String, Error> {
        guard let apiClient = apiClient else {
            throw ChatRepositoryError.apiClientNotConfigured
        }
        return try await apiClient.confirmFactCheck(request)
    }

    // MARK: - Combine Publishers

    var conversationsPublisher: AnyPublisher<[Conversation], Never> {
        conversationsSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Helpers

    private func notifyConversationsChanged() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let conversations = try await fetchAllConversations()
                await MainActor.run {
                    self.conversationsSubject.send(conversations)
                }
            } catch {
                print("Error fetching conversations for publisher: \(error)")
            }
        }
    }
}

// MARK: - Repository Errors

enum ChatRepositoryError: LocalizedError {
    case conversationNotFound
    case messageNotFound
    case invalidData
    case apiClientNotConfigured

    var errorDescription: String? {
        switch self {
        case .conversationNotFound:
            return "Conversation not found."
        case .messageNotFound:
            return "Message not found."
        case .invalidData:
            return "Invalid data encountered."
        case .apiClientNotConfigured:
            return "API client is not configured."
        }
    }
}
