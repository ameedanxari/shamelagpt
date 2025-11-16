package com.shamelagpt.android.data.mapper

import com.shamelagpt.android.data.local.entity.ConversationEntity
import com.shamelagpt.android.data.local.entity.ConversationType
import com.shamelagpt.android.domain.model.Conversation

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
        conversationType = type
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
        conversationType = conversationType.name
    )
}
