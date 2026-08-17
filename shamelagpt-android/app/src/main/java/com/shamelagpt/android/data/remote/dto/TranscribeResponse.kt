package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Response from POST /api/transcribe (Groq Whisper).
 */
data class TranscribeResponse(
    @SerializedName("text")
    val text: String,
    @SerializedName("language")
    val language: String? = null
)
