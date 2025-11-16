package com.shamelagpt.android.data.remote.dto

/**
 * Request payload for user signup.
 */
data class SignupRequest(
    val email: String,
    val password: String,
    val display_name: String?
)
