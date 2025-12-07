package com.shamelagpt.android.data.remote.dto

/**
 * Request payload for updating user profile.
 */
data class UpdateUserRequest(
    val email: String?,
    val display_name: String?
)
