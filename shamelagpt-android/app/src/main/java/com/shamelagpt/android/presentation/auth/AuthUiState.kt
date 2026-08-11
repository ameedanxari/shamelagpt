package com.shamelagpt.android.presentation.auth

/**
 * UI state for authentication screen.
 */
data class AuthUiState(
    val email: String = "",
    val password: String = "",
    val displayName: String = "",
    val isLoginMode: Boolean = true,
    val isLoading: Boolean = false,
    val error: String? = null,
    val isGuestLimitPrompt: Boolean = false,
    /** True when [error] is an informational/success message (not a failure). */
    val isInfoMessage: Boolean = false
)
