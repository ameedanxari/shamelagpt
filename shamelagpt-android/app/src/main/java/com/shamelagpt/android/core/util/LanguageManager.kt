package com.shamelagpt.android.core.util

import android.content.Context
import android.util.Log
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import com.shamelagpt.android.core.preferences.PreferencesManager
import java.util.Locale

private const val TAG = "LanguageManager"

/**
 * Manages app language selection and locale updates
 */
class LanguageManager(
    private val context: Context,
    private val preferencesManager: PreferencesManager
) {
    companion object {
        const val LANGUAGE_ENGLISH = "en"
        const val LANGUAGE_ARABIC = "ar"
        const val LANGUAGE_URDU = "ur"
    }

    /**
     * Set the app language and update locale
     */
    fun setLanguage(languageCode: String) {
        Log.d(TAG, "setLanguage() called with languageCode=$languageCode")
        preferencesManager.setSelectedLanguage(languageCode)
        Log.d(TAG, "Saved language to preferences: $languageCode")
        updateLocale(languageCode)
        Log.d(TAG, "Updated locale to: $languageCode")
    }

    /**
     * Get the currently selected language
     */
    fun getLanguage(): String {
        val language = preferencesManager.getSelectedLanguage()
        Log.d(TAG, "getLanguage() returning: $language")
        return language
    }

    /**
     * Update the app locale
     */
    fun updateLocale(languageCode: String) {
        Log.d(TAG, "updateLocale() called with languageCode=$languageCode")
        if (languageCode.isBlank()) {
            Log.w(TAG, "updateLocale: languageCode is blank, skipping")
            return
        }

        val locale = Locale(languageCode)
        Locale.setDefault(locale)
        Log.d(TAG, "Locale.setDefault() called with: $locale")

        // Use AppCompat's application-wide locales API which applies dynamically
        // across activities that use AppCompat.
        val localeList = LocaleListCompat.forLanguageTags(languageCode)
        Log.d(TAG, "Calling AppCompatDelegate.setApplicationLocales() with: $languageCode")
        AppCompatDelegate.setApplicationLocales(localeList)
        Log.d(TAG, "AppCompatDelegate.setApplicationLocales() completed")
    }

    /**
     * Apply the saved language on app start
     */
    fun applySavedLanguage() {
        Log.d(TAG, "applySavedLanguage() called")
        val savedLanguage = getLanguage()
        Log.d(TAG, "Applying saved language: $savedLanguage")
        updateLocale(savedLanguage)
        Log.d(TAG, "applySavedLanguage() completed")
    }
}
