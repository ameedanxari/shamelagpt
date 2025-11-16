package com.shamelagpt.android.domain.repository

import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.HealthResponse
import com.shamelagpt.android.data.remote.dto.OCRRequest
import com.shamelagpt.android.data.remote.dto.OCRResponse
import com.shamelagpt.android.data.remote.dto.ConfirmFactCheckRequest
import com.shamelagpt.android.data.remote.dto.StreamEvent
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for chat operations.
 */
interface ChatRepository {

    /**
     * Sends a message to the API and saves the conversation locally.
     *
     * @param question User's question
     * @param conversationId ID of the conversation
     * @param threadId Optional thread ID from previous API response
     * @param saveUserMessage Whether to save the user message (false for fact-check messages where it's already saved)
     * @return Result with ChatResponse or error
     */
    suspend fun sendMessage(
        question: String,
        conversationId: String,
        threadId: String?,
        saveUserMessage: Boolean = true,
        promptConfig: com.google.gson.JsonElement? = null,
        languagePreference: String? = null,
        customSystemPrompt: String? = null,
        enableThinking: Boolean? = null
    ): Result<com.shamelagpt.android.data.remote.dto.ChatResponse>

    /**
     * Sends a message to the API and receives real-time streaming updates.
     *
     * @param question User's question
     * @param conversationId ID of the conversation
     * @param threadId Optional thread ID from previous API response
     * @return Flow of SSE StreamEvents
     */
    fun streamMessage(
        question: String,
        conversationId: String,
        threadId: String?,
        promptConfig: com.google.gson.JsonElement? = null,
        languagePreference: String? = null,
        customSystemPrompt: String? = null,
        enableThinking: Boolean? = null
    ): Flow<StreamEvent>

    /**
     * Extracts text from an image via OCR.
     */
    suspend fun ocr(request: OCRRequest): Result<OCRResponse>

    /**
     * Confirms the OCR result and starts a fact-check stream.
     */
    fun confirmFactCheck(request: ConfirmFactCheckRequest): Flow<StreamEvent>

    /**
     * Checks API health status.
     *
     * @return Result with HealthResponse or error
     */
    suspend fun checkHealth(): Result<HealthResponse>
}
