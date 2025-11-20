//
//  ChatRepository.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Combine

/// Protocol defining the interface for chat data operations
protocol ChatRepository {

    // MARK: - Conversation Operations

    /// Creates a new conversation
    /// - Parameter title: The title of the conversation
    /// - Returns: The created Conversation
    func createConversation(title: String) async throws -> Conversation

    /// Fetches all conversations
    /// - Returns: Array of all conversations ordered by most recent
    func fetchAllConversations() async throws -> [Conversation]

    /// Fetches a conversation by its ID
    /// - Parameter id: The conversation ID
    /// - Returns: The Conversation if found
    func fetchConversation(byId id: String) async throws -> Conversation?

    /// Fetches a conversation by its thread ID
    /// - Parameter threadId: The OpenAI thread ID
    /// - Returns: The Conversation if found
    func fetchConversation(byThreadId threadId: String) async throws -> Conversation?

    /// Fetches the most recent empty conversation (with no messages)
    /// - Returns: The most recent empty Conversation if found
    func fetchMostRecentEmptyConversation() async throws -> Conversation?

    /// Updates a conversation's title
    /// - Parameters:
    ///   - id: The conversation ID
    ///   - title: The new title
    func updateConversationTitle(id: String, title: String) async throws

    /// Updates a conversation's thread ID
    /// - Parameters:
    ///   - id: The conversation ID
    ///   - threadId: The OpenAI thread ID
    func updateConversationThreadId(id: String, threadId: String) async throws

    /// Deletes a conversation
    /// - Parameter id: The conversation ID
    func deleteConversation(id: String) async throws

    /// Deletes all conversations
    func deleteAllConversations() async throws

    // MARK: - Message Operations

    /// Adds a message to a conversation
    /// - Parameters:
    ///   - conversationId: The ID of the conversation
    ///   - content: The message content
    ///   - isUserMessage: Whether this is a user message
    ///   - sources: Optional array of sources
    /// - Returns: The created Message
    func addMessage(
        toConversation conversationId: String,
        content: String,
        isUserMessage: Bool,
        sources: [Source]
    ) async throws -> Message

    /// Adds a fact-check message to a conversation
    /// - Parameters:
    ///   - conversationId: The ID of the conversation
    ///   - content: The message content
    ///   - isUserMessage: Whether this is a user message
    ///   - sources: Optional array of sources
    ///   - imageData: Optional image data for fact-check messages
    ///   - detectedLanguage: Optional detected language code
    ///   - isFactCheckMessage: Whether this is a fact-check message
    /// - Returns: The created Message
    func addFactCheckMessage(
        toConversation conversationId: String,
        content: String,
        isUserMessage: Bool,
        sources: [Source],
        imageData: Data?,
        detectedLanguage: String?,
        isFactCheckMessage: Bool
    ) async throws -> Message

    /// Fetches all messages for a conversation
    /// - Parameter conversationId: The conversation ID
    /// - Returns: Array of messages ordered by timestamp
    func fetchMessages(forConversation conversationId: String) async throws -> [Message]

    /// Updates a message's content
    /// - Parameters:
    ///   - id: The message ID
    ///   - content: The new content
    func updateMessageContent(id: String, content: String) async throws

    /// Deletes a message
    /// - Parameter id: The message ID
    func deleteMessage(id: String) async throws

    // MARK: - Combine Publishers

    /// Publisher that emits conversation updates
    var conversationsPublisher: AnyPublisher<[Conversation], Never> { get }
}
