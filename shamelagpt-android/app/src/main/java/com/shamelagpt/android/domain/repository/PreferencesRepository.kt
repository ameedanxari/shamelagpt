package com.shamelagpt.android.domain.repository

import com.shamelagpt.android.domain.model.UserPreferences

interface PreferencesRepository {
    suspend fun fetchPreferences(): Result<UserPreferences>
    suspend fun updatePreferences(preferences: UserPreferences): Result<Unit>
}
