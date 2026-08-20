package com.shamelagpt.android.core.network

import com.shamelagpt.android.core.preferences.SessionManager
import com.shamelagpt.android.core.util.Logger
import com.shamelagpt.android.data.remote.dto.AuthResponse
import com.shamelagpt.android.data.remote.ApiService
import com.shamelagpt.android.data.remote.dto.RefreshTokenRequest

/** Restores session via refresh token only. */
class AuthRetryManager(
    private val sessionManager: SessionManager,
    private val apiService: ApiService
) {
    private val tag = "AuthRetryManager"

    suspend fun restoreSession(): Boolean {
        Logger.i(tag, "session restore started")
        sessionManager.clearCredentials()

        when (tryRefreshToken()) {
            AttemptResult.Success -> return true
            AttemptResult.Unauthorized -> {
                Logger.w(tag, "refresh token unauthorized; clearing session")
                sessionManager.clearSession()
            }
            AttemptResult.Failed,
            AttemptResult.Skipped -> Unit
        }

        Logger.i(tag, "session restore failed")
        return false
    }

    suspend fun trySilentLogin(): Boolean = restoreSession()

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
