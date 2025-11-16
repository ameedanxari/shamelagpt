package com.shamelagpt.android.data.remote

import com.shamelagpt.android.data.remote.dto.ChatRequest
import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.HealthResponse
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST

/**
 * Retrofit API service interface for ShamelaGPT API.
 */
interface ApiService {

    /**
     * Health check endpoint.
     *
     * @return Health status response
     */
    @GET("api/health")
    suspend fun checkHealth(): HealthResponse

    /**
     * Chat endpoint - sends a message and receives AI response.
     *
     * @param request Chat request containing question and optional thread ID
     * @return Chat response with answer and thread ID
     */
    @POST("api/chat")
    suspend fun sendMessage(@Body request: ChatRequest): ChatResponse
}
