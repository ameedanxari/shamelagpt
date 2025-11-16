package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Request payload for user preferences.
 */
data class UserPreferencesRequest(
    @SerializedName("language_preference")
    val languagePreference: String?,
    @SerializedName("custom_system_prompt")
    val customSystemPrompt: String?,
    @SerializedName("response_preferences")
    val responsePreferences: ResponsePreferencesRequest?
)
