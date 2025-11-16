package com.shamelagpt.android.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Type of conversation
 */
enum class ConversationType {
    REGULAR,
    FACT_CHECK
}

/**
 * Room entity representing a conversation in the local database.
 *
 * @property id Unique identifier (UUID)
 * @property threadId Thread ID from API responses (nullable)
 * @property title Conversation title
 * @property createdAt Creation timestamp in milliseconds
 * @property updatedAt Last update timestamp in milliseconds
 * @property conversationType Type of conversation (regular or fact-check)
 * @property isLocalOnly Whether the conversation exists only locally (guest/unauthenticated)
 */
@Entity(tableName = "conversations")
data class ConversationEntity(
    @PrimaryKey
    val id: String,
    val threadId: String? = null,
    val title: String,
    val createdAt: Long,
    val updatedAt: Long,
    val conversationType: String = ConversationType.REGULAR.name,
    val isLocalOnly: Boolean = false
)
