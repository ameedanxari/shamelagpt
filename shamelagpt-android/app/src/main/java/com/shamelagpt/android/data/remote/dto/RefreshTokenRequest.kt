package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Request model for token refresh.
 *
 * @property refreshToken Firebase refresh token
 */
data class RefreshTokenRequest(
    @SerializedName("refresh_token")
    val refreshToken: String
)
