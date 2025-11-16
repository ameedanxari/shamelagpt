package com.shamelagpt.android.core.preferences

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

private const val TAG = "PreferencesManager"

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
        val seen = prefs.getBoolean(KEY_HAS_SEEN_WELCOME, false)
        Log.d(TAG, "hasSeenWelcome() returning: $seen")
        return seen
    }

    /**
     * Mark that user has seen the welcome screen
     */
    fun setHasSeenWelcome(hasSeen: Boolean) {
        Log.d(TAG, "setHasSeenWelcome() called with: $hasSeen")
        prefs.edit().putBoolean(KEY_HAS_SEEN_WELCOME, hasSeen).apply()
        Log.d(TAG, "setHasSeenWelcome() completed")
    }

    /**
     * Get selected language code
     */
    fun getSelectedLanguage(): String {
        val language = prefs.getString(KEY_SELECTED_LANGUAGE, DEFAULT_LANGUAGE) ?: DEFAULT_LANGUAGE
        Log.d(TAG, "getSelectedLanguage() returning: $language")
        return language
    }

    /**
     * Set selected language code
     */
    fun setSelectedLanguage(languageCode: String) {
        Log.d(TAG, "setSelectedLanguage() called with: $languageCode")
        prefs.edit().putString(KEY_SELECTED_LANGUAGE, languageCode).apply()
        Log.d(TAG, "setSelectedLanguage() completed for: $languageCode")
    }
}
