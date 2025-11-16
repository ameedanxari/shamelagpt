package com.shamelagpt.android.presentation.history

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.domain.usecase.DeleteConversationUseCase
import com.shamelagpt.android.domain.usecase.GetConversationsUseCase
import java.text.DateFormat
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

private const val TAG = "HistoryViewModel"

/**
 * ViewModel for the History screen.
 *
 * Manages conversation list, loading states, and deletion.
 *
 * @property getConversationsUseCase Use case for fetching conversations
 * @property deleteConversationUseCase Use case for deleting conversations
 */
class HistoryViewModel(
    private val getConversationsUseCase: GetConversationsUseCase,
    private val deleteConversationUseCase: DeleteConversationUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(HistoryUiState())
    val uiState: StateFlow<HistoryUiState> = _uiState.asStateFlow()

    init {
        loadConversations()
    }

    /**
     * Loads all conversations from the repository.
     */
    fun loadConversations(forceRefresh: Boolean = false) {
        Log.d(TAG, "loadConversations() called")
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            Log.d(TAG, "Set isLoading = true")

            // Attempt remote sync (no-op if guest)
            Log.d(TAG, "Attempting to sync conversations...")
            val syncResult = getConversationsUseCase.sync(forceRefresh = forceRefresh)
            syncResult.onFailure { exception ->
                Log.e(TAG, "Sync failed: ${exception.message}")
                _uiState.update {
                    it.copy(error = exception.message)
                }
            }.onSuccess {
                Log.d(TAG, "Sync completed successfully")
            }

            Log.d(TAG, "Collecting conversations from repository...")
            getConversationsUseCase()
                .catch { exception ->
                    Log.e(TAG, "Failed to load conversations: ${exception.message}", exception)
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = exception.message ?: "Failed to load conversations"
                        )
                    }
                }
                .collect { conversations ->
                    Log.d(TAG, "Loaded ${conversations.size} conversations")
                    _uiState.update {
                        it.copy(
                            conversations = conversations,
                            isLoading = false,
                            error = null
                        )
                    }
                }
        }
    }

    /**
     * Deletes a conversation by ID.
     *
     * @param id Conversation ID to delete
     */
    fun deleteConversation(id: String) {
        Log.d(TAG, "deleteConversation() called for id: $id")
        viewModelScope.launch {
            deleteConversationUseCase(id)
                .onSuccess {
                    Log.d(TAG, "Conversation deleted: $id")
                    // Conversation will be automatically removed via Flow update
                }
                .onFailure { exception ->
                    Log.e(TAG, "Failed to delete conversation: ${exception.message}", exception)
                    _uiState.update {
                        it.copy(error = exception.message ?: "Failed to delete conversation")
                    }
                }
        }
    }

    /**
     * Clears the current error message.
     */
    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun messagePreview(conversation: Conversation): String {
        return conversation.messages.lastOrNull()?.content
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: "No messages"
    }

    fun displayTitle(conversation: Conversation): String {
        val rawTitle = conversation.title.trim()
        if (rawTitle.isNotEmpty() && rawTitle != "New Conversation") {
            return rawTitle
        }

        val firstUserMessage = conversation.messages.firstOrNull { it.isUserMessage }?.content?.trim()
        if (!firstUserMessage.isNullOrEmpty()) {
            return if (firstUserMessage.length > 50) {
                firstUserMessage.take(50) + "..."
            } else {
                firstUserMessage
            }
        }

        return "New Conversation"
    }

    fun exportConversation(conversation: Conversation): String {
        val title = displayTitle(conversation)
        val link = "https://shamelagpt.com/chat?id=${conversation.id}"
        val preview = messagePreview(conversation)
        val updated = DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT)
            .format(java.util.Date(conversation.updatedAt))

        return buildString {
            append("ShamelaGPT Chat: $title\n")
            append("Link: $link\n")
            append("Last updated: $updated\n")
            if (preview.isNotBlank()) {
                append("\nPreview:\n$preview")
            }
        }
    }
}

/**
 * UI state for the History screen.
 *
 * @property conversations List of conversations sorted by most recent
 * @property isLoading Whether conversations are currently loading
 * @property error Error message if loading failed
 */
data class HistoryUiState(
    val conversations: List<Conversation> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)
