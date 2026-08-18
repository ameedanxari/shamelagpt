package com.shamelagpt.android.data.remote.datasource

import com.shamelagpt.android.data.remote.dto.ConversationRequest
import com.shamelagpt.android.data.remote.dto.ConversationResponse
import com.shamelagpt.android.data.remote.dto.ConversationMessagesResponse
import com.shamelagpt.android.data.remote.dto.EmptyResponse
import com.shamelagpt.android.data.remote.dto.ShareStatusResponse

interface ConversationRemoteDataSource {
    suspend fun listConversations(): Result<List<ConversationResponse>>
    suspend fun createConversation(request: ConversationRequest): Result<ConversationResponse>
    suspend fun deleteConversation(conversationId: String): Result<EmptyResponse>
    suspend fun deleteAllConversations(): Result<EmptyResponse>
    suspend fun getMessages(conversationId: String): Result<ConversationMessagesResponse>
    suspend fun setShareStatus(conversationId: String, isShared: Boolean): Result<ShareStatusResponse>
}
