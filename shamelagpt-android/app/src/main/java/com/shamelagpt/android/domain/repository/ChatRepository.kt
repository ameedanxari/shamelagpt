package com.shamelagpt.android.domain.repository

import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.HealthResponse

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
        saveUserMessage: Boolean = true
    ): Result<ChatResponse>

    /**
     * Checks API health status.
     *
     * @return Result with HealthResponse or error
     */
    suspend fun checkHealth(): Result<HealthResponse>
}
