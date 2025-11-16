package com.shamelagpt.android.core.network

import com.shamelagpt.android.core.preferences.SessionManager
import com.shamelagpt.android.core.util.Logger
import com.shamelagpt.android.data.remote.dto.LoginRequest
import com.shamelagpt.android.data.remote.dto.AuthResponse
import com.shamelagpt.android.data.remote.ApiService
import com.shamelagpt.android.data.remote.dto.RefreshTokenRequest

/**
 * Handles silent re-login when tokens expire by using stored credentials.
 *
 * Behaviour:
 * - Attempts login once when invoked.
 * - If login succeeds, persists new session.
 * - If login fails with unauthorized, clears stored credentials.
 * - If login fails due to network/other errors, keeps credentials for later attempts.
 */
class AuthRetryManager(
    private val sessionManager: SessionManager,
    private val apiService: ApiService
 ) {
    private val tag = "AuthRetryManager"

    /**
     * Attempts to restore a valid session with the least user friction:
     * 1) refresh token
     * 2) stored email/password login fallback
     */
    suspend fun restoreSession(): Boolean {
        Logger.i(tag, "session restore started")

        when (tryRefreshToken()) {
            AttemptResult.Success -> return true
            AttemptResult.Unauthorized -> {
                // Invalid refresh token; clear token artifacts and try credential fallback.
                sessionManager.clearSession()
            }
            AttemptResult.Failed,
            AttemptResult.Skipped -> Unit
        }

        when (tryCredentialsLogin()) {
            AttemptResult.Success -> return true
            AttemptResult.Unauthorized -> {
                Logger.w(tag, "credential login unauthorized; clearing persisted auth state")
                sessionManager.clearSession()
                sessionManager.clearCredentials()
            }
            AttemptResult.Failed,
            AttemptResult.Skipped -> Unit
        }

        Logger.i(tag, "session restore failed")
        return false
    }

    suspend fun trySilentLogin(): Boolean {
        return restoreSession()
    }

    private suspend fun tryRefreshToken(): AttemptResult {
        val refreshToken = sessionManager.getRefreshToken()
        if (refreshToken.isNullOrBlank()) {
            Logger.i(tag, "refresh token attempt skipped: token not available")
            return AttemptResult.Skipped
        }

        Logger.i(tag, "refresh token attempt started")
        val refreshResult = safeApiCall {
            apiService.refreshToken(RefreshTokenRequest(refreshToken))
        }

        return refreshResult.fold(
            onSuccess = { response ->
                Logger.i(tag, "refresh token attempt succeeded")
                persistSession(response)
                AttemptResult.Success
            },
            onFailure = { throwable ->
                Logger.w(tag, "refresh token attempt failed reason=${throwable::class.simpleName}")
                if (throwable is NetworkError.Unauthorized) {
                    AttemptResult.Unauthorized
                } else {
                    AttemptResult.Failed
                }
            }
        )
    }

    private suspend fun tryCredentialsLogin(): AttemptResult {
        val creds = sessionManager.getCredentials()
        if (creds == null) {
            Logger.i(tag, "credential login attempt skipped: credentials not available")
            return AttemptResult.Skipped
        }

        Logger.i(tag, "credential login attempt started")
        val loginResult = safeApiCall {
            apiService.login(LoginRequest(email = creds.first, password = creds.second))
        }

        return loginResult.fold(
            onSuccess = { response ->
                Logger.i(tag, "credential login attempt succeeded")
                persistSession(response)
                AttemptResult.Success
            },
            onFailure = { throwable ->
                Logger.w(tag, "credential login attempt failed reason=${throwable::class.simpleName}")
                if (throwable is NetworkError.Unauthorized) {
                    AttemptResult.Unauthorized
                } else {
                    AttemptResult.Failed
                }
            }
        )
    }

    private fun persistSession(response: AuthResponse) {
        val expiresInSeconds = response.expiresIn.toLongOrNull()
        sessionManager.saveSession(
            token = response.token,
            refreshToken = response.refreshToken,
            expiresInSeconds = expiresInSeconds
        )
    }

    private enum class AttemptResult {
        Success,
        Failed,
        Unauthorized,
        Skipped
    }
}
