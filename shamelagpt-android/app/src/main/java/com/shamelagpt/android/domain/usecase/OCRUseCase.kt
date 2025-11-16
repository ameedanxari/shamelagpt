package com.shamelagpt.android.domain.usecase

import com.shamelagpt.android.data.remote.dto.OCRRequest
import com.shamelagpt.android.data.remote.dto.OCRResponse
import com.shamelagpt.android.domain.repository.ChatRepository

/**
 * Use case for backend-driven OCR extraction.
 */
class OCRUseCase(
    private val chatRepository: ChatRepository
) {
    /**
     * Extracts text from an image.
     *
     * @param imageBase64 Base64 encoded image
     * @param threadId Optional thread ID
     * @param languageHint Optional language hint
     * @return Result with OCRResponse
     */
    suspend operator fun invoke(
        imageBase64: String,
        threadId: String? = null,
        languageHint: String? = null
    ): Result<OCRResponse> {
        val request = OCRRequest(
            imageBase64 = imageBase64,
            threadId = threadId,
            languageHint = languageHint
        )
        return chatRepository.ocr(request)
    }
}
