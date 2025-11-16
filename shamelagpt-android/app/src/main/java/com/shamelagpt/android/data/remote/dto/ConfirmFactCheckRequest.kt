package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Request model for confirming and fact-checking reviewed text.
 *
 * @property reviewedText User-confirmed text from OCR
 * @property imageUrl The S3 URL of the uploaded image
 * @property threadId Optional thread ID to associate the fact-check with
 * @property languagePreference Optional language preference ("Arabic" or "English")
 * @property enableThinking Whether to enable chain-of-thought thinking
 */
data class ConfirmFactCheckRequest(
    @SerializedName("reviewed_text")
    val reviewedText: String,
    @SerializedName("image_url")
    val imageUrl: String? = null,
    @SerializedName("image_base64")
    val imageBase64: String? = null,
    @SerializedName("thread_id")
    val threadId: String? = null,
    @SerializedName("language_preference")
    val languagePreference: String? = null,
    @SerializedName("enable_thinking")
    val enableThinking: Boolean? = true
)
