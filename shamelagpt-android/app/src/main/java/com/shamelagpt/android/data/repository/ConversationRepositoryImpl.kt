package com.shamelagpt.android.data.repository

import android.util.Log
import com.shamelagpt.android.data.local.dao.ConversationDao
import com.shamelagpt.android.data.local.dao.MessageDao
import com.shamelagpt.android.data.mapper.toDomain
import com.shamelagpt.android.data.mapper.toDomainModel
import com.shamelagpt.android.data.mapper.toEntity
import com.shamelagpt.android.data.remote.datasource.ConversationRemoteDataSource
import com.shamelagpt.android.data.remote.dto.ConversationResponse
import com.shamelagpt.android.data.remote.dto.ConversationRequest
import com.shamelagpt.android.data.remote.dto.MessageResponse
import com.shamelagpt.android.data.local.entity.ConversationType
import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.repository.ConversationRepository
import com.shamelagpt.android.core.preferences.SessionManager
import com.shamelagpt.android.core.preferences.ConversationSyncMetadataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.Instant
import java.time.format.DateTimeParseException
import java.util.UUID

private const val TAG = "ConversationRepositoryImpl"

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
    private val sessionManager: SessionManager? = null,
    private val syncMetadataStore: ConversationSyncMetadataStore
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
        Log.d(TAG, "createConversation() called with title: $title")
        val now = System.currentTimeMillis()
        val isLoggedIn = sessionManager?.isLoggedIn() == true
        Log.d(TAG, "User isLoggedIn: $isLoggedIn")
        val remoteCreated = if (isLoggedIn && conversationRemoteDataSource != null) {
            Log.d(TAG, "Creating conversation on remote server...")
            conversationRemoteDataSource.createConversation(ConversationRequest(title = title)).getOrNull()
        } else null
        val isLocalOnly = !isLoggedIn

        val conversation = Conversation(
            id = remoteCreated?.id ?: UUID.randomUUID().toString(),
            threadId = remoteCreated?.threadId,
            title = remoteCreated?.title ?: title,
            createdAt = remoteCreated?.createdAt?.let { parseTimestamp(it) } ?: now,
            updatedAt = remoteCreated?.updatedAt?.let { parseTimestamp(it) } ?: now,
            messages = emptyList(),
            isLocalOnly = isLocalOnly
        )

        Log.d(TAG, "Inserting conversation: id=${conversation.id}, isLocalOnly=$isLocalOnly")
        conversationDao.insertConversation(conversation.toEntity())
        Log.d(TAG, "Conversation created successfully")
        return conversation
    }

    override suspend fun deleteConversation(id: String) {
        Log.d(TAG, "deleteConversation() called for id: $id")
        if (sessionManager?.isLoggedIn() == true && conversationRemoteDataSource != null) {
            Log.d(TAG, "Deleting conversation from remote server...")
            conversationRemoteDataSource.deleteConversation(id)
        }
        val entity = conversationDao.getConversationById(id)
        if (entity != null) {
            Log.d(TAG, "Deleting conversation from local database...")
            conversationDao.deleteConversation(entity)
            Log.d(TAG, "Conversation deleted (messages cascade deleted)")
            // Messages will be cascade deleted due to foreign key constraint
        } else {
            Log.w(TAG, "Conversation not found: $id")
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
        Log.d(TAG, "saveMessage() called: conversationId=$conversationId, messageId=${message.id}, isUser=${message.isUserMessage}")
        // Insert the message
        messageDao.insertMessage(message.toEntity(conversationId))
        Log.d(TAG, "Message inserted")

        // Update conversation's updatedAt timestamp
        val conversation = conversationDao.getConversationById(conversationId)
        if (conversation != null) {
            val updatedType = if (message.isFactCheckMessage) {
                ConversationType.FACT_CHECK.name
            } else {
                conversation.conversationType
            }
            val updatedConversation = conversation.copy(
                updatedAt = System.currentTimeMillis(),
                conversationType = updatedType
            )
            conversationDao.updateConversation(updatedConversation)
            Log.d(TAG, "Updated conversation timestamp")
        } else {
            Log.w(TAG, "Conversation not found for update: $conversationId")
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

    override suspend fun fetchMessages(conversationId: String, forceRefresh: Boolean): Result<Unit> {
        if (sessionManager?.isLoggedIn() != true || conversationRemoteDataSource == null) {
            Log.d(
                TAG,
                "Skipping remote fetch for conversationId=${conversationId.takeLast(4)} (not authenticated or remote data source unavailable)"
            )
            return Result.success(Unit)
        }
        if (!syncMetadataStore.shouldSyncMessages(conversationId, forceRefresh)) {
            Log.d(
                TAG,
                "Skipping remote fetch for conversationId=${conversationId.takeLast(4)} due to fresh cache (forceRefresh=$forceRefresh)"
            )
            return Result.success(Unit)
        }

        Log.d(TAG, "fetchMessages() called for conversationId: $conversationId")
        val localMessageCountBeforeSync = messageDao.countMessagesByConversationId(conversationId)
        val result = conversationRemoteDataSource.getMessages(conversationId)
        result.onSuccess { response ->
            Log.d(TAG, "Fetched ${response.messages.size} messages from remote")

            if (response.messages.isEmpty() && localMessageCountBeforeSync > 0) {
                Log.w(
                    TAG,
                    "Remote returned 0 messages for conversationId=${conversationId.takeLast(4)}; preserving $localMessageCountBeforeSync local message(s)"
                )
                syncMetadataStore.markMessagesSynced(conversationId)
                return@onSuccess
            }

            response.messages.forEach { remoteMessage ->
                val domainMessage = remoteMessage.toDomainModel()
                messageDao.insertMessage(domainMessage.toEntity(conversationId))
                
                // Also update conversation updatedAt locally to reflect new message
                val conv = conversationDao.getConversationById(conversationId)
                if (conv != null) {
                    val msgTime = domainMessage.timestamp
                    if (msgTime > conv.updatedAt) {
                        conversationDao.updateConversation(conv.copy(updatedAt = msgTime))
                    }
                }
            }
            syncMetadataStore.markMessagesSynced(conversationId)
        }
        return result.map { }
    }

    override suspend fun syncConversations(forceRefresh: Boolean): Result<Unit> {
        if (sessionManager?.isLoggedIn() != true || conversationRemoteDataSource == null) {
            return Result.success(Unit)
        }
        if (!syncMetadataStore.shouldSyncConversations(forceRefresh)) {
            return Result.success(Unit)
        }

        val result = conversationRemoteDataSource.listConversations()
        result.onSuccess { conversations ->
            conversations.forEach { upsertConversation(it) }
            syncMetadataStore.markConversationsSynced()
        }
        return result.map { }
    }

    private suspend fun upsertConversation(remote: ConversationResponse) {
        val existing = conversationDao.getConversationById(remote.id)
        val createdAt = parseTimestamp(remote.createdAt) ?: existing?.createdAt ?: System.currentTimeMillis()
        val updatedAt = parseTimestamp(remote.updatedAt) ?: existing?.updatedAt ?: System.currentTimeMillis()
        
        // Take the latest of remote updated_at AND existing local updated_at to ensure history order is preserved
        val finalUpdatedAt = if (existing != null) maxOf(updatedAt, existing.updatedAt) else updatedAt

        val conversation = Conversation(
            id = remote.id,
            threadId = remote.threadId ?: existing?.threadId,
            title = remote.title ?: existing?.title ?: "New Chat",
            createdAt = createdAt,
            updatedAt = finalUpdatedAt,
            messages = emptyList(),
            isLocalOnly = false,
            // Preserve existing type if present
            conversationType = existing?.let {
                try { com.shamelagpt.android.data.local.entity.ConversationType.valueOf(it.conversationType) }
                catch(e: Exception) { com.shamelagpt.android.data.local.entity.ConversationType.REGULAR }
            } ?: com.shamelagpt.android.data.local.entity.ConversationType.REGULAR
        )

        // Avoid INSERT(REPLACE) on an existing conversation row because REPLACE can
        // trigger FK cascade deletion of child messages.
        if (existing != null) {
            conversationDao.updateConversation(conversation.toEntity())
        } else {
            conversationDao.insertConversation(conversation.toEntity())
        }
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
