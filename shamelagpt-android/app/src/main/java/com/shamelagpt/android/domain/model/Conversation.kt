package com.shamelagpt.android.domain.model

import com.shamelagpt.android.data.local.entity.ConversationType

/**
 * Domain model representing a conversation.
 *
 * @property id Unique identifier (UUID)
 * @property threadId Thread ID from API responses (nullable)
 * @property title Conversation title
 * @property createdAt Creation timestamp in milliseconds
 * @property updatedAt Last update timestamp in milliseconds
 * @property messages List of messages in the conversation
 * @property conversationType Type of conversation (regular or fact-check)
 * @property isLocalOnly Whether the conversation exists only locally (guest/unauthenticated)
 */
data class Conversation(
    val id: String,
    var threadId: String? = null,
    val title: String,
    val createdAt: Long,
    var updatedAt: Long,
    var messages: List<Message> = emptyList(),
    val conversationType: ConversationType = ConversationType.REGULAR,
    val isLocalOnly: Boolean = false
)
