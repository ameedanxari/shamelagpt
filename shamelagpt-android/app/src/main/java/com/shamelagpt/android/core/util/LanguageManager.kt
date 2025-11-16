package com.shamelagpt.android.core.util

import android.content.Context
import com.shamelagpt.android.core.preferences.PreferencesManager
import java.util.Locale

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
    }

    /**
     * Set the app language and update locale
     */
    fun setLanguage(languageCode: String) {
        preferencesManager.setSelectedLanguage(languageCode)
        updateLocale(languageCode)
    }

    /**
     * Get the currently selected language
     */
    fun getLanguage(): String {
        return preferencesManager.getSelectedLanguage()
    }

    /**
     * Update the app locale
     */
    fun updateLocale(languageCode: String) {
        val locale = Locale(languageCode)
        Locale.setDefault(locale)

        val config = context.resources.configuration
        config.setLocale(locale)
        context.createConfigurationContext(config)
    }

    /**
     * Apply the saved language on app start
     */
    fun applySavedLanguage() {
        val savedLanguage = getLanguage()
        updateLocale(savedLanguage)
    }
}
