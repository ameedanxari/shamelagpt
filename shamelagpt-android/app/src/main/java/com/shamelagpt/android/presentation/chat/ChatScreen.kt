package com.shamelagpt.android.presentation.chat

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.*
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.R
import com.shamelagpt.android.presentation.chat.components.InputBar
import com.shamelagpt.android.presentation.chat.components.MessageBubble
import com.shamelagpt.android.presentation.chat.components.OCRConfirmationDialog
import com.shamelagpt.android.presentation.chat.components.TypingIndicator
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import org.koin.androidx.compose.koinViewModel

/**
 * Main chat screen composable.
 *
 * @param conversationId Optional conversation ID to load (null for new conversation)
 * @param viewModel ChatViewModel instance
 * @param onMenuClick Callback when menu button is clicked
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun ChatScreen(
    conversationId: String? = null,
    viewModel: ChatViewModel = koinViewModel(),
    onMenuClick: () -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    // State for hiding/showing bottom bar
    var isBottomBarVisible by remember { mutableStateOf(true) }

    // Load conversation when composable is first created
    LaunchedEffect(conversationId) {
        viewModel.loadConversation(conversationId)
    }

    // Handle events
    LaunchedEffect(Unit) {
        viewModel.events.collectLatest { event ->
            when (event) {
                is ChatEvent.ShowError -> {
                    snackbarHostState.showSnackbar(
                        message = event.message,
                        duration = SnackbarDuration.Short
                    )
                }
                is ChatEvent.ScrollToBottom -> {
                    scope.launch {
                        if (uiState.messages.isNotEmpty()) {
                            listState.animateScrollToItem(uiState.messages.size)
                        }
                    }
                }
                is ChatEvent.MessageSent -> {
                    // Could add haptic feedback or other UI feedback here
                }
            }
        }
    }

    // Auto-scroll to bottom when new message arrives
    LaunchedEffect(uiState.messages.size) {
        if (uiState.messages.isNotEmpty()) {
            scope.launch {
                listState.animateScrollToItem(uiState.messages.size)
            }
        }
    }

    // Monitor scroll state to show bottom bar when scrolling
    LaunchedEffect(listState.isScrollInProgress) {
        if (listState.isScrollInProgress && !isBottomBarVisible) {
            isBottomBarVisible = true
        }
    }

    Scaffold(
        snackbarHost = {
            SnackbarHost(hostState = snackbarHostState)
        },
        bottomBar = {
            AnimatedVisibility(
                visible = isBottomBarVisible,
                enter = slideInVertically(initialOffsetY = { it }),
                exit = slideOutVertically(targetOffsetY = { it })
            ) {
                InputBar(
                    text = uiState.inputText,
                    onTextChange = viewModel::updateInputText,
                    onSendClick = { viewModel.sendMessage() },
                    isLoading = uiState.isLoading,
                    isRecording = uiState.voiceInputState.isRecording,
                    isProcessingImage = uiState.imageInputState.isProcessing,
                    onVoiceClick = {
                        if (uiState.voiceInputState.isRecording) {
                            viewModel.stopVoiceInput()
                        } else {
                            viewModel.startVoiceInput()
                        }
                    },
                    onImageClick = { uri ->
                        viewModel.processImage(uri)
                    }
                )
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(
                    bottom = if (isBottomBarVisible) paddingValues.calculateBottomPadding() else 0.dp
                )
        ) {
            if (uiState.messages.isEmpty() && !uiState.isLoading) {
                // Empty state
                EmptyState(modifier = Modifier.align(Alignment.Center))
            } else {
                // Message list with tap-to-toggle bottom bar
                LazyColumn(
                    state = listState,
                    modifier = Modifier
                        .fillMaxSize()
                        .clickable(
                            indication = null,
                            interactionSource = remember { MutableInteractionSource() }
                        ) {
                            // Toggle bottom bar visibility on tap
                            isBottomBarVisible = !isBottomBarVisible
                        },
                    contentPadding = PaddingValues(vertical = 8.dp)
                ) {
                    items(
                        items = uiState.messages,
                        key = { message -> message.id }
                    ) { message ->
                        MessageBubble(
                            message = message,
                            modifier = Modifier.animateItemPlacement(
                                animationSpec = spring(
                                    dampingRatio = Spring.DampingRatioMediumBouncy,
                                    stiffness = Spring.StiffnessLow
                                )
                            )
                        )
                    }

                    // Typing indicator
                    if (uiState.isLoading) {
                        item {
                            TypingIndicator()
                        }
                    }
                }
            }

            // Error state with retry button
            if (uiState.error != null) {
                Card(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(16.dp)
                        .fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = uiState.error ?: stringResource(R.string.error_occurred),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.weight(1f)
                        )
                        TextButton(onClick = viewModel::clearError) {
                            Text(stringResource(R.string.dismiss))
                        }
                    }
                }
            }
        }

        // OCR Confirmation Dialog
        if (uiState.imageInputState.showConfirmationDialog &&
            uiState.imageInputState.imageData != null) {
            OCRConfirmationDialog(
                imageData = uiState.imageInputState.imageData!!,
                extractedText = uiState.imageInputState.extractedText,
                detectedLanguage = uiState.imageInputState.detectedLanguage,
                onConfirm = { confirmedText ->
                    viewModel.confirmFactCheck(confirmedText)
                },
                onDismiss = {
                    viewModel.dismissOcrConfirmation()
                }
            )
        }
    }
}

/**
 * Empty state view shown when there are no messages.
 */
@Composable
private fun EmptyState(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.Email,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = stringResource(R.string.start_conversation),
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = stringResource(R.string.ask_anything),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
            textAlign = TextAlign.Center
        )
    }
}
