package com.shamelagpt.android.mock

import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.HealthResponse
import com.shamelagpt.android.data.remote.dto.StreamEvent
import com.shamelagpt.android.data.remote.dto.OCRRequest
import com.shamelagpt.android.data.remote.dto.OCRResponse
import com.shamelagpt.android.data.remote.dto.OCRMetadata
import com.shamelagpt.android.data.remote.dto.ConfirmFactCheckRequest
import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.repository.ChatRepository
import com.shamelagpt.android.domain.repository.ConversationRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import java.util.UUID

/**
 * Mock implementation of ChatRepository for testing.
 *
 * This mock mimics the real ChatRepositoryImpl behavior by actually saving
 * messages to the provided ConversationRepository, just like the real implementation does.
 */
class MockChatRepository(
    private val conversationRepository: ConversationRepository? = null
) : ChatRepository {

    var sendMessageResult: Result<ChatResponse> = Result.success(TestData.sampleChatResponse)
    var checkHealthResult: Result<HealthResponse> = Result.success(HealthResponse("OK", "ShamelaGPT"))
    var sendMessageCallCount = 0
    var streamMessageCallCount = 0
    var confirmFactCheckCallCount = 0
    var lastQuestion: String? = null
    var lastThreadId: String? = null
    var lastConversationId: String? = null
    var lastSaveUserMessage: Boolean? = null
    var lastLanguagePreference: String? = null
    var lastEnableThinking: Boolean? = null
    var lastConfirmFactCheckRequest: ConfirmFactCheckRequest? = null
    var delayMs: Long = 0

    override suspend fun sendMessage(
        question: String,
        conversationId: String,
        threadId: String?,
        saveUserMessage: Boolean,
        promptConfig: com.google.gson.JsonElement?,
        languagePreference: String?,
        customSystemPrompt: String?,
        enableThinking: Boolean?
    ): Result<ChatResponse> {
        sendMessageCallCount++
        lastQuestion = question
        lastThreadId = threadId
        lastConversationId = conversationId
        lastSaveUserMessage = saveUserMessage
        lastLanguagePreference = languagePreference
        lastEnableThinking = enableThinking

        if (delayMs > 0) {
            kotlinx.coroutines.delay(delayMs)
        }

        // Mimic real ChatRepositoryImpl behavior: save user message if requested
        if (saveUserMessage && conversationRepository != null) {
            val userMessage = Message(
                id = UUID.randomUUID().toString(),
                content = question,
                isUserMessage = true,
                timestamp = System.currentTimeMillis(),
                sources = null
            )
            conversationRepository.saveMessage(userMessage, conversationId)
        }

        // If API call succeeded, save AI response (mimicking real behavior)
        sendMessageResult.onSuccess { response ->
            if (conversationRepository != null) {
                // Parse response to extract sources (using simplified logic for mock)
                val (cleanContent, sources) = com.shamelagpt.android.data.remote.ResponseParser.parseAnswer(response.answer)

                val aiMessage = Message(
                    id = UUID.randomUUID().toString(),
                    content = cleanContent,
                    isUserMessage = false,
                    timestamp = System.currentTimeMillis(),
                    sources = sources.ifEmpty { null }
                )
                conversationRepository.saveMessage(aiMessage, conversationId)

                // Update thread ID
                conversationRepository.updateConversationThread(conversationId, response.threadId)
            }
        }

        return sendMessageResult
    }

    override fun streamMessage(
        question: String,
        conversationId: String,
        threadId: String?,
        promptConfig: com.google.gson.JsonElement?,
        languagePreference: String?,
        customSystemPrompt: String?,
        enableThinking: Boolean?
    ): Flow<StreamEvent> = flow {
        streamMessageCallCount++
        lastQuestion = question
        lastThreadId = threadId
        lastConversationId = conversationId
        lastLanguagePreference = languagePreference
        lastEnableThinking = enableThinking
        
        // Handle result failure
        sendMessageResult.onFailure { throw it }

        if (delayMs > 0) {
            kotlinx.coroutines.delay(delayMs)
        }

        // Emit metadata if successful
        sendMessageResult.onSuccess { response ->
            emit(StreamEvent(type = "metadata", threadId = response.threadId))
        }

        // Simple mock streaming implementation
        emit(StreamEvent(type = "chunk", content = "Mock response chunk"))
        emit(StreamEvent(type = "done", content = "Mock response complete"))
    }

    override suspend fun checkHealth(): Result<HealthResponse> {
        return checkHealthResult
    }

    override suspend fun ocr(request: OCRRequest): Result<OCRResponse> {
        return Result.success(OCRResponse(
            extractedText = "Mock OCR text",
            imageUrl = "https://mock-s3-url.com/image.jpg",
            metadata = OCRMetadata(
                success = true,
                detectedLanguage = "en",
                confidence = "0.95",
                textLength = 13
            )
        ))
    }

    override fun confirmFactCheck(request: ConfirmFactCheckRequest): Flow<StreamEvent> = flow {
        confirmFactCheckCallCount++
        lastConfirmFactCheckRequest = request
        if (delayMs > 0) {
            kotlinx.coroutines.delay(delayMs)
        }
        emit(StreamEvent(type = "chunk", content = "Mock fact-check response"))
        emit(StreamEvent(type = "done", content = "Mock fact-check complete"))
    }

    fun reset() {
        sendMessageResult = Result.success(TestData.sampleChatResponse)
        checkHealthResult = Result.success(HealthResponse("OK", "ShamelaGPT"))
        sendMessageCallCount = 0
        lastQuestion = null
        lastThreadId = null
        lastConversationId = null
        lastSaveUserMessage = null
        lastLanguagePreference = null
        lastEnableThinking = null
        lastConfirmFactCheckRequest = null
        streamMessageCallCount = 0
        confirmFactCheckCallCount = 0
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

    override suspend fun fetchMessages(conversationId: String, forceRefresh: Boolean): Result<Unit> {
        return Result.success(Unit)
    }

    override suspend fun syncConversations(forceRefresh: Boolean): Result<Unit> = Result.success(Unit)

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

/**
 * Mock implementation of AuthRepository for testing.
 */
class MockAuthRepository : com.shamelagpt.android.domain.repository.AuthRepository {
    override suspend fun signup(request: com.shamelagpt.android.data.remote.dto.SignupRequest): Result<com.shamelagpt.android.data.remote.dto.AuthResponse> = Result.success(TestData.sampleAuthResponse)
    override suspend fun login(request: com.shamelagpt.android.data.remote.dto.LoginRequest): Result<com.shamelagpt.android.data.remote.dto.AuthResponse> = Result.success(TestData.sampleAuthResponse)
    override suspend fun forgotPassword(email: String): Result<Unit> = Result.success(Unit)
    override suspend fun googleSignIn(idToken: String): Result<com.shamelagpt.android.data.remote.dto.AuthResponse> = Result.success(TestData.sampleAuthResponse)
    override suspend fun refreshToken(refreshToken: String): Result<com.shamelagpt.android.data.remote.dto.AuthResponse> = Result.success(TestData.sampleAuthResponse)
    override suspend fun getCurrentUser(): Result<com.shamelagpt.android.data.remote.dto.UserResponse> = Result.success(com.shamelagpt.android.data.remote.dto.UserResponse(
        id = "1",
        firebaseUid = "uid",
        email = "test@example.com",
        displayName = "Test User",
        createdAt = "2026-01-12",
        updatedAt = "2026-01-12",
        lastLogin = "2026-01-12"
    ))
    override suspend fun updateCurrentUser(request: com.shamelagpt.android.data.remote.dto.UpdateUserRequest): Result<com.shamelagpt.android.data.remote.dto.UserResponse> = Result.success(com.shamelagpt.android.data.remote.dto.UserResponse(
        id = "1",
        firebaseUid = "uid",
        email = "test@example.com",
        displayName = request.display_name ?: "Test User",
        createdAt = "2026-01-12",
        updatedAt = "2026-01-12",
        lastLogin = "2026-01-12"
    ))
    override suspend fun deleteCurrentUser(): Result<Unit> = Result.success(Unit)
    override suspend fun verifyToken(): Result<Unit> = Result.success(Unit)
    override suspend fun getPreferences(): Result<com.shamelagpt.android.data.remote.dto.UserPreferencesRequest> = Result.success(com.shamelagpt.android.data.remote.dto.UserPreferencesRequest(
        languagePreference = "en",
        customSystemPrompt = null,
        responsePreferences = null
    ))
    override suspend fun setPreferences(request: com.shamelagpt.android.data.remote.dto.UserPreferencesRequest): Result<Unit> = Result.success(Unit)
    override fun logout() {}
    override fun getToken(): String? = "mock_token"
    override fun isLoggedIn(): Boolean = true
}

/**
 * Mock implementation of PreferencesRepository for testing.
 */
class MockPreferencesRepository : com.shamelagpt.android.domain.repository.PreferencesRepository {
    private val preferences = MutableStateFlow(com.shamelagpt.android.domain.model.UserPreferences())
    
    override suspend fun fetchPreferences(): Result<com.shamelagpt.android.domain.model.UserPreferences> = Result.success(preferences.value)
    override suspend fun updatePreferences(prefs: com.shamelagpt.android.domain.model.UserPreferences): Result<Unit> {
        preferences.value = prefs
        return Result.success(Unit)
    }
    fun getPreferences(): Flow<com.shamelagpt.android.domain.model.UserPreferences> = preferences
}
