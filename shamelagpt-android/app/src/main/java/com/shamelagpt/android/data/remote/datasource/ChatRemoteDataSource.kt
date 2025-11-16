package com.shamelagpt.android.data.remote.datasource

import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.HealthResponse

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
    suspend fun sendMessage(question: String, threadId: String?): Result<ChatResponse>

    /**
     * Checks API health status.
     *
     * @return Result with HealthResponse or error
     */
    suspend fun checkHealth(): Result<HealthResponse>
}
