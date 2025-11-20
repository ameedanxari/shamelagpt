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

    // MARK: - Private Properties

    private let getConversationsUseCase: GetConversationsUseCase
    private let deleteConversationUseCase: DeleteConversationUseCase
    private let chatRepository: ChatRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        getConversationsUseCase: GetConversationsUseCase,
        deleteConversationUseCase: DeleteConversationUseCase,
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
                // Filter out empty conversations (those with no messages)
                // Only show conversations that have at least one message
                self?.conversations = conversations.filter { !$0.messages.isEmpty }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Loads all conversations from the repository
    func loadConversations() {
        Task {
            isLoading = true
            error = nil

            do {
                let conversations = try await getConversationsUseCase.execute()
                // Filter out empty conversations (those with no messages)
                self.conversations = conversations.filter { !$0.messages.isEmpty }
            } catch {
                self.error = "Failed to load conversations: \(error.localizedDescription)"
            }

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
                    self.error = "Failed to delete conversation: \(error.localizedDescription)"
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
                self.error = "Failed to delete all conversations: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }

    /// Creates a new conversation
    /// - Returns: The ID of the newly created conversation
    func createNewConversation() async throws -> String {
        error = nil

        do {
            // Generate title from timestamp
            let title = "New Conversation"
            let conversation = try await chatRepository.createConversation(title: title)
            return conversation.id
        } catch {
            self.error = "Failed to create conversation: \(error.localizedDescription)"
            throw error
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

        return conversation.preview
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
        var text = "Conversation: \(displayTitle(for: conversation))\n"
        text += "Created: \(conversation.createdAt.formatted())\n"
        text += "Updated: \(conversation.updatedAt.formatted())\n"
        text += "\n---\n\n"

        for message in conversation.messages {
            let sender = message.isUserMessage ? "You" : "ShamelaGPT"
            text += "[\(sender)] \(message.timestamp.formatted())\n"
            text += "\(message.content)\n"

            if message.hasSources {
                text += "\nSources:\n"
                for (index, source) in message.sources.enumerated() {
                    text += "\(index + 1). \(source.citation)\n"
                }
            }

            text += "\n---\n\n"
        }

        return text
    }
}
