package com.shamelagpt.android.domain.usecase

import com.shamelagpt.android.domain.repository.ConversationRepository

/**
 * Use case for deleting a conversation.
 *
 * @property conversationRepository Repository for conversation data
 */
class DeleteConversationUseCase(
    private val conversationRepository: ConversationRepository
) {
    /**
     * Deletes a conversation by ID.
     *
     * @param conversationId ID of the conversation to delete
     * @return Result indicating success or failure
     */
    suspend operator fun invoke(conversationId: String): Result<Unit> {
        return try {
            conversationRepository.deleteConversation(conversationId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
