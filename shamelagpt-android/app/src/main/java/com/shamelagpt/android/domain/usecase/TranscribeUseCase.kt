package com.shamelagpt.android.domain.usecase

import com.shamelagpt.android.data.remote.dto.TranscribeResponse
import com.shamelagpt.android.domain.repository.ChatRepository

/**
 * Uploads recorded audio to `/api/transcribe` (Groq Whisper).
 */
class TranscribeUseCase(
    private val chatRepository: ChatRepository
) {
    suspend operator fun invoke(
        audioBytes: ByteArray,
        mimeType: String,
        fileName: String,
        language: String? = null
    ): Result<TranscribeResponse> {
        return chatRepository.transcribe(
            audioBytes = audioBytes,
            mimeType = mimeType,
            fileName = fileName,
            language = language
        )
    }
}
