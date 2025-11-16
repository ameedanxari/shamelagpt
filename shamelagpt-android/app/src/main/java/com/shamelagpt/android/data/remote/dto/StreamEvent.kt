package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * SSE event from the streaming chat API.
 */
data class StreamEvent(
    val type: String,
    val content: String? = null,
    @SerializedName("session_id")
    val sessionId: String? = null,
    @SerializedName("thread_id")
    val threadId: String? = null,
    @SerializedName("full_answer")
    val fullAnswer: String? = null
)
