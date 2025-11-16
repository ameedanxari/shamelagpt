package com.shamelagpt.android.data.repository

import android.util.Log
import com.shamelagpt.android.data.remote.datasource.ChatRemoteDataSource
import com.shamelagpt.android.data.remote.ResponseParser
import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.StreamEvent
import com.shamelagpt.android.data.remote.dto.HealthResponse
import com.shamelagpt.android.data.remote.dto.OCRRequest
import com.shamelagpt.android.data.remote.dto.OCRResponse
import com.shamelagpt.android.data.remote.dto.ConfirmFactCheckRequest
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.repository.ChatRepository
import com.shamelagpt.android.domain.repository.ConversationRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.flow
import java.util.UUID

private const val TAG = "ChatRepositoryImpl"

/**
 * Implementation of ChatRepository that integrates API calls with local storage.
 *
 * @property chatRemoteDataSource Remote data source for API calls
 * @property conversationRepository Repository for local conversation storage
 */
class ChatRepositoryImpl(
    private val chatRemoteDataSource: ChatRemoteDataSource,
    private val conversationRepository: ConversationRepository
) : ChatRepository {

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
        Log.d(TAG, "sendMessage() called: conversationId=$conversationId, threadId=$threadId, languagePreference=$languagePreference")
        val conversation = conversationRepository.getConversationById(conversationId)
        val isGuestConversation = conversation?.isLocalOnly == true
        Log.d(TAG, "isGuestConversation=$isGuestConversation")
        val effectiveThreadId = conversation?.threadId ?: threadId
        val sessionId = if (isGuestConversation) {
            effectiveThreadId ?: conversationId
        } else null

        // Save user message immediately (unless it's a fact-check message already saved)
        if (saveUserMessage) {
            Log.d(TAG, "Saving user message to conversation")
            val userMessage = Message(
                id = UUID.randomUUID().toString(),
                content = question,
                isUserMessage = true,
                timestamp = System.currentTimeMillis(),
                sources = null
            )
            conversationRepository.saveMessage(userMessage, conversationId)
            Log.d(TAG, "User message saved")
        }

        // Send to API
        Log.d(TAG, "Sending message to API...")
        val result = if (isGuestConversation) {
            chatRemoteDataSource.sendGuestMessage(
                question = question,
                sessionId = sessionId,
                promptConfig = promptConfig,
                languagePreference = languagePreference,
                customSystemPrompt = customSystemPrompt,
                enableThinking = enableThinking
            )
        } else {
            chatRemoteDataSource.sendMessage(
                question = question,
                threadId = effectiveThreadId,
                promptConfig = promptConfig,
                languagePreference = languagePreference,
                customSystemPrompt = customSystemPrompt,
                enableThinking = enableThinking
            )
        }

        // If successful, parse and save AI response
        result.onSuccess { response ->
            Log.d(TAG, "API response received, parsing answer...")
            // Parse the answer to extract content and sources
            val parsedResponse = ResponseParser.parseAnswer(response.answer)
            val cleanContent = parsedResponse.first
            val sourceList = parsedResponse.second

            // Create AI message with parsed data
            val aiMessage = Message(
                id = UUID.randomUUID().toString(),
                content = cleanContent,
                isUserMessage = false,
                timestamp = System.currentTimeMillis(),
                sources = if (sourceList.isEmpty()) null else sourceList
            )

            // Save AI message
            Log.d(TAG, "Saving AI message with ${sourceList.size} sources")
            conversationRepository.saveMessage(aiMessage, conversationId)

            // Update conversation thread ID
            conversationRepository.updateConversationThread(conversationId, response.threadId)
            Log.d(TAG, "Updated conversation thread ID: ${response.threadId}")
        }

        result.onFailure { error ->
            Log.e(TAG, "API error sending message: ${error.message}", error)
        }

        return result
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
        Log.d(TAG, "streamMessage() called: conversationId=$conversationId, threadId=$threadId")
        val conversation = conversationRepository.getConversationById(conversationId)
        val isGuestConversation = conversation?.isLocalOnly == true
        Log.d(TAG, "isGuestConversation=$isGuestConversation")
        val effectiveThreadId = conversation?.threadId ?: threadId
        val sessionId = if (isGuestConversation) {
            effectiveThreadId ?: conversationId
        } else null

        // Save user message immediately (unless it's a fact-check message already saved)
        // Note: For streaming, we assume the caller wants to save unless specified otherwise
        val userMessage = Message(
            id = UUID.randomUUID().toString(),
            content = question,
            isUserMessage = true,
            timestamp = System.currentTimeMillis(),
            sources = null
        )
        conversationRepository.saveMessage(userMessage, conversationId)
        Log.d(TAG, "User message saved for stream")

        val stream = if (isGuestConversation) {
            chatRemoteDataSource.streamGuestMessage(
                question = question,
                sessionId = sessionId,
                promptConfig = promptConfig,
                languagePreference = languagePreference,
                customSystemPrompt = customSystemPrompt,
                enableThinking = enableThinking
            )
        } else {
            chatRemoteDataSource.streamMessage(
                question = question,
                threadId = effectiveThreadId,
                promptConfig = promptConfig,
                languagePreference = languagePreference,
                customSystemPrompt = customSystemPrompt,
                enableThinking = enableThinking
            )
        }

        emitAll(stream)
    }

    override suspend fun ocr(request: OCRRequest): Result<OCRResponse> {
        Log.d(TAG, "ocr() called")
        return chatRemoteDataSource.ocr(request)
    }

    override fun confirmFactCheck(request: ConfirmFactCheckRequest): Flow<StreamEvent> = flow {
        Log.d(TAG, "confirmFactCheck() called")
        // Note: For fact-checking, the backend handles the prompt and storage linkage
        // The caller (ViewModel) is responsible for saving the 'reviewed_text' as a local user message
        // if they want it to appear in history with the image metadata.
        emitAll(chatRemoteDataSource.confirmFactCheck(request))
    }

    override suspend fun checkHealth(): Result<HealthResponse> {
        return chatRemoteDataSource.checkHealth()
    }
}
