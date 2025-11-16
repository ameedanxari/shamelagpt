package com.shamelagpt.android.presentation.history

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.History
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshContainer
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.presentation.components.DeleteConfirmationDialog
import com.shamelagpt.android.presentation.components.EmptyState
import org.koin.androidx.compose.koinViewModel

/**
 * History screen showing list of past conversations.
 *
 * Features:
 * - List of conversations sorted by most recent
 * - Pull-to-refresh
 * - Tap to open conversation
 * - Delete conversation with confirmation
 * - Empty state when no conversations
 * - FAB for creating new conversation
 *
 * @param onNavigateToChat Callback to navigate to chat screen with conversation ID
 * @param viewModel ViewModel for managing history state
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen(
    onNavigateToChat: (String?) -> Unit,
    viewModel: HistoryViewModel = koinViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    var conversationToDelete by remember { mutableStateOf<String?>(null) }

    // Pull-to-refresh state
    val pullToRefreshState = rememberPullToRefreshState()

    // Handle pull-to-refresh
    if (pullToRefreshState.isRefreshing) {
        LaunchedEffect(Unit) {
            viewModel.loadConversations()
        }
    }

    // Stop refreshing when loading completes
    LaunchedEffect(uiState.isLoading) {
        if (!uiState.isLoading) {
            pullToRefreshState.endRefresh()
        }
    }

    // Show error in snackbar
    LaunchedEffect(uiState.error) {
        uiState.error?.let { error ->
            snackbarHostState.showSnackbar(error)
            viewModel.clearError()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("History") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { onNavigateToChat(null) },
                containerColor = MaterialTheme.colorScheme.primary
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "New Chat",
                    tint = MaterialTheme.colorScheme.onPrimary
                )
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .nestedScroll(pullToRefreshState.nestedScrollConnection)
        ) {
            when {
                uiState.isLoading && uiState.conversations.isEmpty() -> {
                    // Initial loading state
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }

                uiState.conversations.isEmpty() -> {
                    // Empty state
                    EmptyState(
                        icon = Icons.Default.History,
                        title = "No Conversations",
                        message = "Start a new chat to begin"
                    )
                }

                else -> {
                    // Conversation list
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(
                            items = uiState.conversations,
                            key = { it.id }
                        ) { conversation ->
                            ConversationCard(
                                conversation = conversation,
                                onClick = { onNavigateToChat(conversation.id) },
                                onDeleteClick = { conversationToDelete = conversation.id }
                            )
                        }
                    }
                }
            }

            // Pull-to-refresh indicator
            PullToRefreshContainer(
                state = pullToRefreshState,
                modifier = Modifier.align(Alignment.TopCenter)
            )
        }

        // Delete confirmation dialog
        conversationToDelete?.let { conversationId ->
            DeleteConfirmationDialog(
                onConfirm = {
                    viewModel.deleteConversation(conversationId)
                },
                onDismiss = {
                    conversationToDelete = null
                }
            )
        }
    }
}
