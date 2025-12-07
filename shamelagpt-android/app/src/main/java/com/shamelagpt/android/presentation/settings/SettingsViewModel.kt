package com.shamelagpt.android.presentation.settings

import androidx.lifecycle.ViewModel
import com.shamelagpt.android.core.util.LanguageManager
import com.shamelagpt.android.domain.model.ResponsePreferences
import com.shamelagpt.android.domain.model.UserPreferences
import com.shamelagpt.android.domain.repository.AuthRepository
import com.shamelagpt.android.domain.repository.PreferencesRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * ViewModel for the Settings screen
 */
class SettingsViewModel(
    private val languageManager: LanguageManager,
    private val authRepository: AuthRepository,
    private val preferencesRepository: PreferencesRepository
) : ViewModel() {

    private val _selectedLanguage = MutableStateFlow(languageManager.getLanguage())
    val selectedLanguage: StateFlow<String> = _selectedLanguage.asStateFlow()
    private val _customPrompt = MutableStateFlow("")
    val customPrompt: StateFlow<String> = _customPrompt.asStateFlow()
    private val _responsePreferences = MutableStateFlow(ResponsePreferences())
    val responsePreferences: StateFlow<ResponsePreferences> = _responsePreferences.asStateFlow()
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    init {
        CoroutineScope(Dispatchers.IO).launch {
            if (authRepository.isLoggedIn()) {
                loadPreferences()
            }
        }
    }

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

    fun updateCustomPrompt(prompt: String) {
        _customPrompt.value = prompt
    }

    fun updateResponsePreferences(length: String?, style: String?, focus: String?) {
        _responsePreferences.update {
            it.copy(length = length, style = style, focus = focus)
        }
    }

    fun savePreferences() {
        CoroutineScope(Dispatchers.IO).launch {
            val prefs = UserPreferences(
                languagePreference = _selectedLanguage.value,
                customSystemPrompt = _customPrompt.value.ifBlank { null },
                responsePreferences = _responsePreferences.value
            )
            preferencesRepository.updatePreferences(prefs)
        }
    }

    private suspend fun loadPreferences() {
        preferencesRepository.fetchPreferences().onSuccess { prefs ->
            _selectedLanguage.value = prefs.languagePreference ?: languageManager.getLanguage()
            _customPrompt.value = prefs.customSystemPrompt ?: ""
            prefs.responsePreferences?.let {
                _responsePreferences.value = it
            }
        }.onFailure {
            _error.value = it.message
        }
    }

    fun logout(onLoggedOut: () -> Unit, onError: (String) -> Unit) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                authRepository.logout()
                onLoggedOut()
            } catch (e: Exception) {
                onError(e.message ?: "Failed to logout")
            }
        }
    }
}
