package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Response payload for user profile.
 */
data class UserResponse(
    val id: String,
    @SerializedName("firebase_uid")
    val firebaseUid: String,
    val email: String?,
    @SerializedName("display_name")
    val displayName: String?,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String,
    @SerializedName("last_login")
    val lastLogin: String?
)
