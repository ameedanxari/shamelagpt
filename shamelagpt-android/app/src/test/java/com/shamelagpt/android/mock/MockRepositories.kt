package com.shamelagpt.android.mock

import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.HealthResponse
import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.repository.ChatRepository
import com.shamelagpt.android.domain.repository.ConversationRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map
import java.util.UUID

/**
 * Mock implementation of ChatRepository for testing.
 */
class MockChatRepository : ChatRepository {

    var sendMessageResult: Result<ChatResponse> = Result.success(TestData.sampleChatResponse)
    var checkHealthResult: Result<HealthResponse> = Result.success(HealthResponse("OK", "ShamelaGPT"))
    var sendMessageCallCount = 0
    var lastQuestion: String? = null
    var lastThreadId: String? = null
    var lastConversationId: String? = null
    var lastSaveUserMessage: Boolean? = null
    var delayMs: Long = 0

    override suspend fun sendMessage(
        question: String,
        conversationId: String,
        threadId: String?,
        saveUserMessage: Boolean
    ): Result<ChatResponse> {
        sendMessageCallCount++
        lastQuestion = question
        lastThreadId = threadId
        lastConversationId = conversationId
        lastSaveUserMessage = saveUserMessage

        if (delayMs > 0) {
            kotlinx.coroutines.delay(delayMs)
        }

        return sendMessageResult
    }

    override suspend fun checkHealth(): Result<HealthResponse> {
        return checkHealthResult
    }

    fun reset() {
        sendMessageResult = Result.success(TestData.sampleChatResponse)
        checkHealthResult = Result.success(HealthResponse("OK", "ShamelaGPT"))
        sendMessageCallCount = 0
        lastQuestion = null
        lastThreadId = null
        lastConversationId = null
        lastSaveUserMessage = null
        delayMs = 0
    }
}

/**
 * Mock implementation of ConversationRepository for testing.
 */
class MockConversationRepository : ConversationRepository {

    private val conversations = mutableMapOf<String, Conversation>()
    private val conversationsFlow = MutableStateFlow<List<Conversation>>(emptyList())
    private val messagesFlows = mutableMapOf<String, MutableStateFlow<List<Message>>>()

    var createConversationResult: Conversation? = null
    var deleteConversationError: Exception? = null

    override fun getConversations(): Flow<List<Conversation>> {
        return conversationsFlow
    }

    override suspend fun getConversationById(id: String): Conversation? {
        return conversations[id]
    }

    override suspend fun createConversation(title: String): Conversation {
        val conversation = createConversationResult ?: TestData.createConversation(
            id = UUID.randomUUID().toString(),
            title = title
        )
        conversations[conversation.id] = conversation
        emitConversations()
        return conversation
    }

    override suspend fun deleteConversation(id: String) {
        deleteConversationError?.let { throw it }
        conversations.remove(id)
        messagesFlows.remove(id)
        emitConversations()
    }

    override suspend fun deleteAllConversations() {
        conversations.clear()
        messagesFlows.clear()
        emitConversations()
    }

    override suspend fun saveMessage(message: Message, conversationId: String) {
        val conversation = conversations[conversationId] ?: return
        val updatedMessages = conversation.messages + message
        conversations[conversationId] = conversation.copy(
            messages = updatedMessages,
            updatedAt = System.currentTimeMillis()
        )
        emitMessages(conversationId, updatedMessages)
        emitConversations()
    }

    override suspend fun updateConversationThread(conversationId: String, threadId: String) {
        val conversation = conversations[conversationId] ?: return
        conversations[conversationId] = conversation.copy(
            threadId = threadId,
            updatedAt = System.currentTimeMillis()
        )
        emitConversations()
    }

    override fun getMessagesByConversationId(conversationId: String): Flow<List<Message>> {
        return messagesFlows.getOrPut(conversationId) {
            MutableStateFlow(conversations[conversationId]?.messages ?: emptyList())
        }
    }

    // Test helper methods

    fun addConversation(conversation: Conversation) {
        conversations[conversation.id] = conversation
        emitConversations()
        emitMessages(conversation.id, conversation.messages)
    }

    fun addMessage(conversationId: String, message: Message) {
        val conversation = conversations[conversationId] ?: return
        val updatedMessages = conversation.messages + message
        conversations[conversationId] = conversation.copy(messages = updatedMessages)
        emitMessages(conversationId, updatedMessages)
        emitConversations()
    }

    fun getConversationCount(): Int = conversations.size

    fun reset() {
        conversations.clear()
        conversationsFlow.value = emptyList()
        messagesFlows.clear()
        createConversationResult = null
        deleteConversationError = null
    }

    private fun emitConversations() {
        conversationsFlow.value = conversations.values
            .sortedByDescending { it.updatedAt }
    }

    private fun emitMessages(conversationId: String, messages: List<Message>) {
        messagesFlows.getOrPut(conversationId) {
            MutableStateFlow(emptyList())
        }.value = messages.sortedBy { it.timestamp }
    }
}
