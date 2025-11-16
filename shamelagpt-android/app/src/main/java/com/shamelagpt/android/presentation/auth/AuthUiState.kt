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
    val error: String? = null
)
