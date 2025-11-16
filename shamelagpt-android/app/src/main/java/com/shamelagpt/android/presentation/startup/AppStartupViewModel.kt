package com.shamelagpt.android.presentation.startup

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shamelagpt.android.core.network.AuthRetryManager
import com.shamelagpt.android.core.preferences.SessionManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class AppStartupViewModel(
    private val sessionManager: SessionManager,
    private val authRetryManager: AuthRetryManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(AppStartupUiState())
    val uiState: StateFlow<AppStartupUiState> = _uiState.asStateFlow()

    fun bootstrap() {
        if (!_uiState.value.isBootstrapping) return

        viewModelScope.launch {
            if (sessionManager.isLoggedIn()) {
                _uiState.value = AppStartupUiState(
                    isBootstrapping = false,
                    isAuthenticated = true
                )
                return@launch
            }

            val canAttemptRestore = !sessionManager.getRefreshToken().isNullOrBlank() ||
                sessionManager.getCredentials() != null

            if (canAttemptRestore) {
                val restored = authRetryManager.restoreSession()
                _uiState.value = AppStartupUiState(
                    isBootstrapping = false,
                    isAuthenticated = restored && sessionManager.isLoggedIn()
                )
                return@launch
            }

            _uiState.value = AppStartupUiState(
                isBootstrapping = false,
                isAuthenticated = false
            )
        }
    }
}
