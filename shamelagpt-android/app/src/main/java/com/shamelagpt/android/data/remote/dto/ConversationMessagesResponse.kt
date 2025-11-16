package com.shamelagpt.android.data.remote.dto

/**
 * Conversation messages response.
 */
data class ConversationMessagesResponse(
    val conversationId: String?,
    val messages: List<MessageResponse>
)
