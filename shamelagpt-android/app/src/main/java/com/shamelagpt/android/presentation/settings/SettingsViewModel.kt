package com.shamelagpt.android.presentation.settings

import androidx.lifecycle.ViewModel
import com.shamelagpt.android.core.util.LanguageManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * ViewModel for the Settings screen
 */
class SettingsViewModel(
    private val languageManager: LanguageManager
) : ViewModel() {

    private val _selectedLanguage = MutableStateFlow(languageManager.getLanguage())
    val selectedLanguage: StateFlow<String> = _selectedLanguage.asStateFlow()

    /**
     * Update selected language
     */
    fun updateLanguage(languageCode: String) {
        _selectedLanguage.value = languageCode
        languageManager.setLanguage(languageCode)
    }

    /**
     * Get current language
     */
    fun getCurrentLanguage(): String {
        return languageManager.getLanguage()
    }
}
