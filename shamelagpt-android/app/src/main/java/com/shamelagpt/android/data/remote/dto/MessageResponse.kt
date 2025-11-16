package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Message response used when fetching conversation messages.
 */
data class MessageResponse(
    val id: String?,
    val role: String?,
    val content: String?,
    @SerializedName("created_at")
    val createdAt: String?
)
