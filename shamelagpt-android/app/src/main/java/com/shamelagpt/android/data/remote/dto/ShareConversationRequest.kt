package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Body for `PUT /api/conversations/{id}/share`.
 */
data class ShareConversationRequest(
    @SerializedName("is_shared")
    val isShared: Boolean
)
