package com.shamelagpt.android.core.preferences

import android.content.Context

/**
 * Simple disk cache for storing the last-known user preferences JSON.
 * This mirrors the iOS approach of returning cached preferences immediately
 * while refreshing from network in the background.
 */
class PreferencesCache(context: Context) {

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun getCachedJson(): String? = prefs.getString(KEY_CACHED_PREFS, null)

    fun saveCachedJson(json: String) {
        prefs.edit().putString(KEY_CACHED_PREFS, json).apply()
    }

    fun clear() {
        prefs.edit().remove(KEY_CACHED_PREFS).apply()
    }

    private companion object {
        private const val PREFS_NAME = "user_prefs_cache"
        private const val KEY_CACHED_PREFS = "cached_user_preferences_json"
    }
}
