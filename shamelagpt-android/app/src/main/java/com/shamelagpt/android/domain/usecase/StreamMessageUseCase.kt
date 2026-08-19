package com.shamelagpt.android.domain.usecase

import android.util.Log
import com.shamelagpt.android.core.error.ChatOperation
import com.shamelagpt.android.core.error.ChatOperationException
import com.shamelagpt.android.data.remote.dto.StreamEvent
import com.shamelagpt.android.domain.repository.ChatRepository
import com.shamelagpt.android.domain.repository.ConversationRepository
import kotlinx.coroutines.flow.Flow
import java.util.Locale

private const val TAG = "StreamMessageUseCase"

/**
 * Use case for streaming messages in a conversation.
 */
class StreamMessageUseCase(
    private val chatRepository: ChatRepository,
    private val conversationRepository: ConversationRepository
) {

    /**
     * Sends a message and returns a Flow of streaming events.
     *
     * @param question User's question/message
     * @param conversationId Optional conversation ID (creates new if null)
     * @param threadId Optional thread ID from previous API response
     * @return Pair of (Flow of StreamEvents, actualConversationId)
     */
    suspend operator fun invoke(
        question: String,
        conversationId: String?,
        threadId: String?,
        promptConfig: com.google.gson.JsonElement? = null,
        languagePreference: String? = null,
        customSystemPrompt: String? = null,
        enableThinking: Boolean? = null
    ): Pair<Flow<StreamEvent>, String> {
        Log.d(TAG, "invoke() called: conversationId=$conversationId, threadId=$threadId")
        
        // Validate input
        if (question.isBlank()) {
            throw IllegalArgumentException("Question cannot be empty")
        }

        val existingConversation = conversationId?.let {
            conversationRepository.getConversationById(it)
                ?: throw ChatOperationException(
                    operation = ChatOperation.LOAD_CONVERSATION,
                    code = "E-CHAT-MISSING-CONVERSATION",
                    message = "Conversation not found"
                )
        }

        // Get or create conversation (similar to SendMessageUseCase)
        val actualConversationId = conversationId ?: run {
            Log.d(TAG, "No conversation ID provided, creating new conversation...")
            val title = generateConversationTitle(question)
            val conversation = conversationRepository.createConversation(title)
            Log.d(TAG, "Created new conversation: ${conversation.id}")
            conversation.id
        }
        val createdOrLoaded = existingConversation
            ?: conversationRepository.getConversationById(actualConversationId)
        val resolvedThreadId = when {
            createdOrLoaded?.isLocalOnly == true ->
                createdOrLoaded.threadId ?: threadId
            !createdOrLoaded?.threadId.isNullOrBlank() ->
                createdOrLoaded?.threadId
            !threadId.isNullOrBlank() -> threadId
            else -> {
                conversationRepository.updateConversationThread(actualConversationId, actualConversationId)
                actualConversationId
            }
        }

        // Send message to repository for streaming
        val resolvedLanguagePreference = (languagePreference?.takeIf { it.isNotBlank() })
            ?: Locale.getDefault().language

        Log.d(TAG, "Initiating stream with conversationId=$actualConversationId")
        val stream = chatRepository.streamMessage(
            question = question,
            conversationId = actualConversationId,
            threadId = resolvedThreadId,
            promptConfig = promptConfig,
            languagePreference = resolvedLanguagePreference,
            customSystemPrompt = customSystemPrompt,
            enableThinking = enableThinking
        )

        return Pair(stream, actualConversationId)
    }

    private fun generateConversationTitle(firstMessage: String): String {
        val maxLength = 50
        return if (firstMessage.length > maxLength) {
            firstMessage.take(maxLength).trim() + "..."
        } else {
            firstMessage.trim()
        }
    }
}
