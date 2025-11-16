package com.shamelagpt.android.data.repository

import com.shamelagpt.android.data.remote.ResponseParser
import com.shamelagpt.android.data.remote.datasource.ChatRemoteDataSource
import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.HealthResponse
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.repository.ChatRepository
import com.shamelagpt.android.domain.repository.ConversationRepository
import java.util.UUID

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
        saveUserMessage: Boolean
    ): Result<ChatResponse> {
        // Save user message immediately (unless it's a fact-check message already saved)
        if (saveUserMessage) {
            val userMessage = Message(
                id = UUID.randomUUID().toString(),
                content = question,
                isUserMessage = true,
                timestamp = System.currentTimeMillis(),
                sources = null
            )
            conversationRepository.saveMessage(userMessage, conversationId)
        }

        // Send to API
        val result = chatRemoteDataSource.sendMessage(question, threadId)

        // If successful, parse and save AI response
        result.onSuccess { response ->
            // Parse the answer to extract content and sources
            val (cleanContent, sources) = ResponseParser.parseAnswer(response.answer)

            // Create AI message with parsed data
            val aiMessage = Message(
                id = UUID.randomUUID().toString(),
                content = cleanContent,
                isUserMessage = false,
                timestamp = System.currentTimeMillis(),
                sources = sources.ifEmpty { null }
            )

            // Save AI message
            conversationRepository.saveMessage(aiMessage, conversationId)

            // Update conversation thread ID
            conversationRepository.updateConversationThread(conversationId, response.threadId)
        }

        return result
    }

    override suspend fun checkHealth(): Result<HealthResponse> {
        return chatRemoteDataSource.checkHealth()
    }
}
