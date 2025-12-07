package com.shamelagpt.android.data.remote.datasource

import com.shamelagpt.android.data.remote.dto.ConversationRequest
import com.shamelagpt.android.data.remote.dto.ConversationResponse
import okhttp3.ResponseBody

interface ConversationRemoteDataSource {
    suspend fun listConversations(): Result<List<ConversationResponse>>
    suspend fun createConversation(request: ConversationRequest): Result<ConversationResponse>
    suspend fun deleteConversation(conversationId: String): Result<ResponseBody>
    suspend fun deleteAllConversations(): Result<ResponseBody>
}
