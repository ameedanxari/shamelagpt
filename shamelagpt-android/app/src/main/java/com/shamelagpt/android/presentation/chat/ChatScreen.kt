package com.shamelagpt.android.presentation.chat

import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.*
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.background
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.R
import com.shamelagpt.android.presentation.common.TestTags
import com.shamelagpt.android.presentation.chat.components.InputBar
import com.shamelagpt.android.presentation.chat.components.MessageBubble
import com.shamelagpt.android.presentation.chat.components.OCRConfirmationDialog
import com.shamelagpt.android.presentation.chat.components.TypingIndicator
import com.shamelagpt.android.core.util.FactCheckSharePayloadStore
import com.shamelagpt.android.core.util.Logger
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import org.koin.androidx.compose.koinViewModel

import androidx.compose.ui.platform.testTag
import android.content.Intent

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
    onMenuClick: () -> Unit = {},
    onRequireAuth: () -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }
    var showVoiceSetupHelpSheet by remember { mutableStateOf(false) }
    var voiceSetupIntent by remember { mutableStateOf<Intent?>(null) }
    val voiceRecognitionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        viewModel.onVoiceRecognitionActivityResult(result.resultCode, result.data)
    }

    // State for hiding/showing bottom bar
    var isBottomBarVisible by remember { mutableStateOf(true) }

    // Load conversation when composable is first created
    LaunchedEffect(conversationId) {
        viewModel.loadConversation(conversationId)
    }

    // Consume one-shot share payload (if app was opened via Android share sheet).
    LaunchedEffect(Unit) {
        val payload = FactCheckSharePayloadStore.consume()
        if (payload == null) return@LaunchedEffect

        viewModel.startNewConversationForShare()

        val sharedImageUri = payload.uris.firstOrNull()
        if (sharedImageUri != null) {
            Logger.i(
                "ChatScreen",
                "Processing shared image payload uri=$sharedImageUri mimeType=${payload.mimeType ?: "null"}"
            )
            viewModel.processImage(sharedImageUri)
        } else if (!payload.text.isNullOrBlank()) {
            Logger.i("ChatScreen", "Applying shared text payload length=${payload.text.length}")
            viewModel.updateInputText(payload.text)
        } else {
            Logger.w("ChatScreen", "Share payload consumed but no processable text/image found")
        }
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
                is ChatEvent.ShowToast -> {
                    Toast.makeText(context, event.message, Toast.LENGTH_SHORT).show()
                }
                is ChatEvent.ScrollToBottom -> {
                    scope.launch {
                        // iOS logic: Scroll to top of the last message (user message or typing indicator)
                        val items = uiState.messages
                        val streamingMessage = uiState.streamingMessage
                        val hasThinking = uiState.thinkingMessages.isNotEmpty()
                        val isLoading = uiState.isLoading
                        
                        val targetIndex = when {
                            hasThinking -> items.size + if (streamingMessage != null) 1 else 0
                            streamingMessage != null -> items.size
                            isLoading -> items.size
                            items.isNotEmpty() -> items.size - 1
                            else -> -1
                        }

                        if (targetIndex >= 0) {
                            // Scroll to the top of the item
                            listState.animateScrollToItem(targetIndex, scrollOffset = 0)
                        }
                    }
                }
                is ChatEvent.MessageSent -> {
                    // Could add haptic feedback or other UI feedback here
                }
                ChatEvent.RequireAuth -> {
                    onRequireAuth()
                }
                is ChatEvent.LaunchVoiceRecognition -> {
                    voiceRecognitionLauncher.launch(event.intent)
                }
                is ChatEvent.ShowVoiceSetupPrompt -> {
                    val result = snackbarHostState.showSnackbar(
                        message = event.message,
                        actionLabel = event.actionLabel,
                        duration = SnackbarDuration.Long
                    )
                    if (result == SnackbarResult.ActionPerformed) {
                        runCatching {
                            context.startActivity(event.intent)
                        }.onFailure {
                            snackbarHostState.showSnackbar(
                                message = it.localizedMessage ?: context.getString(R.string.error_occurred),
                                duration = SnackbarDuration.Short
                            )
                        }
                    }
                }
                is ChatEvent.ShowVoiceSetupHelp -> {
                    voiceSetupIntent = event.intent
                    showVoiceSetupHelpSheet = true
                }
            }
        }
    }

    // Auto-scroll to top of last message when new messages arrive or loading indicator is shown
    LaunchedEffect(uiState.messages.size, uiState.isLoading, uiState.streamingMessage, uiState.thinkingMessages.size) {
        val totalItems = uiState.messages.size + 
                (if (uiState.streamingMessage != null) 1 else 0) + 
                (if (uiState.isLoading && uiState.streamingMessage == null) 1 else 0) +
                (if (uiState.thinkingMessages.isNotEmpty()) 1 else 0)
        
        if (totalItems == 0) return@LaunchedEffect

        // iOS logic: Scroll to last item (user message, assistant chunk, or typing indicator)
        val targetIndex = totalItems - 1
        val visibleLast = listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: -1
        val totalCount = listState.layoutInfo.totalItemsCount
        val isNearBottom = visibleLast >= totalCount - 3 || visibleLast == -1

        if (isNearBottom) {
            listState.animateScrollToItem(targetIndex, scrollOffset = 0)
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
            SnackbarHost(
                hostState = snackbarHostState,
                snackbar = { data ->
                    Snackbar(modifier = Modifier.testTag(TestTags.Chat.ErrorBanner)) {
                        Text(text = data.visuals.message)
                    }
                }
            )
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
                    onSendClick = { viewModel.sendMessage(uiState.inputText) },
                    isLoading = uiState.isLoading,
                    isRecording = uiState.voiceInputState.isRecording,
                    isProcessingImage = uiState.imageInputState.isProcessing,
                    requiresMicPermission = uiState.voiceInputState.requiresMicPermission,
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
                .testTag(TestTags.Chat.Screen)
        ) {
            if (uiState.messages.isEmpty() && !uiState.isLoading && !uiState.isHydratingConversation) {
                // Empty state
                EmptyState(
                    onSuggestionClick = viewModel::sendSuggestedQuestion,
                    modifier = Modifier.align(Alignment.Center).testTag(TestTags.Chat.EmptyState)
                )
            } else {
                // Message list with tap-to-toggle bottom bar
                LazyColumn(
                    state = listState,
                    modifier = Modifier
                        .fillMaxSize()
                        .testTag(TestTags.Chat.MessagesList)
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

                    // Streaming assistant message
                    uiState.streamingMessage?.let { message ->
                        item(key = "streaming") {
                            MessageBubble(
                                message = message,
                                modifier = Modifier.fillMaxWidth()
                            )
                        }
                    }

                    // Thinking messages
                    if (uiState.thinkingMessages.isNotEmpty()) {
                        item(key = "thinking") {
                            ThinkingStatusBubble(text = uiState.thinkingMessages.first())
                        }
                    } else if (uiState.isLoading && uiState.streamingMessage == null) {
                        // Plain typing indicator if no thinking messages yet
                        item(key = "typing") {
                            TypingIndicator()
                        }
                    }
                }
            }

            if (uiState.isHydratingConversation) {
                Surface(
                    modifier = Modifier
                        .fillMaxSize()
                        .testTag(TestTags.Chat.HydrationOverlay),
                    color = MaterialTheme.colorScheme.background.copy(alpha = 0.8f)
                ) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            CircularProgressIndicator()
                            Text(
                                text = stringResource(R.string.loading),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onBackground
                            )
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
                        TextButton(
                            onClick = viewModel::clearError,
                            modifier = Modifier.testTag(TestTags.Chat.ErrorBannerDismissButton)
                        ) {
                            Text(text = stringResource(R.string.dismiss))
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

    if (showVoiceSetupHelpSheet) {
        VoiceSetupHelpSheet(
            canOpenSettings = voiceSetupIntent != null,
            onDismiss = { showVoiceSetupHelpSheet = false },
            onOpenSettings = {
                val intent = voiceSetupIntent ?: return@VoiceSetupHelpSheet
                runCatching {
                    context.startActivity(intent)
                }.onFailure {
                    scope.launch {
                        snackbarHostState.showSnackbar(
                            message = it.localizedMessage ?: context.getString(R.string.error_occurred),
                            duration = SnackbarDuration.Short
                        )
                    }
                }
            }
        )
    }
}

@Composable
private fun ThinkingStatusBubble(text: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .testTag(TestTags.Chat.ThinkingBubble),
        horizontalArrangement = Arrangement.Start
    ) {
        Row(
            modifier = Modifier
                .widthIn(max = 320.dp)
                .background(
                    color = MaterialTheme.colorScheme.surfaceVariant,
                    shape = RoundedCornerShape(16.dp)
                )
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.Top
        ) {
            Icon(
                imageVector = Icons.Default.Psychology,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.8f),
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = text,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun VoiceSetupHelpSheet(
    canOpenSettings: Boolean,
    onDismiss: () -> Unit,
    onOpenSettings: () -> Unit
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text(
                text = stringResource(R.string.voice_help_title),
                style = MaterialTheme.typography.titleMedium
            )
            Text(
                text = stringResource(R.string.voice_help_intro),
                style = MaterialTheme.typography.bodyMedium
            )
            Text(
                text = "1. ${stringResource(R.string.voice_help_step_1)}",
                style = MaterialTheme.typography.bodyMedium
            )
            Text(
                text = "2. ${stringResource(R.string.voice_help_step_2)}",
                style = MaterialTheme.typography.bodyMedium
            )
            Text(
                text = "3. ${stringResource(R.string.voice_help_step_3)}",
                style = MaterialTheme.typography.bodyMedium
            )
            if (!canOpenSettings) {
                Text(
                    text = stringResource(R.string.voice_setup_no_settings_fallback),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(modifier = Modifier.height(6.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                if (canOpenSettings) {
                    Button(
                        onClick = onOpenSettings,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(stringResource(R.string.voice_open_settings_action))
                    }
                }
                OutlinedButton(
                    onClick = onDismiss,
                    modifier = Modifier.weight(1f)
                ) {
                    Text(stringResource(R.string.common_cancel))
                }
            }
            Spacer(modifier = Modifier.height(14.dp))
        }
    }
}

/**
 * Empty state view shown when there are no messages.
 */
@Composable
private fun EmptyState(
    onSuggestionClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val suggestions = listOf(
        stringResource(R.string.suggestion_1),
        stringResource(R.string.suggestion_2),
        stringResource(R.string.suggestion_3)
    )

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

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 16.dp)
                .padding(horizontal = 24.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = stringResource(R.string.try_asking),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            suggestions.forEach { suggestion ->
                SuggestionItem(
                    text = suggestion,
                    onClick = { onSuggestionClick(suggestion) }
                )
            }
        }
    }
}

@Composable
private fun SuggestionItem(
    text: String,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surfaceVariant,
        tonalElevation = 1.dp,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
    ) {
        Row(
            modifier = Modifier
                .clickable { onClick() }
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Lightbulb,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.tertiary
            )
            Text(
                text = text,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}
