package com.shamelagpt.android.domain.usecase

import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.domain.repository.ChatRepository
import com.shamelagpt.android.domain.repository.ConversationRepository
import java.util.Locale

/**
 * Use case for sending messages in a conversation.
 *
 * Handles the business logic for:
 * 1. Creating a new conversation if needed
 * 2. Sending the message to the API
 * 3. Saving messages to local storage
 * 4. Updating conversation metadata
 *
 * @property chatRepository Repository for chat API operations
 * @property conversationRepository Repository for local conversation storage
 */
class SendMessageUseCase(
    private val chatRepository: ChatRepository,
    private val conversationRepository: ConversationRepository
) {

    /**
     * Sends a message and handles the conversation flow.
     *
     * @param question User's question/message
     * @param conversationId Optional conversation ID (creates new if null)
     * @param threadId Optional thread ID from previous API response
     * @param saveUserMessage Whether to save the user message (false for fact-check messages)
     * @return Result with ChatResponse or error
     */
    suspend operator fun invoke(
        question: String,
        conversationId: String?,
        threadId: String?,
        saveUserMessage: Boolean = true,
        promptConfig: com.google.gson.JsonElement? = null,
        languagePreference: String? = null,
        customSystemPrompt: String? = null,
        enableThinking: Boolean? = null
    ): Result<Pair<ChatResponse, String>> {
        // Validate input
        if (question.isBlank()) {
            return Result.failure(IllegalArgumentException("Question cannot be empty"))
        }

        // Get or create conversation
        val actualConversationId = conversationId ?: run {
            // Create new conversation with title from first message
            val title = generateConversationTitle(question)
            val conversation = conversationRepository.createConversation(title)
            conversation.id
        }

        // Send message to API
        val resolvedLanguagePreference = (languagePreference?.takeIf { it.isNotBlank() })
            ?: Locale.getDefault().language

        val result = chatRepository.sendMessage(
            question = question,
            conversationId = actualConversationId,
            threadId = threadId,
            saveUserMessage = saveUserMessage,
            promptConfig = promptConfig,
            languagePreference = resolvedLanguagePreference,
            customSystemPrompt = customSystemPrompt,
            enableThinking = enableThinking
        )

        // Return the response with the conversation ID
        return result.map { response ->
            Pair(response, actualConversationId)
        }
    }

    /**
     * Generates a conversation title from the first message.
     *
     * @param firstMessage The first user message
     * @return Generated title (truncated if needed)
     */
    private fun generateConversationTitle(firstMessage: String): String {
        val maxLength = 50
        return if (firstMessage.length > maxLength) {
            firstMessage.take(maxLength).trim() + "..."
        } else {
            firstMessage.trim()
        }
    }
}
