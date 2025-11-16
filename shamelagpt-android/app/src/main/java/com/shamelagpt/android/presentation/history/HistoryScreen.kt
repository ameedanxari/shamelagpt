package com.shamelagpt.android.presentation.history

import android.content.Intent
import androidx.compose.ui.platform.LocalContext
import com.shamelagpt.android.domain.model.Conversation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.exclude
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ScaffoldDefaults
import androidx.compose.ui.platform.testTag

import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Login
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshContainer
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.R
import com.shamelagpt.android.presentation.common.TestTags
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
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()

    val snackbarHostState = remember { SnackbarHostState() }

    var conversationToDelete by remember { mutableStateOf<Conversation?>(null) }
    var showNewConversationWarning by remember { mutableStateOf(false) }


    // Pull-to-refresh state
    val pullToRefreshState = rememberPullToRefreshState()

    // Handle pull-to-refresh
    if (pullToRefreshState.isRefreshing) {
        LaunchedEffect(Unit) {
            if (isAuthenticated) {
                viewModel.loadConversations(forceRefresh = true)
            } else {
                pullToRefreshState.endRefresh()
            }
        }
    }
    
    // Initial load
    LaunchedEffect(Unit) {
        if (isAuthenticated) {
            viewModel.loadConversations(forceRefresh = false)
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
                    onClick = { showNewConversationWarning = true },
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
        snackbarHost = { SnackbarHost(snackbarHostState) },
        contentWindowInsets = ScaffoldDefaults.contentWindowInsets.exclude(WindowInsets.navigationBars)
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
                            modifier = Modifier.fillMaxSize().testTag(TestTags.History.List),
                            contentPadding = PaddingValues(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            items(
                                items = uiState.conversations,
                                key = { it.id }
                            ) { conversation ->
                                SwipeRevealConversationCard(
                                    conversation = conversation,
                                    title = viewModel.displayTitle(conversation),
                                    preview = viewModel.messagePreview(conversation),
                                    onOpen = { onNavigateToChat(conversation.id) },
                                    onShare = { shareConversation(context, viewModel, conversation) },
                                    onDelete = { conversationToDelete = conversation },
                                    modifier = Modifier
                                        .testTag(TestTags.History.conversationCard(conversation.id))
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
        conversationToDelete?.let { conversation ->
            DeleteConfirmationDialog(
                conversationTitle = conversation.title,
                onConfirm = {
                    viewModel.deleteConversation(conversation.id)
                },
                onDismiss = {
                    conversationToDelete = null
                }
            )
        }

        if (showNewConversationWarning) {
            AlertDialog(
                onDismissRequest = { showNewConversationWarning = false },
                title = { Text(stringResource(R.string.new_chat_warning_title)) },
                text = {
                    Text(
                        stringResource(
                            if (isAuthenticated) {
                                R.string.new_chat_warning_message_logged_in
                            } else {
                                R.string.new_chat_warning_message_logged_out
                            }
                        )
                    )
                },
                dismissButton = {
                    TextButton(onClick = { showNewConversationWarning = false }) {
                        Text(stringResource(R.string.common_cancel))
                    }
                },
                confirmButton = {
                    TextButton(
                        onClick = {
                            showNewConversationWarning = false
                            onNavigateToChat(null)
                        }
                    ) {
                        Text(stringResource(R.string.new_chat))
                    }
                }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SwipeRevealConversationCard(
    conversation: Conversation,
    title: String,
    preview: String,
    onOpen: () -> Unit,
    onShare: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    val contentLayoutDirection = LocalLayoutDirection.current
    val isRtl = contentLayoutDirection == LayoutDirection.Rtl
    val cardShape = RoundedCornerShape(12.dp)

    fun actionFor(direction: SwipeToDismissBoxValue): SwipeAction {
        if (isRtl) {
            return when (direction) {
                SwipeToDismissBoxValue.StartToEnd -> SwipeAction.Delete
                SwipeToDismissBoxValue.EndToStart -> SwipeAction.Share
                SwipeToDismissBoxValue.Settled -> SwipeAction.None
            }
        }
        return when (direction) {
            SwipeToDismissBoxValue.StartToEnd -> SwipeAction.Share
            SwipeToDismissBoxValue.EndToStart -> SwipeAction.Delete
            SwipeToDismissBoxValue.Settled -> SwipeAction.None
        }
    }

    val dismissState = rememberSwipeToDismissBoxState(
        confirmValueChange = { target ->
            when (actionFor(target)) {
                SwipeAction.Share -> {
                    onShare()
                    false
                }
                SwipeAction.Delete -> {
                    onDelete()
                    false
                }
                SwipeAction.None -> true
            }
        },
        positionalThreshold = { totalDistance -> totalDistance * 0.35f }
    )

    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        SwipeToDismissBox(
            state = dismissState,
            enableDismissFromStartToEnd = true,
            enableDismissFromEndToStart = true,
            backgroundContent = {
                val action = actionFor(dismissState.dismissDirection)
                if (action == SwipeAction.None) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(cardShape)
                            .background(MaterialTheme.colorScheme.surface)
                    )
                    return@SwipeToDismissBox
                }
                val backgroundColor = if (action == SwipeAction.Share) {
                    MaterialTheme.colorScheme.secondaryContainer
                } else {
                    MaterialTheme.colorScheme.errorContainer
                }
                val contentColor = if (action == SwipeAction.Share) {
                    MaterialTheme.colorScheme.onSecondaryContainer
                } else {
                    MaterialTheme.colorScheme.onErrorContainer
                }
                val actionIcon = if (action == SwipeAction.Share) Icons.Default.Share else Icons.Default.Delete
                val actionText = if (action == SwipeAction.Share) {
                    stringResource(R.string.common_share)
                } else {
                    stringResource(R.string.common_delete)
                }
                val direction = dismissState.dismissDirection
                val arrangement = if (direction == SwipeToDismissBoxValue.StartToEnd) {
                    Arrangement.Start
                } else {
                    Arrangement.End
                }

                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .clip(cardShape)
                        .background(backgroundColor)
                        .padding(horizontal = 16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = arrangement
                ) {
                    Surface(
                        color = contentColor.copy(alpha = 0.16f),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Column(
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            Icon(
                                imageVector = actionIcon,
                                contentDescription = null,
                                tint = contentColor,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = actionText,
                                color = contentColor,
                                style = MaterialTheme.typography.labelLarge,
                                maxLines = 1
                            )
                        }
                    }
                }
            },
            modifier = modifier
                .fillMaxWidth()
                .clip(cardShape)
        ) {
            CompositionLocalProvider(LocalLayoutDirection provides contentLayoutDirection) {
                ConversationCard(
                    conversation = conversation,
                    title = title,
                    preview = preview,
                    onClick = onOpen,
                    onShareClick = onShare,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}

private enum class SwipeAction {
    Share,
    Delete,
    None
}

private fun shareConversation(
    context: android.content.Context,
    viewModel: HistoryViewModel,
    conversation: Conversation
) {
    val sendIntent = Intent().apply {
        action = Intent.ACTION_SEND
        putExtra(Intent.EXTRA_TEXT, viewModel.exportConversation(conversation))
        type = "text/plain"
    }
    val shareIntent = Intent.createChooser(sendIntent, null)
    context.startActivity(shareIntent)
}
