package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Data transfer object for chat API responses.
 *
 * @property answer AI response in markdown format with sources
 * @property threadId Thread ID for continuing the conversation
 */
data class ChatResponse(
    val answer: String,
    @SerializedName("thread_id")
    val threadId: String
)
