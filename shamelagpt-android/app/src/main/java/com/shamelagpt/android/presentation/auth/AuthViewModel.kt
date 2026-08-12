package com.shamelagpt.android.presentation.auth

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shamelagpt.android.R
import com.shamelagpt.android.core.error.AppError
import com.shamelagpt.android.core.error.UserErrorMessage
import com.shamelagpt.android.core.network.NetworkError
import com.shamelagpt.android.core.util.Logger
import com.shamelagpt.android.data.remote.dto.LoginRequest
import com.shamelagpt.android.data.remote.dto.SignupRequest
import com.shamelagpt.android.domain.repository.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

private const val TAG = "AuthViewModel"

/**
 * ViewModel for login/signup flows.
 */
class AuthViewModel(
    private val authRepository: AuthRepository,
    private val appContext: Context
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

    fun setError(message: String) {
        _uiState.update { it.copy(error = message, isGuestLimitPrompt = false, isInfoMessage = false) }
    }

    fun prepareEntry(startInSignup: Boolean, initialMessage: String?) {
        _uiState.update {
            it.copy(
                isLoginMode = !startInSignup,
                error = initialMessage,
                isGuestLimitPrompt = !initialMessage.isNullOrBlank(),
                isInfoMessage = false
            )
        }
    }

    fun toggleMode() {
        _uiState.update {
            it.copy(
                isLoginMode = !it.isLoginMode,
                error = null,
                isGuestLimitPrompt = false,
                isInfoMessage = false
            )
        }
    }

    fun authenticate(onSuccess: () -> Unit) {
        val state = _uiState.value
        val mode = if (state.isLoginMode) "login" else "signup"
        Logger.i(TAG, "authenticate requested mode=$mode")
        
        if (state.email.isBlank() || state.password.isBlank()) {
            Logger.w(TAG, "authenticate validation failed: missing required fields")
            _uiState.update {
                it.copy(
                    error = "Email and password are required",
                    isGuestLimitPrompt = false,
                    isInfoMessage = false
                )
            }
            return
        }

        viewModelScope.launch {
            _uiState.update {
                it.copy(isLoading = true, error = null, isGuestLimitPrompt = false, isInfoMessage = false)
            }
            
            val trimmedEmail = state.email.trim()
            val trimmedPassword = state.password.trim()
            val result = if (state.isLoginMode) {
                Logger.d(TAG, "sending login request")
                authRepository.login(LoginRequest(trimmedEmail, trimmedPassword))
            } else {
                Logger.d(TAG, "sending signup request")
                authRepository.signup(
                    SignupRequest(
                        email = trimmedEmail,
                        password = trimmedPassword,
                        display_name = state.displayName.ifBlank { null }
                    )
                )
            }

            result.fold(
                onSuccess = {
                    Logger.i(TAG, "authentication success mode=$mode")
                    onSuccess()
                    _uiState.update { it.copy(isLoading = false) }
                },
                onFailure = { ex ->
                    Logger.w(TAG, "authentication failed mode=$mode reason=${ex::class.simpleName}")
                    if (isExpectedAuthValidation(state.isLoginMode, ex)) {
                        Logger.w(TAG, "authentication validation error mode=$mode detail=${ex.message}")
                    } else {
                        Logger.e(TAG, "authentication error", ex)
                    }
                    val mappedError = ex.toAuthFailureUi(state.isLoginMode)
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = mappedError.message,
                            isGuestLimitPrompt = false,
                            isInfoMessage = false
                        )
                    }
                }
            )
        }
    }

    fun forgotPassword() {
        val email = _uiState.value.email.trim()
        Logger.i(TAG, "forgot password requested")
        if (email.isBlank()) {
            Logger.w(TAG, "forgot password validation failed: email missing")
            _uiState.update {
                it.copy(
                    error = appContext.getString(R.string.forgot_password_email_required),
                    isGuestLimitPrompt = false,
                    isInfoMessage = false
                )
            }
            return
        }

        viewModelScope.launch {
            _uiState.update {
                it.copy(isLoading = true, error = null, isGuestLimitPrompt = false, isInfoMessage = false)
            }
            Logger.d(TAG, "sending forgot password request")
            val result = authRepository.forgotPassword(email)
            result.fold(
                onSuccess = {
                    Logger.i(TAG, "forgot password request succeeded")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = appContext.getString(R.string.forgot_password_email_sent),
                            isGuestLimitPrompt = false,
                            isInfoMessage = true
                        )
                    }
                },
                onFailure = { ex ->
                    Logger.w(TAG, "forgot password failed reason=${ex::class.simpleName}")
                    Logger.e(TAG, "forgot password error", ex)
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = ex.toUserFacingMessage(),
                            isGuestLimitPrompt = false,
                            isInfoMessage = false
                        )
                    }
                }
            )
        }
    }

    fun googleSignIn(idToken: String, onSuccess: () -> Unit) {
        viewModelScope.launch {
            Logger.i(TAG, "google sign-in requested")
            Logger.d(TAG, "google sign-in id_token length=${idToken.length}")
            _uiState.update {
                it.copy(isLoading = true, error = null, isGuestLimitPrompt = false, isInfoMessage = false)
            }
            val result = authRepository.googleSignIn(idToken)
            result.fold(
                onSuccess = {
                    Logger.i(TAG, "google sign-in succeeded")
                    onSuccess()
                    _uiState.update { it.copy(isLoading = false) }
                },
                onFailure = { ex ->
                    Logger.w(TAG, "google sign-in failed reason=${ex::class.simpleName}")
                    Logger.e(TAG, "google sign-in error", ex)
                    if (ex is NetworkError) {
                        Logger.d(TAG, "google sign-in network error detail=${ex.getUserMessage(appContext)}")
                    }
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = ex.toUserFacingMessage(),
                            isGuestLimitPrompt = false,
                            isInfoMessage = false
                        )
                    }
                }
            )
        }
    }

    private fun isExpectedAuthValidation(isLoginMode: Boolean, throwable: Throwable): Boolean {
        if (isInvalidLoginCredentials(isLoginMode, throwable)) return true
        if (isLoginMode) return false
        val httpError = throwable as? NetworkError.HttpError ?: return false
        val body = httpError.errorBody.orEmpty()
        return httpError.code == 400 && body.contains("Email already exists", ignoreCase = true)
    }

    private fun Throwable.toAuthFailureUi(isLoginMode: Boolean): AuthFailureUi {
        if (isInvalidLoginCredentials(isLoginMode, this)) {
            return AuthFailureUi(message = appContext.getString(R.string.auth_invalid_credentials))
        }
        if (!isLoginMode) {
            val httpError = this as? NetworkError.HttpError
            val body = httpError?.errorBody.orEmpty()
            if (httpError?.code == 400 && body.contains("Email already exists", ignoreCase = true)) {
                return AuthFailureUi(message = appContext.getString(R.string.auth_email_exists_use_login))
            }
        }
        return AuthFailureUi(message = toUserFacingMessage())
    }

    private fun isInvalidLoginCredentials(isLoginMode: Boolean, throwable: Throwable): Boolean {
        if (!isLoginMode) return false
        // Login 401/403 are mapped to Unauthorized by SafeApiCall — treat as bad credentials,
        // not "session expired / please sign in" (that copy is for authenticated API calls).
        if (throwable is NetworkError.Unauthorized) return true
        val httpError = throwable as? NetworkError.HttpError ?: return false
        if (httpError.code == 401 || httpError.code == 403) return true
        if (httpError.code != 400) return false

        val body = httpError.errorBody.orEmpty()
        return body.contains("invalid credential", ignoreCase = true) ||
            body.contains("invalid login credential", ignoreCase = true) ||
            body.contains("invalid email or password", ignoreCase = true) ||
            body.contains("email or password", ignoreCase = true)
    }

    private fun Throwable.toUserFacingMessage(): String {
        return when (this) {
            is NetworkError -> getUserMessageWithCode(appContext)
            is AppError -> UserErrorMessage.format(appContext, getUserMessage(appContext), debugCode)
            else -> UserErrorMessage.from(appContext, this)
        }
    }

    private data class AuthFailureUi(val message: String)
}
