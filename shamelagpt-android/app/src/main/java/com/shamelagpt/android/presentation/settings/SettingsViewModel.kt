package com.shamelagpt.android.presentation.settings

import android.util.Log
import com.shamelagpt.android.core.util.Logger
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shamelagpt.android.core.util.LanguageManager
import com.shamelagpt.android.domain.model.MadhabPreference
import com.shamelagpt.android.domain.model.ResponsePreferences
import com.shamelagpt.android.domain.model.UserPreferences
import com.shamelagpt.android.domain.repository.AuthRepository
import com.shamelagpt.android.domain.repository.ConversationRepository
import com.shamelagpt.android.domain.repository.PreferencesRepository
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
    private val preferencesRepository: PreferencesRepository,
    private val conversationRepository: ConversationRepository
) : ViewModel() {

    private val _selectedLanguage = MutableStateFlow(normalizeLanguageCode(languageManager.getLanguage()))
    val selectedLanguage: StateFlow<String> = _selectedLanguage.asStateFlow()
    private val _customPrompt = MutableStateFlow("")
    val customPrompt: StateFlow<String> = _customPrompt.asStateFlow()
    private val _responsePreferences = MutableStateFlow(ResponsePreferences())
    val responsePreferences: StateFlow<ResponsePreferences> = _responsePreferences.asStateFlow()
    private val _madhabPreference = MutableStateFlow(MadhabPreference.ALL)
    val madhabPreference: StateFlow<String> = _madhabPreference.asStateFlow()
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private val _isDeletingAccount = MutableStateFlow(false)
    val isDeletingAccount: StateFlow<Boolean> = _isDeletingAccount.asStateFlow()

    private val _deleteAccountError = MutableStateFlow(false)
    val deleteAccountError: StateFlow<Boolean> = _deleteAccountError.asStateFlow()

    init {
        viewModelScope.launch {
            _isAuthenticated.value = authRepository.isLoggedIn()
            if (_isAuthenticated.value) {
                loadPreferences()
                loadMadhabPreference()
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

    fun updateMadhabPreference(madhab: String) {
        val normalized = MadhabPreference.normalize(madhab)
        _madhabPreference.value = normalized
        viewModelScope.launch {
            authRepository.setMadhabPreference(normalized).onSuccess { response ->
                val saved = MadhabPreference.normalize(response.madhabPreference)
                _madhabPreference.value = saved
            }.onFailure { error ->
                Logger.e(TAG, "Failed to save madhab preference: ${error.message}", error)
                _error.value = error.message
                loadMadhabPreference()
            }
        }
    }

    private suspend fun loadMadhabPreference() {
        authRepository.getMadhabPreference().onSuccess { response ->
            _madhabPreference.value = MadhabPreference.normalize(response.madhabPreference)
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

    fun clearDeleteAccountError() {
        _deleteAccountError.value = false
    }

    fun deleteAccount(onSuccess: () -> Unit) {
        if (_isDeletingAccount.value) return

        viewModelScope.launch {
            _isDeletingAccount.value = true
            _deleteAccountError.value = false
            Log.d(TAG, "deleteAccount() started")

            // Wipe chats while still authenticated (server best-effort + local Room).
            try {
                conversationRepository.deleteAllConversations()
                Log.d(TAG, "deleteAccount() conversation wipe completed")
            } catch (error: Exception) {
                Log.e(TAG, "deleteAccount() conversation wipe failed; continuing with account delete", error)
            }

            val result = authRepository.deleteCurrentUser()
            result.fold(
                onSuccess = {
                    Log.d(TAG, "deleteAccount() succeeded")
                    _isAuthenticated.value = false
                    _isDeletingAccount.value = false
                    onSuccess()
                },
                onFailure = { error ->
                    Log.e(TAG, "deleteAccount() failed", error)
                    _isDeletingAccount.value = false
                    _deleteAccountError.value = true
                }
            )
        }
    }
}
