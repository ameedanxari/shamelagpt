package com.shamelagpt.android.presentation.settings

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
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

private const val TAG = "SettingsViewModel"

/**
 * ViewModel for the Settings screen
 */
class SettingsViewModel(
    private val languageManager: LanguageManager,
    private val authRepository: AuthRepository,
    private val preferencesRepository: PreferencesRepository
) : ViewModel() {

    private val _selectedLanguage = MutableStateFlow(normalizeLanguageCode(languageManager.getLanguage()))
    val selectedLanguage: StateFlow<String> = _selectedLanguage.asStateFlow()
    private val _customPrompt = MutableStateFlow("")
    val customPrompt: StateFlow<String> = _customPrompt.asStateFlow()
    private val _responsePreferences = MutableStateFlow(ResponsePreferences())
    val responsePreferences: StateFlow<ResponsePreferences> = _responsePreferences.asStateFlow()
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    // Mode preference: 0 = default/research, 1 = research, 2 = fact_check
    private val _modePreference = MutableStateFlow(0)
    val modePreference: StateFlow<Int> = _modePreference.asStateFlow()
    private val _isModeLoading = MutableStateFlow(false)
    val isModeLoading: StateFlow<Boolean> = _isModeLoading.asStateFlow()

    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    init {
        viewModelScope.launch {
            _isAuthenticated.value = authRepository.isLoggedIn()
            if (_isAuthenticated.value) {
                loadPreferences()
                loadModePreference()
            }
        }
    }

    /**
     * Update selected language
     */
    fun updateLanguage(languageCode: String) {
        val normalized = normalizeLanguageCode(languageCode)
        Log.d(TAG, "updateLanguage() called with languageCode=$languageCode normalized=$normalized")
        Log.d(TAG, "Current language before update: ${_selectedLanguage.value}")
        _selectedLanguage.value = normalized
        Log.d(TAG, "Updated _selectedLanguage state to: $normalized")
        languageManager.setLanguage(normalized)
        Log.d(TAG, "updateLanguage() completed for: $normalized")
    }

    /**
     * Get current language
     */
    fun getCurrentLanguage(): String {
        val current = normalizeLanguageCode(languageManager.getLanguage())
        Log.d(TAG, "getCurrentLanguage() returning: $current")
        return current
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
        Log.d(TAG, "savePreferences() called")
        Log.d(TAG, "Current language preference to save: ${_selectedLanguage.value}")
        viewModelScope.launch {
            val prefs = UserPreferences(
                languagePreference = _selectedLanguage.value,
                customSystemPrompt = _customPrompt.value.ifBlank { null },
                responsePreferences = _responsePreferences.value
            )
            Log.d(TAG, "Saving preferences with language: ${prefs.languagePreference}")
            preferencesRepository.updatePreferences(prefs)
            Log.d(TAG, "savePreferences() completed")
        }
    }

    private suspend fun loadModePreference() {
        authRepository.getModePreference().onSuccess { response ->
            _modePreference.value = response.modePreference
        }.onFailure {
            Log.e(TAG, "Failed to load mode preference: ${it.message}")
        }
    }

    fun updateModePreference(mode: Int) {
        _isModeLoading.value = true
        viewModelScope.launch {
            authRepository.setModePreference(mode).onSuccess { response ->
                _modePreference.value = response.modePreference
                Log.d(TAG, "Mode preference updated to: ${response.modeName}")
            }.onFailure {
                Log.e(TAG, "Failed to update mode preference: ${it.message}")
                _error.value = it.message
            }
            _isModeLoading.value = false
        }
    }

    private suspend fun loadPreferences() {
        preferencesRepository.fetchPreferences().onSuccess { prefs ->
            // Keep currently-applied app language authoritative for runtime UX.
            // Server/cached preferences may lag and should not override locale when opening Settings.
            val activeLanguage = normalizeLanguageCode(languageManager.getLanguage())
            _selectedLanguage.value = activeLanguage
            _customPrompt.value = prefs.customSystemPrompt ?: ""
            prefs.responsePreferences?.let {
                _responsePreferences.value = it
            }
        }.onFailure {
            _error.value = it.message
        }
    }

    private fun normalizeLanguageCode(raw: String?): String {
        val value = raw?.trim()?.lowercase().orEmpty()
        return when (value) {
            "ar", "arabic" -> LanguageManager.LANGUAGE_ARABIC
            "ur", "urdu" -> LanguageManager.LANGUAGE_URDU
            "en", "english", "" -> LanguageManager.LANGUAGE_ENGLISH
            else -> LanguageManager.LANGUAGE_ENGLISH
        }
    }

    fun logout(onLoggedOut: () -> Unit, onError: (String) -> Unit) {
        viewModelScope.launch {
            try {
                authRepository.logout()
                _isAuthenticated.value = false
                onLoggedOut()
            } catch (e: Exception) {
                onError(e.message ?: "Failed to logout")
            }
        }
    }
}
