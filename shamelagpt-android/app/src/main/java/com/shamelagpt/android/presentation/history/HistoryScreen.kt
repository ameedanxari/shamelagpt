package com.shamelagpt.android.presentation.history

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Login
import androidx.compose.material3.Button
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.R
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
    isAuthenticated: Boolean,
    onNavigateToChat: (String?) -> Unit,
    onNavigateToAuth: () -> Unit,
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
            if (isAuthenticated) {
                viewModel.loadConversations()
            } else {
                pullToRefreshState.endRefresh()
            }
        }
    }
    
    // Initial load
    LaunchedEffect(Unit) {
        if (isAuthenticated) {
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
                title = { Text(stringResource(R.string.history)) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary
                ),
                actions = {
                    if (isAuthenticated && uiState.conversations.isNotEmpty()) {
                        // Optional: Clear all button or other actions
                    }
                }
            )
        },
        floatingActionButton = {
            if (isAuthenticated) {
                FloatingActionButton(
                    onClick = { onNavigateToChat(null) },
                    containerColor = MaterialTheme.colorScheme.primary
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = stringResource(R.string.new_chat),
                        tint = MaterialTheme.colorScheme.onPrimary
                    )
                }
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
            if (!isAuthenticated) {
                // Guest View - Locked State
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center,
                        modifier = Modifier.padding(32.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(80.dp)
                                .background(
                                    MaterialTheme.colorScheme.surfaceVariant,
                                    shape = MaterialTheme.shapes.large
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Lock,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(40.dp)
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(24.dp))
                        
                        Text(
                            text = stringResource(R.string.history_locked_title),
                            style = MaterialTheme.typography.headlineSmall,
                            color = MaterialTheme.colorScheme.onBackground,
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Text(
                            text = stringResource(R.string.history_locked_message),
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center
                        )
                        
                        Spacer(modifier = Modifier.height(32.dp))
                        
                        Button(
                            onClick = onNavigateToAuth,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Icon(
                                imageVector = Icons.Default.Login,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(stringResource(R.string.settings_sign_in_button))
                        }
                    }
                }
            } else {
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
                            title = stringResource(R.string.no_conversations),
                            message = stringResource(R.string.start_new_chat)
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
