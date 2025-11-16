package com.shamelagpt.android.domain.usecase

import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.domain.repository.ConversationRepository
import kotlinx.coroutines.flow.Flow

/**
 * Use case for retrieving all conversations.
 *
 * @property conversationRepository Repository for conversation data
 */
class GetConversationsUseCase(
    private val conversationRepository: ConversationRepository
) {

    /**
     * Sync conversations from backend if authenticated.
     */
    suspend fun sync(forceRefresh: Boolean = false): Result<Unit> =
        conversationRepository.syncConversations(forceRefresh = forceRefresh)

    /**
     * Retrieves all conversations as a Flow.
     *
     * @return Flow of conversation list sorted by most recent first
     */
    operator fun invoke(): Flow<List<Conversation>> {
        return conversationRepository.getConversations()
    }
}
