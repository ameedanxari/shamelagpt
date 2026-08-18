package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Server response describing whether a conversation is publicly shared.
 */
data class ShareStatusResponse(
    val status: String? = null,
    @SerializedName("conversation_id")
    val conversationId: String,
    @SerializedName("is_shared")
    val isShared: Boolean,
    @SerializedName("share_url")
    val shareUrl: String? = null
)
