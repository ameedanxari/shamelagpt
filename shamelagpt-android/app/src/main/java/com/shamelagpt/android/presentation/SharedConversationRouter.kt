package com.shamelagpt.android.presentation

import com.shamelagpt.android.core.util.ShareLink
import com.shamelagpt.android.domain.repository.ConversationRepository

sealed class SharedLinkAction {
    data class OpenInApp(val conversationId: String) : SharedLinkAction()
    data class OpenInBrowser(val url: String) : SharedLinkAction()
}

object SharedConversationRouter {
    suspend fun resolve(
        conversationId: String,
        conversationRepository: ConversationRepository
    ): SharedLinkAction {
        val local = conversationRepository.getConversationById(conversationId)
        return if (local != null) {
            SharedLinkAction.OpenInApp(conversationId)
        } else {
            SharedLinkAction.OpenInBrowser(ShareLink.normalize(null, conversationId))
        }
    }
}
