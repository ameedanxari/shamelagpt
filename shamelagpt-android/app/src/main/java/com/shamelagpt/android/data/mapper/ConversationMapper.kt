package com.shamelagpt.android.data.mapper

import com.shamelagpt.android.data.local.entity.ConversationEntity
import com.shamelagpt.android.data.local.entity.ConversationType
import com.shamelagpt.android.data.local.dao.ConversationWithLastMessageEntity
import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.domain.model.Message


/**
 * Converts ConversationEntity to domain model Conversation.
 *
 * @return Conversation domain model
 */
fun ConversationEntity.toDomain(): Conversation {
    // Parse conversation type from string, defaulting to REGULAR if invalid
    val type = try {
        ConversationType.valueOf(conversationType)
    } catch (e: IllegalArgumentException) {
        ConversationType.REGULAR
    }

    return Conversation(
        id = id,
        threadId = threadId,
        title = title,
        createdAt = createdAt,
        updatedAt = updatedAt,
        messages = emptyList(), // Messages loaded separately
        conversationType = type,
        isLocalOnly = isLocalOnly
    )
}

/**
 * Converts domain model Conversation to ConversationEntity.
 *
 * @return ConversationEntity for database storage
 */
fun Conversation.toEntity(): ConversationEntity {
    return ConversationEntity(
        id = id,
        threadId = threadId,
        title = title,
        createdAt = createdAt,
        updatedAt = updatedAt,
        conversationType = conversationType.name,
        isLocalOnly = isLocalOnly
    )
}

/**
 * Converts ConversationWithLastMessageEntity to domain model Conversation.
 */
fun ConversationWithLastMessageEntity.toDomain(): Conversation {
    val domain = conversation.toDomain()
    val finalUpdatedAt = latestTimestamp ?: domain.updatedAt
    
    val messageList = if (lastMessageContent != null) {
        listOf(
            Message(
                id = "last_msg_preview",
                content = lastMessageContent,
                isUserMessage = false,
                timestamp = latestTimestamp ?: domain.updatedAt
            )
        )
    } else emptyList()
    
    return domain.copy(
        updatedAt = finalUpdatedAt,
        messages = messageList
    )
}
