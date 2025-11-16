package com.shamelagpt.android.data.remote.datasource

import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.HealthResponse
import com.shamelagpt.android.data.remote.dto.OCRRequest
import com.shamelagpt.android.data.remote.dto.OCRResponse
import com.shamelagpt.android.data.remote.dto.ConfirmFactCheckRequest
import com.shamelagpt.android.data.remote.dto.StreamEvent

/**
 * Interface for chat remote data source.
 */
interface ChatRemoteDataSource {

    /**
     * Sends a message to the chat API.
     *
     * @param question User's question
     * @param threadId Optional thread ID for continuing conversation
     * @return Result with ChatResponse or error
     */
    suspend fun sendMessage(
        question: String,
        threadId: String?,
        promptConfig: com.google.gson.JsonElement? = null,
        languagePreference: String? = null,
        customSystemPrompt: String? = null,
        enableThinking: Boolean? = null
    ): Result<com.shamelagpt.android.data.remote.dto.ChatResponse>

    /**
     * Sends a guest/local-only chat message to the guest endpoint.
     *
     * @param question User's question
     * @param sessionId Session identifier to maintain guest conversation continuity
     * @return Result with ChatResponse or error
     */
    suspend fun sendGuestMessage(
        question: String,
        sessionId: String?,
        promptConfig: com.google.gson.JsonElement? = null,
        languagePreference: String? = null,
        customSystemPrompt: String? = null,
        enableThinking: Boolean? = null
    ): Result<com.shamelagpt.android.data.remote.dto.ChatResponse>

    /**
     * Sends a message to the chat API and receives real-time streaming updates.
     *
     * @param question User's question
     * @param threadId Optional thread ID for continuing conversation
     * @return Flow of SSE StreamEvents
     */
    fun streamMessage(
        question: String,
        threadId: String?,
        promptConfig: com.google.gson.JsonElement? = null,
        languagePreference: String? = null,
        customSystemPrompt: String? = null,
        enableThinking: Boolean? = null
    ): kotlinx.coroutines.flow.Flow<com.shamelagpt.android.data.remote.dto.StreamEvent>

    /**
     * Sends a guest chat message and receives real-time streaming updates.
     *
     * @param question User's question
     * @param sessionId Session identifier
     * @return Flow of SSE StreamEvents
     */
    fun streamGuestMessage(
        question: String,
        sessionId: String?,
        promptConfig: com.google.gson.JsonElement? = null,
        languagePreference: String? = null,
        customSystemPrompt: String? = null,
        enableThinking: Boolean? = null
    ): kotlinx.coroutines.flow.Flow<com.shamelagpt.android.data.remote.dto.StreamEvent>

    /**
     * Extracts text from an image via OCR.
     */
    suspend fun ocr(request: OCRRequest): Result<OCRResponse>

    /**
     * Confirms the OCR result and starts a fact-check stream.
     */
    fun confirmFactCheck(request: ConfirmFactCheckRequest): kotlinx.coroutines.flow.Flow<StreamEvent>

    /**
     * Checks API health status.
     *
     * @return Result with HealthResponse or error
     */
    suspend fun checkHealth(): Result<HealthResponse>
}
