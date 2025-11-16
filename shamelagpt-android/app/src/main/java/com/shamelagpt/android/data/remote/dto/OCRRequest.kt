package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Request model for OCR extraction (review step before fact-checking).
 *
 * @property imageBase64 Base64 encoded image string
 * @property threadId Optional thread ID to associate the image with
 * @property languageHint Optional language hint for OCR ("Arabic" or "English")
 */
data class OCRRequest(
    @SerializedName("image_base64")
    val imageBase64: String,
    @SerializedName("thread_id")
    val threadId: String? = null,
    @SerializedName("language_hint")
    val languageHint: String? = null
)
