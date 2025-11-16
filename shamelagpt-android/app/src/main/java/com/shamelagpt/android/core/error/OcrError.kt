package com.shamelagpt.android.core.error

import androidx.annotation.StringRes
import com.shamelagpt.android.R

sealed class OcrError(
    val debugCode: String,
    @StringRes val messageRes: Int
) : Exception() {
    object InvalidImage : OcrError("E-OCR-001", R.string.ocr_error_invalid_image)
    object NoTextFound : OcrError("E-OCR-002", R.string.ocr_error_no_text)
    data class RecognitionFailed(val reason: String? = null) : OcrError("E-OCR-003", R.string.ocr_error_failed)
    object ImageDataMissing : OcrError("E-OCR-004", R.string.ocr_error_image_data_missing)
}
