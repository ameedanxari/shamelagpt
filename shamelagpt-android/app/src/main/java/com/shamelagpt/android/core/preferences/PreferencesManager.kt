package com.shamelagpt.android.core.preferences

import android.content.Context
import android.content.SharedPreferences

/**
 * Manages app preferences using SharedPreferences
 */
class PreferencesManager(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    companion object {
        private const val PREFS_NAME = "app_prefs"
        private const val KEY_HAS_SEEN_WELCOME = "has_seen_welcome"
        private const val KEY_SELECTED_LANGUAGE = "selected_language"
        private const val DEFAULT_LANGUAGE = "en"
    }

    /**
     * Check if user has seen the welcome screen
     */
    fun hasSeenWelcome(): Boolean {
        return prefs.getBoolean(KEY_HAS_SEEN_WELCOME, false)
    }

    /**
     * Mark that user has seen the welcome screen
     */
    fun setHasSeenWelcome(hasSeen: Boolean) {
        prefs.edit().putBoolean(KEY_HAS_SEEN_WELCOME, hasSeen).apply()
    }

    /**
     * Get selected language code
     */
    fun getSelectedLanguage(): String {
        return prefs.getString(KEY_SELECTED_LANGUAGE, DEFAULT_LANGUAGE) ?: DEFAULT_LANGUAGE
    }

    /**
     * Set selected language code
     */
    fun setSelectedLanguage(languageCode: String) {
        prefs.edit().putString(KEY_SELECTED_LANGUAGE, languageCode).apply()
    }
}
