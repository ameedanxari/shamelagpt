package com.shamelagpt.android.data.remote.datasource

import com.shamelagpt.android.core.network.safeApiCall
import com.shamelagpt.android.data.remote.ApiService
import com.shamelagpt.android.data.remote.dto.ConversationRequest
import com.shamelagpt.android.data.remote.dto.ConversationResponse
import com.shamelagpt.android.data.remote.dto.ConversationMessagesResponse
import com.shamelagpt.android.data.remote.dto.EmptyResponse

class ConversationRemoteDataSourceImpl(
    private val apiService: ApiService,
    private val authRetryManager: com.shamelagpt.android.core.network.AuthRetryManager
) : ConversationRemoteDataSource {

    private suspend fun <T> callWithAuth(block: suspend () -> T): Result<T> {
        return safeApiCall(authRetry = { authRetryManager.trySilentLogin() }) { block() }
    }

    override suspend fun listConversations(): Result<List<ConversationResponse>> = callWithAuth {
        apiService.listConversations()
    }

    override suspend fun createConversation(request: ConversationRequest): Result<ConversationResponse> = callWithAuth {
        apiService.createConversation(request)
    }

    override suspend fun deleteConversation(conversationId: String): Result<EmptyResponse> = callWithAuth {
        apiService.deleteConversation(conversationId)
    }

    override suspend fun deleteAllConversations(): Result<EmptyResponse> = callWithAuth {
        apiService.deleteAllConversations()
    }

    override suspend fun getMessages(conversationId: String): Result<ConversationMessagesResponse> = callWithAuth {
        apiService.getMessages(conversationId)
    }
}
