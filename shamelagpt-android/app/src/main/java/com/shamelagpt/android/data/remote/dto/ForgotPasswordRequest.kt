package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Request model for forgot password.
 *
 * @property email User's email address
 */
data class ForgotPasswordRequest(
    @SerializedName("email")
    val email: String
)
