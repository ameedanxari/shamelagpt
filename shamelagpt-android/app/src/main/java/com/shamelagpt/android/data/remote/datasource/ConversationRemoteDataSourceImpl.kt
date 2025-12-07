package com.shamelagpt.android.data.remote.datasource

import com.shamelagpt.android.core.network.safeApiCall
import com.shamelagpt.android.data.remote.ApiService
import com.shamelagpt.android.data.remote.dto.ConversationRequest
import com.shamelagpt.android.data.remote.dto.ConversationResponse
import okhttp3.ResponseBody

class ConversationRemoteDataSourceImpl(
    private val apiService: ApiService
) : ConversationRemoteDataSource {

    override suspend fun listConversations(): Result<List<ConversationResponse>> = safeApiCall {
        apiService.listConversations()
    }

    override suspend fun createConversation(request: ConversationRequest): Result<ConversationResponse> = safeApiCall {
        apiService.createConversation(request)
    }

    override suspend fun deleteConversation(conversationId: String): Result<ResponseBody> = safeApiCall {
        apiService.deleteConversation(conversationId)
    }

    override suspend fun deleteAllConversations(): Result<ResponseBody> = safeApiCall {
        apiService.deleteAllConversations()
    }
}
