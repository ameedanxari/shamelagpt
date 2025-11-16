package com.shamelagpt.android.domain.repository

import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.domain.model.Message
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for conversation operations.
 */
interface ConversationRepository {

    /**
     * Retrieves all conversations as a Flow.
     *
     * @return Flow of conversation list
     */
    fun getConversations(): Flow<List<Conversation>>

    /**
     * Retrieves a specific conversation by ID.
     *
     * @param id Conversation ID
     * @return Conversation or null if not found
     */
    suspend fun getConversationById(id: String): Conversation?

    /**
     * Creates a new conversation with the given title.
     *
     * @param title Conversation title
     * @return Newly created Conversation
     */
    suspend fun createConversation(title: String): Conversation

    /**
     * Deletes a conversation by ID.
     *
     * @param id Conversation ID
     */
    suspend fun deleteConversation(id: String)

    /**
     * Deletes all conversations.
     */
    suspend fun deleteAllConversations()

    /**
     * Saves a message to a conversation.
     *
     * @param message Message to save
     * @param conversationId ID of the conversation
     */
    suspend fun saveMessage(message: Message, conversationId: String)

    /**
     * Updates the conversation's threadId and updatedAt timestamp.
     *
     * @param conversationId Conversation ID
     * @param threadId Thread ID from API
     */
    suspend fun updateConversationThread(conversationId: String, threadId: String)

    /**
     * Retrieves all messages for a specific conversation as a Flow.
     *
     * @param conversationId Conversation ID
     * @return Flow of message list sorted by timestamp
     */
    fun getMessagesByConversationId(conversationId: String): Flow<List<Message>>

    /**
     * Sync conversations from backend when authenticated.
     */
    suspend fun syncConversations(forceRefresh: Boolean = false): Result<Unit>

    /**
     * Fetches messages for a specific conversation from the remote server and saves them locally.
     *
     * @param conversationId Conversation ID
     * @return Result indicating success or failure
     */
    suspend fun fetchMessages(conversationId: String, forceRefresh: Boolean = false): Result<Unit>
}
