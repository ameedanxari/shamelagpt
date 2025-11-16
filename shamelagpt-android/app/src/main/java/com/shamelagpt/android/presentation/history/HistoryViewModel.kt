package com.shamelagpt.android.presentation.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.domain.usecase.DeleteConversationUseCase
import com.shamelagpt.android.domain.usecase.GetConversationsUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

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
    fun loadConversations() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            getConversationsUseCase()
                .catch { exception ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = exception.message ?: "Failed to load conversations"
                        )
                    }
                }
                .collect { conversations ->
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
        viewModelScope.launch {
            deleteConversationUseCase(id)
                .onSuccess {
                    // Conversation will be automatically removed via Flow update
                }
                .onFailure { exception ->
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
