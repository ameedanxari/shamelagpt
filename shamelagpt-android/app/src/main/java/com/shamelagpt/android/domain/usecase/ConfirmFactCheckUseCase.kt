package com.shamelagpt.android.domain.usecase

import com.shamelagpt.android.data.remote.dto.ConfirmFactCheckRequest
import com.shamelagpt.android.data.remote.dto.StreamEvent
import com.shamelagpt.android.domain.repository.ChatRepository
import kotlinx.coroutines.flow.Flow

/**
 * Use case for confirming OCR and starting fact-check stream.
 */
class ConfirmFactCheckUseCase(
    private val chatRepository: ChatRepository
) {
    /**
     * Confirms text and starts streaming.
     *
     * @param reviewedText User-confirmed text
     * @param imageUrl S3 URL from OCR step
     * @param threadId Optional thread ID
     * @param languagePreference Optional language preference
     * @param enableThinking Whether to enable thinking
     * @return Flow of StreamEvents
     */
    operator fun invoke(
        reviewedText: String,
        imageUrl: String? = null,
        imageBase64: String? = null,
        threadId: String? = null,
        languagePreference: String? = null,
        enableThinking: Boolean? = true
    ): Flow<StreamEvent> {
        val request = ConfirmFactCheckRequest(
            reviewedText = reviewedText,
            imageUrl = imageUrl,
            imageBase64 = imageBase64,
            threadId = threadId,
            languagePreference = languagePreference,
            enableThinking = enableThinking
        )
        return chatRepository.confirmFactCheck(request)
    }
}
