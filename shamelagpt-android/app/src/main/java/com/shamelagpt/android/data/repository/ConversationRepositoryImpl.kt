package com.shamelagpt.android.data.repository

import com.shamelagpt.android.data.local.dao.ConversationDao
import com.shamelagpt.android.data.local.dao.MessageDao
import com.shamelagpt.android.data.mapper.toDomain
import com.shamelagpt.android.data.mapper.toEntity
import com.shamelagpt.android.data.remote.datasource.ConversationRemoteDataSource
import com.shamelagpt.android.data.remote.dto.ConversationResponse
import com.shamelagpt.android.data.remote.dto.ConversationRequest
import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.repository.ConversationRepository
import com.shamelagpt.android.core.preferences.SessionManager
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.Instant
import java.time.format.DateTimeParseException
import java.util.UUID

/**
 * Implementation of ConversationRepository using Room database.
 *
 * @property conversationDao DAO for conversation operations
 * @property messageDao DAO for message operations
 */
class ConversationRepositoryImpl(
    private val conversationDao: ConversationDao,
    private val messageDao: MessageDao,
    private val conversationRemoteDataSource: ConversationRemoteDataSource? = null,
    private val sessionManager: SessionManager? = null
) : ConversationRepository {

    override fun getConversations(): Flow<List<Conversation>> {
        return conversationDao.getAllConversations()
            .map { entities -> entities.map { it.toDomain() } }
    }

    override suspend fun getConversationById(id: String): Conversation? {
        val entity = conversationDao.getConversationById(id) ?: return null
        return entity.toDomain()
    }

    override suspend fun createConversation(title: String): Conversation {
        val now = System.currentTimeMillis()
        val remoteCreated = if (sessionManager?.isLoggedIn() == true && conversationRemoteDataSource != null) {
            conversationRemoteDataSource.createConversation(ConversationRequest(title = title)).getOrNull()
        } else null

        val conversation = Conversation(
            id = remoteCreated?.id ?: UUID.randomUUID().toString(),
            threadId = remoteCreated?.threadId,
            title = remoteCreated?.title ?: title,
            createdAt = remoteCreated?.createdAt?.let { parseTimestamp(it) } ?: now,
            updatedAt = remoteCreated?.updatedAt?.let { parseTimestamp(it) } ?: now,
            messages = emptyList()
        )

        conversationDao.insertConversation(conversation.toEntity())
        return conversation
    }

    override suspend fun deleteConversation(id: String) {
        if (sessionManager?.isLoggedIn() == true && conversationRemoteDataSource != null) {
            conversationRemoteDataSource.deleteConversation(id)
        }
        val entity = conversationDao.getConversationById(id)
        if (entity != null) {
            conversationDao.deleteConversation(entity)
            // Messages will be cascade deleted due to foreign key constraint
        }
    }

    override suspend fun deleteAllConversations() {
        if (sessionManager?.isLoggedIn() == true && conversationRemoteDataSource != null) {
            conversationRemoteDataSource.deleteAllConversations()
        }
        conversationDao.deleteAllConversations()
        // Messages will be cascade deleted due to foreign key constraint
    }

    override suspend fun saveMessage(message: Message, conversationId: String) {
        // Insert the message
        messageDao.insertMessage(message.toEntity(conversationId))

        // Update conversation's updatedAt timestamp
        val conversation = conversationDao.getConversationById(conversationId)
        if (conversation != null) {
            val updatedConversation = conversation.copy(updatedAt = System.currentTimeMillis())
            conversationDao.updateConversation(updatedConversation)
        }
    }

    override suspend fun updateConversationThread(conversationId: String, threadId: String) {
        val conversation = conversationDao.getConversationById(conversationId)
        if (conversation != null) {
            val updatedConversation = conversation.copy(
                threadId = threadId,
                updatedAt = System.currentTimeMillis()
            )
            conversationDao.updateConversation(updatedConversation)
        }
    }

    override fun getMessagesByConversationId(conversationId: String): Flow<List<Message>> {
        return messageDao.getMessagesByConversationId(conversationId)
            .map { entities -> entities.map { it.toDomain() } }
    }

    override suspend fun syncConversations(): Result<Unit> {
        if (sessionManager?.isLoggedIn() != true || conversationRemoteDataSource == null) {
            return Result.success(Unit)
        }

        val result = conversationRemoteDataSource.listConversations()
        result.onSuccess { conversations ->
            conversations.forEach { upsertConversation(it) }
        }
        return result.map { }
    }

    private suspend fun upsertConversation(remote: ConversationResponse) {
        val createdAt = parseTimestamp(remote.createdAt)
        val updatedAt = parseTimestamp(remote.updatedAt)
        val conversation = Conversation(
            id = remote.id,
            threadId = remote.threadId,
            title = remote.title ?: "New Chat",
            createdAt = createdAt ?: System.currentTimeMillis(),
            updatedAt = updatedAt ?: System.currentTimeMillis(),
            messages = emptyList()
        )
        conversationDao.insertConversation(conversation.toEntity())
    }

    private fun parseTimestamp(raw: String?): Long? {
        if (raw.isNullOrBlank()) return null
        return try {
            Instant.parse(raw).toEpochMilli()
        } catch (e: DateTimeParseException) {
            null
        }
    }
}
