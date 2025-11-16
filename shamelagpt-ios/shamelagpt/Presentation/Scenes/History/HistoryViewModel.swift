//
//  HistoryViewModel.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for the conversation history screen
@MainActor
final class HistoryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var conversations: [Conversation] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var showDeleteConfirmation: Bool = false
    @Published var conversationToDelete: Conversation?
    @Published var includeLocalOnly: Bool = true

    // MARK: - Private Properties

    private let getConversationsUseCase: GetConversationsUseCaseProtocol
    private let deleteConversationUseCase: DeleteConversationUseCaseProtocol
    private let chatRepository: ChatRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        getConversationsUseCase: GetConversationsUseCaseProtocol,
        deleteConversationUseCase: DeleteConversationUseCaseProtocol,
        chatRepository: ChatRepository
    ) {
        self.getConversationsUseCase = getConversationsUseCase
        self.deleteConversationUseCase = deleteConversationUseCase
        self.chatRepository = chatRepository

        setupConversationObserver()
    }

    // MARK: - Setup

    /// Sets up the conversation observer to receive real-time updates
    private func setupConversationObserver() {
        getConversationsUseCase.observeConversations()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conversations in
                AppLogger.app.logDebug("HistoryViewModel received \(conversations.count) conversations from observer")
                // Log a compact summary for each conversation to aid debugging
                for conv in conversations {
                    AppLogger.app.logDebug("-- conv id:\(conv.id) messages:\(conv.messages.count) threadId:\(conv.threadId ?? "nil") isLocalOnly:\(conv.isLocalOnly) createdAt:\(conv.createdAt)")
                }

                let filtered = conversations.filter { [weak self] conversation in
                    // Hide local-only conversations only when not allowed (e.g., guests viewing history)
                    if conversation.isLocalOnly && (self?.includeLocalOnly == false) {
                        AppLogger.app.logDebug("Conversation \(conversation.id) is local-only - FILTERED from history")
                        return false
                    }

                    AppLogger.app.logDebug("Conversation \(conversation.id) INCLUDED (messages=\(conversation.messages.count), localOnly=\(conversation.isLocalOnly))")
                    return true
                }

                AppLogger.app.logDebug("HistoryViewModel filtered to \(filtered.count) conversations")
                self?.conversations = filtered.sorted {
                    // sort in reverse chronological order using last update
                    $0.updatedAt > $1.updatedAt
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Loads all conversations (used for initial load)
    func loadConversations() {
        Task {
            await refreshConversations(forceRefresh: false)
        }
    }

    /// Async refresh for pull-to-refresh (authenticated only)
    func refreshConversations(forceRefresh: Bool = false) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            try await chatRepository.syncRemoteConversations(forceRefresh: forceRefresh)
            let conversations = try await getConversationsUseCase.execute()
            await MainActor.run {
                self.conversations = conversations.filter { conversation in
                    // Hide local-only conversations only when not allowed (e.g., guests viewing history)
                    if conversation.isLocalOnly && includeLocalOnly == false {
                        return false
                    }
                    // Include conversations even if messages are not yet hydrated
                    return true
                }.sorted {
                    // sort in reverse chronological order using last update
                    $0.updatedAt > $1.updatedAt
                }
            }
        } catch {
            await MainActor.run {
                AppLogger.app.logError("Failed to load conversations", error: error)
                self.error = LanguageManager.shared.localizedString(forKey: LocalizationKeys.historyLoadFailed)
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    /// Shows delete confirmation dialog for a conversation
    /// - Parameter conversation: The conversation to delete
    func requestDelete(_ conversation: Conversation) {
        conversationToDelete = conversation
        showDeleteConfirmation = true
    }

    /// Deletes the selected conversation
    func confirmDelete() {
        guard let conversation = conversationToDelete else { return }

        Task {
            error = nil

            do {
                try await deleteConversationUseCase.execute(id: conversation.id)

                // Clean up state with animation coordination
                await MainActor.run {
                    withAnimation {
                        conversationToDelete = nil
                        showDeleteConfirmation = false
                    }
                }
            } catch {
                await MainActor.run {
                    AppLogger.app.logError("Failed to delete conversation", error: error)
                    self.error = LanguageManager.shared.localizedString(forKey: LocalizationKeys.historyDeleteFailed)
                    conversationToDelete = nil
                    showDeleteConfirmation = false
                }
            }
        }
    }

    /// Cancels the delete operation
    func cancelDelete() {
        conversationToDelete = nil
        showDeleteConfirmation = false
    }

    /// Deletes all conversations
    func deleteAllConversations() {
        Task {
            isLoading = true
            error = nil

            do {
                try await deleteConversationUseCase.executeDeleteAll()
            } catch {
                AppLogger.app.logError("Failed to delete all conversations", error: error)
                await MainActor.run {
                    self.error = LanguageManager.shared.localizedString(forKey: LocalizationKeys.historyDeleteAllFailed)
                }
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }

    /// Generates a title from the first message
    /// - Parameter message: The first user message
    /// - Returns: Truncated title (max 50 characters)
    func generateTitle(from message: String) -> String {
        let trimmed = message.trimmed

        if trimmed.isEmpty {
            return "New Conversation"
        }

        return trimmed.truncated(to: 50)
    }

    /// Gets the relative timestamp for a conversation
    /// - Parameter conversation: The conversation
    /// - Returns: Formatted relative time string
    func relativeTime(for conversation: Conversation) -> String {
        conversation.updatedAt.relativeTimeString()
    }

    /// Gets a preview of the last message
    /// - Parameter conversation: The conversation
    /// - Returns: Preview text
    func messagePreview(for conversation: Conversation) -> String {
        if conversation.messages.isEmpty {
            return "No messages"
        }

        return conversation.previewText
    }

    /// Gets the display title for a conversation
    /// - Parameter conversation: The conversation
    /// - Returns: The conversation title
    func displayTitle(for conversation: Conversation) -> String {
        let title = conversation.title.trimmed

        if title.isEmpty || title == "New Conversation" {
            // If title is empty or default, try to generate from first message
            if let firstMessage = conversation.messages.first(where: { $0.isUserMessage }) {
                return generateTitle(from: firstMessage.content)
            }
            return "New Conversation"
        }

        return title
    }

    /// Exports conversation as text
    /// - Parameter conversation: The conversation to export
    /// - Returns: Formatted text of the conversation
    func exportConversation(_ conversation: Conversation) -> String {
        let title = displayTitle(for: conversation)
        let link = "https://shamelagpt.com/chat?id=\(conversation.id)"
        let preview = messagePreview(for: conversation)
        let updated = conversation.updatedAt.formatted()

        var text = "ShamelaGPT Chat: \(title)\n"
        text += "Link: \(link)\n"
        text += "Last updated: \(updated)\n"

        if !preview.isEmpty {
            text += "\nPreview:\n\(preview)"
        }

        return text
    }
}
