package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName
import com.google.gson.JsonObject

/**
 * Response payload for authentication actions.
 */
data class AuthResponse(
    val token: String,
    @SerializedName("refresh_token")
    val refreshToken: String,
    @SerializedName("expires_in")
    val expiresIn: String,
    val user: JsonObject
)
