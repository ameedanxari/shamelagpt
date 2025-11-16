package com.shamelagpt.android.domain.model

data class UserPreferences(
    val languagePreference: String? = null,
    val customSystemPrompt: String? = null,
    val responsePreferences: ResponsePreferences? = null
)

data class ResponsePreferences(
    val length: String? = null,
    val style: String? = null,
    val focus: String? = null
)
