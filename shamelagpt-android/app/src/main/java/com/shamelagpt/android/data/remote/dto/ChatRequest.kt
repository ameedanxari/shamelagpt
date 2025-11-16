package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Data transfer object for chat API requests.
 *
 * @property question User's question/message
 * @property threadId Optional thread ID from previous conversation
 * @property userId Optional user ID (currently not used)
 */
data class ChatRequest(
    val question: String,
    @SerializedName("thread_id")
    val threadId: String? = null,
    @SerializedName("user_id")
    val userId: String? = null
)
