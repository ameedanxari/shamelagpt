package com.shamelagpt.android.data.remote.datasource

import com.shamelagpt.android.core.network.safeApiCall
import com.shamelagpt.android.data.remote.ApiService
import com.shamelagpt.android.data.remote.dto.ChatRequest
import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.HealthResponse

/**
 * Implementation of ChatRemoteDataSource using Retrofit.
 *
 * @property apiService Retrofit API service
 */
class ChatRemoteDataSourceImpl(
    private val apiService: ApiService
) : ChatRemoteDataSource {

    override suspend fun sendMessage(question: String, threadId: String?): Result<ChatResponse> {
        return safeApiCall {
            val request = ChatRequest(
                question = question,
                threadId = threadId,
                userId = null // Not used currently
            )
            apiService.sendMessage(request)
        }
    }

    override suspend fun checkHealth(): Result<HealthResponse> {
        return safeApiCall {
            apiService.checkHealth()
        }
    }
}
