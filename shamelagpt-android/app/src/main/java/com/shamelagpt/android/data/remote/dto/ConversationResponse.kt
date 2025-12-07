package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Minimal conversation response model to mirror backend shape.
 */
data class ConversationResponse(
    val id: String,
    @SerializedName("thread_id")
    val threadId: String?,
    val title: String?,
    @SerializedName("created_at")
    val createdAt: String?,
    @SerializedName("updated_at")
    val updatedAt: String?
)
