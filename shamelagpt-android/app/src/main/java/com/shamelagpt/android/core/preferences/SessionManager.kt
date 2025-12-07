package com.shamelagpt.android.core.preferences

import android.content.Context
import android.content.SharedPreferences
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
        prefs.edit()
            .putString(KEY_TOKEN, token)
            .putString(KEY_REFRESH_TOKEN, refreshToken)
            .putLong(KEY_EXPIRES_AT, expiresInSeconds?.let { nowMs() + TimeUnit.SECONDS.toMillis(it) } ?: 0L)
            .apply()
    }

    fun clearSession() {
        prefs.edit()
            .remove(KEY_TOKEN)
            .remove(KEY_REFRESH_TOKEN)
            .remove(KEY_EXPIRES_AT)
            .apply()
    }

    fun getToken(): String? {
        val token = prefs.getString(KEY_TOKEN, null)
        val expiresAt = prefs.getLong(KEY_EXPIRES_AT, 0L)
        return if (token != null && (expiresAt == 0L || expiresAt > nowMs())) token else null
    }

    fun getRefreshToken(): String? = prefs.getString(KEY_REFRESH_TOKEN, null)

    fun isLoggedIn(): Boolean = getToken() != null

    private fun nowMs() = System.currentTimeMillis()

    private companion object {
        private const val PREFS_NAME = "session_prefs"
        private const val KEY_TOKEN = "token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
        private const val KEY_EXPIRES_AT = "expires_at"
    }
}
