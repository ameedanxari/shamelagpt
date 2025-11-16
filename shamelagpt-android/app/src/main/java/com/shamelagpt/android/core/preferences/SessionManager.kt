package com.shamelagpt.android.core.preferences

import android.content.Context
import android.content.SharedPreferences
import com.shamelagpt.android.core.util.Logger
import java.util.concurrent.TimeUnit

/**
 * Handles persisted auth session (tokens and metadata).
 */
class SessionManager(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun saveSession(
        token: String,
        refreshToken: String?,
        expiresInSeconds: Long?
    ) {
        Logger.i(
            TAG,
            "saveSession called refreshTokenPresent=${!refreshToken.isNullOrBlank()} hasExpiry=${expiresInSeconds != null}"
        )
        prefs.edit()
            .putString(KEY_TOKEN, token)
            .putString(KEY_REFRESH_TOKEN, refreshToken)
            .putLong(KEY_EXPIRES_AT, expiresInSeconds?.let { nowMs() + TimeUnit.SECONDS.toMillis(it) } ?: 0L)
            .apply()
    }

    fun clearSession() {
        Logger.i(TAG, "clearSession called")
        prefs.edit()
            .remove(KEY_TOKEN)
            .remove(KEY_REFRESH_TOKEN)
            .remove(KEY_EXPIRES_AT)
            .apply()
    }

    fun getToken(): String? {
        val token = prefs.getString(KEY_TOKEN, null)
        val expiresAt = prefs.getLong(KEY_EXPIRES_AT, 0L)
        if (token == null) return null

        if (expiresAt != 0L && expiresAt <= nowMs()) {
            Logger.w(TAG, "token considered expired by local expiry timestamp")
            return null
        }
        return token
    }

    fun getRefreshToken(): String? = prefs.getString(KEY_REFRESH_TOKEN, null)

    fun isLoggedIn(): Boolean = getToken() != null

    // Credential storage for silent re-login
    fun saveCredentials(email: String, password: String) {
        Logger.i(TAG, "saveCredentials called")
        prefs.edit()
            .putString(KEY_EMAIL, email)
            .putString(KEY_PASSWORD, password)
            .apply()
    }

    fun getCredentials(): Pair<String, String>? {
        val email = prefs.getString(KEY_EMAIL, null)
        val password = prefs.getString(KEY_PASSWORD, null)
        return if (!email.isNullOrBlank() && !password.isNullOrBlank()) {
            email to password
        } else null
    }

    fun clearCredentials() {
        Logger.i(TAG, "clearCredentials called")
        prefs.edit()
            .remove(KEY_EMAIL)
            .remove(KEY_PASSWORD)
            .apply()
    }

    private fun nowMs() = System.currentTimeMillis()

    private companion object {
        private const val TAG = "SessionManager"
        private const val PREFS_NAME = "session_prefs"
        private const val KEY_TOKEN = "token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
        private const val KEY_EXPIRES_AT = "expires_at"
        private const val KEY_EMAIL = "auth_email"
        private const val KEY_PASSWORD = "auth_password"
    }
}
