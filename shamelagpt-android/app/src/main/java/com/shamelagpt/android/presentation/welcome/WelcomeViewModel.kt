package com.shamelagpt.android.presentation.welcome

import androidx.lifecycle.ViewModel
import com.shamelagpt.android.core.preferences.PreferencesManager

/**
 * ViewModel for the Welcome screen
 */
class WelcomeViewModel(
    private val preferencesManager: PreferencesManager
) : ViewModel() {

    /**
     * Check if user has seen welcome screen
     */
    fun hasSeenWelcome(): Boolean {
        return preferencesManager.hasSeenWelcome()
    }

    /**
     * Mark that user has completed welcome screen
     */
    fun completeWelcome() {
        preferencesManager.setHasSeenWelcome(true)
    }
}
