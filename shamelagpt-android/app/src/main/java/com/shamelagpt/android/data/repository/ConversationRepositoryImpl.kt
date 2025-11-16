package com.shamelagpt.android.data.repository

import com.shamelagpt.android.data.local.dao.ConversationDao
import com.shamelagpt.android.data.local.dao.MessageDao
import com.shamelagpt.android.data.mapper.toDomain
import com.shamelagpt.android.data.mapper.toEntity
import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.repository.ConversationRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.UUID

/**
 * Implementation of ConversationRepository using Room database.
 *
 * @property conversationDao DAO for conversation operations
 * @property messageDao DAO for message operations
 */
class ConversationRepositoryImpl(
    private val conversationDao: ConversationDao,
    private val messageDao: MessageDao
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
        val conversation = Conversation(
            id = UUID.randomUUID().toString(),
            threadId = null,
            title = title,
            createdAt = now,
            updatedAt = now,
            messages = emptyList()
        )

        conversationDao.insertConversation(conversation.toEntity())
        return conversation
    }

    override suspend fun deleteConversation(id: String) {
        val entity = conversationDao.getConversationById(id)
        if (entity != null) {
            conversationDao.deleteConversation(entity)
            // Messages will be cascade deleted due to foreign key constraint
        }
    }

    override suspend fun deleteAllConversations() {
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
}
