package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Response model for OCR extraction.
 *
 * @property extractedText The text extracted from the image
 * @property imageUrl The S3 URL where the image was saved
 * @property metadata Additional metadata about the OCR process
 */
data class OCRResponse(
    @SerializedName("extracted_text")
    val extractedText: String,
    @SerializedName("image_url")
    val imageUrl: String,
    @SerializedName("metadata")
    val metadata: OCRMetadata
)

/**
 * Metadata for OCR response.
 */
data class OCRMetadata(
    @SerializedName("success")
    val success: Boolean,
    @SerializedName("detected_language")
    val detectedLanguage: String?,
    @SerializedName("confidence")
    val confidence: String?,
    @SerializedName("text_length")
    val textLength: Int
)
