package com.shamelagpt.android.presentation.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shamelagpt.android.data.remote.dto.LoginRequest
import com.shamelagpt.android.data.remote.dto.SignupRequest
import com.shamelagpt.android.domain.repository.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * ViewModel for login/signup flows.
 */
class AuthViewModel(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState

    fun updateEmail(email: String) {
        _uiState.update { it.copy(email = email) }
    }

    fun updatePassword(password: String) {
        _uiState.update { it.copy(password = password) }
    }

    fun updateDisplayName(name: String) {
        _uiState.update { it.copy(displayName = name) }
    }

    fun toggleMode() {
        _uiState.update {
            it.copy(isLoginMode = !it.isLoginMode, error = null)
        }
    }

    fun authenticate(onSuccess: () -> Unit) {
        val state = _uiState.value
        if (state.email.isBlank() || state.password.isBlank()) {
            _uiState.update { it.copy(error = "Email and password are required") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            val result = if (state.isLoginMode) {
                authRepository.login(LoginRequest(state.email, state.password))
            } else {
                authRepository.signup(
                    SignupRequest(
                        email = state.email,
                        password = state.password,
                        display_name = state.displayName.ifBlank { null }
                    )
                )
            }

            result.fold(
                onSuccess = {
                    onSuccess()
                    _uiState.update { it.copy(isLoading = false) }
                },
                onFailure = { ex ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = ex.message ?: "Authentication failed"
                        )
                    }
                }
            )
        }
    }
}
