package com.shamelagpt.android.presentation.chat

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shamelagpt.android.core.util.Logger
import com.shamelagpt.android.core.util.OCRManager
import com.shamelagpt.android.core.util.VoiceInputCapability
import com.shamelagpt.android.core.util.VoiceInputManager
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.repository.ConversationRepository
import android.util.Base64
import com.shamelagpt.android.R
import com.shamelagpt.android.domain.usecase.SendMessageUseCase
import com.shamelagpt.android.domain.usecase.StreamMessageUseCase
import com.shamelagpt.android.domain.usecase.OCRUseCase
import com.shamelagpt.android.domain.usecase.ConfirmFactCheckUseCase
import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.core.error.AppError
import com.shamelagpt.android.core.error.UserErrorMessage
import com.shamelagpt.android.core.network.NetworkError
import com.shamelagpt.android.core.preferences.PreferencesManager
import kotlinx.coroutines.Job
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.Locale
import java.util.UUID

/**
 * ViewModel for the chat screen.
 * Manages chat state, user input, and message sending.
 *
 * @property sendMessageUseCase Use case for sending messages
 * @property conversationRepository Repository for conversation operations
 * @property voiceInputManager Manager for voice input
 * @property ocrManager Manager for OCR processing
 * @property context Application context for accessing content resolver
 */
class ChatViewModel(
    private val sendMessageUseCase: SendMessageUseCase,
    private val streamMessageUseCase: StreamMessageUseCase,
    private val ocrUseCase: OCRUseCase,
    private val confirmFactCheckUseCase: ConfirmFactCheckUseCase,
    private val conversationRepository: ConversationRepository,
    private val voiceInputManager: VoiceInputManager,
    private val ocrManager: OCRManager,
    private val context: Context,
    private val preferencesManager: PreferencesManager? = null
) : ViewModel() {

    private val TAG = "ChatViewModel"

    // UI State
    private val _uiState = MutableStateFlow(createFreshUiState())
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()

    // One-time events channel
    private val _events = Channel<ChatEvent>(Channel.BUFFERED)
    val events: Flow<ChatEvent> = _events.receiveAsFlow()

    init {
        // Initial state is already fresh, but we can call it if needed.
        // For tests, calling it often causes race conditions with resets.
        // loadConversation(null) 
    }

    // Job for collecting messages from Room Flow
    private var messageCollectionJob: Job? = null
    private var activeConversationLoadId: String? = null

    /**
     * Loads a conversation by ID.
     * If conversationId is null, starts a new conversation.
     *
     * @param conversationId Conversation ID to load, or null for new conversation
     */
    fun loadConversation(conversationId: String?, showHydrationUi: Boolean = true) {
        val normalizedConversationId = conversationId?.trim()?.takeIf { it.isNotEmpty() }
        if (messageCollectionJob?.isActive == true && activeConversationLoadId == normalizedConversationId) {
            Logger.d(TAG, "Ignoring duplicate loadConversation request for conversationId=${Logger.redactedId(normalizedConversationId)}")
            return
        }

        messageCollectionJob?.cancel(CancellationException("Superseded by loadConversation(${normalizedConversationId ?: "new"})"))
        activeConversationLoadId = normalizedConversationId

        messageCollectionJob = viewModelScope.launch {
            try {
                if (showHydrationUi && normalizedConversationId != null) {
                    _uiState.update { state ->
                        state.copy(
                            isHydratingConversation = true,
                            error = null,
                            streamingMessage = null,
                            thinkingMessages = emptyList(),
                            messages = emptyList()
                        )
                    }
                } else {
                    _uiState.update { it.copy(isHydratingConversation = false) }
                }

                if (normalizedConversationId != null) {
                    Logger.d(TAG, "Loading conversation: ${Logger.redactedId(normalizedConversationId)}")
                    
                    // First, try to fetch remote messages to ensure history is available
                    conversationRepository.fetchMessages(normalizedConversationId)
                        .onFailure { failure ->
                            Logger.w(
                                TAG,
                                "Remote fetch failed for conversationId=${Logger.redactedId(normalizedConversationId)}; proceeding with local cache. reason=${failure.message}"
                            )
                        }
                    Logger.d(TAG, "Initial fetch attempt completed for conversationId=${Logger.redactedId(normalizedConversationId)}")

                    // Load existing conversation metadata
                    val conversation = conversationRepository.getConversationById(normalizedConversationId)
                    _uiState.update { state ->
                        state.copy(
                            conversationId = conversation?.id,
                            threadId = conversation?.threadId ?: state.threadId,
                            conversationTitle = conversation?.title
                        )
                    }
                    Logger.d(
                        TAG,
                        "Conversation metadata loaded id=${Logger.redactedId(conversation?.id)} thread=${Logger.redactedId(conversation?.threadId)} titlePresent=${!conversation?.title.isNullOrBlank()}"
                    )

                    // Observe messages for this conversation
                    var hasAttemptedForceRefresh = false
                    conversationRepository.getMessagesByConversationId(normalizedConversationId)
                        .collect { messages ->
                            if (messages.isEmpty() && !hasAttemptedForceRefresh) {
                                hasAttemptedForceRefresh = true
                                Logger.w(
                                    TAG,
                                    "No local messages yet for conversationId=${Logger.redactedId(normalizedConversationId)}; forcing one remote refresh"
                                )
                                conversationRepository.fetchMessages(
                                    conversationId = normalizedConversationId,
                                    forceRefresh = true
                                ).onFailure { failure ->
                                    Logger.w(
                                        TAG,
                                        "Forced refresh failed for conversationId=${Logger.redactedId(normalizedConversationId)} reason=${failure.message}"
                                    )
                                }
                            }

                            _uiState.update { state ->
                                state.copy(
                                    messages = messages,
                                    isHydratingConversation = false
                                )
                            }
                            Logger.d(
                                TAG,
                                "Conversation loaded id=${Logger.redactedId(normalizedConversationId)} messageCount=${messages.size}"
                            )
                        }
                } else {
                    Logger.d(TAG, "Starting new conversation")
                    // New conversation - reset state
                    _uiState.update {
                        createFreshUiState().copy(isHydratingConversation = false)
                    }
                }
            } catch (e: CancellationException) {
                Logger.d(
                    TAG,
                    "loadConversation cancelled for conversationId=${Logger.redactedId(normalizedConversationId)} reason=${e.message}"
                )
                throw e
            } catch (e: Exception) {
                Logger.e(TAG, "Failed to load conversation", e)
                _uiState.update { it.copy(isHydratingConversation = false) }
                _events.send(ChatEvent.ShowError("Failed to load conversation: ${e.message}"))
            }
        }
    }

    /**
     * Forces a clean chat state before handling a new external share flow.
     * This guarantees shared content starts in a brand-new conversation.
     */
    fun startNewConversationForShare() {
        Logger.i(TAG, "startNewConversationForShare requested")
        messageCollectionJob?.cancel(CancellationException("Superseded by share flow"))
        activeConversationLoadId = null
        _uiState.update { createFreshUiState().copy(isHydratingConversation = false) }
    }

    /**
     * Updates the input text field.
     *
     * @param text New input text
     */
    fun updateInputText(text: String) {
        _uiState.update { state ->
            state.copy(inputText = text)
        }
    }

    /**
     * Sends a message to the API using streaming.
     *
     * @param text Message text to send
     */
    fun sendMessage() {
        sendMessage(_uiState.value.inputText)
    }

    fun sendMessage(text: String) {
        val trimmedText = text.trim()
        val currentState = _uiState.value
        if (trimmedText.isEmpty() || currentState.isLoading) {
            return
        }

        viewModelScope.launch {
            val optimisticUserMessage = Message(
                id = UUID.randomUUID().toString(),
                content = trimmedText,
                isUserMessage = true,
                timestamp = System.currentTimeMillis()
            )

            try {
                // Clear input, set loading, and add optimistic user message
                _uiState.update { state ->
                    state.copy(
                        inputText = "",
                        isLoading = true,
                        error = null,
                        messages = state.messages + optimisticUserMessage,
                        thinkingMessages = listOf(DEFAULT_THINKING_MESSAGE),
                        streamingMessage = null
                    )
                }

                // Initiate stream via use case
                val (stream, actualConversationId) = streamMessageUseCase(
                    question = trimmedText,
                    conversationId = currentState.conversationId,
                    threadId = currentState.threadId,
                    languagePreference = resolveLanguagePreference(),
                    enableThinking = true
                )

                _uiState.update { it.copy(conversationId = actualConversationId) }

                // If this was a new conversation, we need to start observing the repository
                // so that the user message (saved by repository.streamMessage) and 
                // subsequent AI messages appear in history correctly.
                if (currentState.conversationId == null) {
                    loadConversation(actualConversationId, showHydrationUi = false)
                }

                var assembledContent = ""
                var assistantMessageId: String? = null

                stream.collect { event ->
                    when (event.type) {
                        "metadata" -> {
                            val continuityId = event.threadId ?: event.sessionId
                            continuityId?.let { tid ->
                                _uiState.update { it.copy(threadId = tid) }
                                persistConversationThreadIdIfNeeded(actualConversationId, tid)
                            }
                        }
                        "thinking" -> {
                            event.content?.let { thinking ->
                                if (thinking.isNotBlank()) {
                                    _uiState.update { it.copy(thinkingMessages = listOf(thinking)) }
                                }
                            }
                        }
                        "chunk" -> {
                            val piece = event.content ?: ""
                            assembledContent += piece
                            
                            if (assistantMessageId == null) {
                                assistantMessageId = UUID.randomUUID().toString()
                            }
                            
                            _uiState.update { state ->
                                state.copy(
                                    streamingMessage = Message(
                                        id = assistantMessageId!!,
                                        content = assembledContent,
                                        isUserMessage = false,
                                        timestamp = System.currentTimeMillis()
                                    )
                                )
                            }
                        }
                        "done" -> {
                            val finalContent = event.fullAnswer ?: event.content ?: assembledContent
                            _uiState.update { state ->
                                state.copy(
                                    isLoading = false,
                                    thinkingMessages = emptyList(),
                                    streamingMessage = null // Clear streaming message as we'll save it to Room
                                )
                            }
                            
                            // Persist the final assistant message
                            val finalAssistantId = assistantMessageId ?: UUID.randomUUID().toString()
                            conversationRepository.saveMessage(
                                Message(
                                    id = finalAssistantId,
                                    content = finalContent,
                                    isUserMessage = false,
                                    timestamp = System.currentTimeMillis()
                                ),
                                actualConversationId
                            )
                            
                            _events.send(ChatEvent.MessageSent)
                            _events.send(ChatEvent.ScrollToBottom)
                        }
                    }
                }
            } catch (e: Exception) {
                Logger.e(TAG, "Failed to send message", e)
                val userMessage = when (e) {
                    is NetworkError -> e.getUserMessageWithCode(context)
                    is AppError -> UserErrorMessage.format(context, e.getUserMessage(context), e.debugCode)
                    else -> UserErrorMessage.from(context, e)
                }
                _uiState.update { state ->
                    state.copy(
                        isLoading = false,
                        error = userMessage,
                        messages = state.messages.filterNot { it.id == optimisticUserMessage.id },
                        inputText = trimmedText,
                        streamingMessage = null,
                        thinkingMessages = emptyList()
                    )
                }
                
                val message = when (e) {
                    is NetworkError.Unauthorized -> {
                        _events.send(ChatEvent.RequireAuth)
                        userMessage
                    }
                    else -> userMessage
                }
                _events.send(ChatEvent.ShowError(message))
            }
        }
    }

    /**
     * Sends one of the suggested starter questions from the empty state.
     */
    fun sendSuggestedQuestion(question: String) {
        val trimmed = question.trim()
        val state = _uiState.value
        if (trimmed.isEmpty() ||
            state.isLoading ||
            state.voiceInputState.isRecording ||
            state.imageInputState.isProcessing
        ) {
            return
        }

        _uiState.update { it.copy(inputText = trimmed) }
        sendMessage(trimmed)
    }

    /**
     * Clears the current error state.
     */
    fun clearError() {
        _uiState.update { state ->
            state.copy(error = null)
        }
    }

    // Voice Input Methods

    /**
     * Starts voice input recording.
     *
     * @param locale Locale for speech recognition
     */
    fun startVoiceInput(locale: Locale = Locale.getDefault()) {
        if (_uiState.value.voiceInputState.isRecording) {
            Logger.d(TAG, "startVoiceInput ignored: already recording")
            return
        }

        val capability = voiceInputManager.getCapability()
        Logger.i(
            TAG,
            "startVoiceInput requested locale=${locale.toLanguageTag()} capability=$capability currentInputLen=${_uiState.value.inputText.length}"
        )

        when (capability) {
            VoiceInputCapability.DIRECT -> {
                _uiState.update { state ->
                    state.copy(
                        voiceInputState = state.voiceInputState.copy(
                            isAvailable = true,
                            requiresMicPermission = true,
                            unavailableReason = null,
                            isRecording = true,
                            transcribedText = "",
                            error = null
                        )
                    )
                }

                voiceInputManager.startListening(
                    locale = locale,
                    onResult = { text ->
                        Logger.i(TAG, "voice onResult received textLen=${text.length}")
                        onVoiceResult(text)
                    },
                    onPartialResult = { partialText ->
                        Logger.d(TAG, "voice onPartialResult received textLen=${partialText.length}")
                        _uiState.update { state ->
                            state.copy(
                                voiceInputState = state.voiceInputState.copy(
                                    transcribedText = partialText
                                )
                            )
                        }
                    },
                    onError = { error ->
                        Logger.w(TAG, "voice onError callback: $error")
                        onVoiceError(error)
                    }
                )
            }
            VoiceInputCapability.INTENT_FALLBACK -> {
                _uiState.update { state ->
                    state.copy(
                        voiceInputState = state.voiceInputState.copy(
                            isAvailable = true,
                            requiresMicPermission = false,
                            unavailableReason = null,
                            isRecording = false,
                            error = null
                        )
                    )
                }

                viewModelScope.launch {
                    Logger.i(TAG, "launching voice intent fallback locale=${locale.toLanguageTag()}")
                    _events.send(ChatEvent.LaunchVoiceRecognition(voiceInputManager.createFallbackIntent(locale)))
                }
            }
            VoiceInputCapability.UNAVAILABLE -> {
                val message = context.getString(R.string.voice_setup_required_message)
                Logger.w(TAG, "voice unavailable: $message")
                _uiState.update { state ->
                    state.copy(
                        voiceInputState = state.voiceInputState.copy(
                            isAvailable = false,
                            requiresMicPermission = false,
                            unavailableReason = message,
                            isRecording = false,
                            error = message
                        )
                    )
                }
                viewModelScope.launch {
                    val setupIntent = voiceInputManager.createSetupIntent()
                    _events.send(ChatEvent.ShowVoiceSetupHelp(intent = setupIntent))
                }
            }
        }
    }

    /**
     * Stops voice input recording.
     */
    fun stopVoiceInput() {
        Logger.i(TAG, "stopVoiceInput requested")
        voiceInputManager.stopListening()
        _uiState.update { state ->
            state.copy(
                voiceInputState = state.voiceInputState.copy(
                    isRecording = false
                )
            )
        }
    }

    fun onVoiceRecognitionActivityResult(resultCode: Int, data: Intent?) {
        Logger.i(TAG, "voice fallback activity resultCode=$resultCode hasData=${data != null}")
        if (resultCode != Activity.RESULT_OK) {
            Logger.w(TAG, "voice fallback activity canceled/non-ok resultCode=$resultCode")
            _uiState.update { state ->
                state.copy(
                    voiceInputState = state.voiceInputState.copy(isRecording = false)
                )
            }
            return
        }

        val recognizedText = voiceInputManager.extractBestResult(data)
        if (recognizedText != null) {
            Logger.i(TAG, "voice fallback produced textLen=${recognizedText.length}")
            onVoiceResult(recognizedText)
            return
        }

        Logger.w(TAG, "voice fallback completed without recognized text")
        onVoiceError("No speech recognized")
    }

    /**
     * Handles successful voice recognition result.
     *
     * @param text Transcribed text
     */
    fun onVoiceResult(text: String) {
        Logger.i(TAG, "onVoiceResult applying textLen=${text.length}")
        _uiState.update { state ->
            state.copy(
                inputText = text,
                voiceInputState = state.voiceInputState.copy(
                    isAvailable = true,
                    requiresMicPermission = voiceInputManager.getCapability() == VoiceInputCapability.DIRECT,
                    unavailableReason = null,
                    isRecording = false,
                    transcribedText = text,
                    error = null
                )
            )
        }
    }

    /**
     * Handles voice recognition error.
     *
     * @param error Error message
     */
    fun onVoiceError(error: String) {
        val capability = voiceInputManager.getCapability()
        Logger.w(TAG, "onVoiceError error=$error capability=$capability")
        _uiState.update { state ->
            state.copy(
                voiceInputState = state.voiceInputState.copy(
                    isAvailable = capability != VoiceInputCapability.UNAVAILABLE,
                    requiresMicPermission = capability == VoiceInputCapability.DIRECT,
                    unavailableReason = if (capability == VoiceInputCapability.UNAVAILABLE) {
                        voiceInputManager.getUnavailableMessage()
                    } else {
                        null
                    },
                    isRecording = false,
                    error = error
                )
            )
        }
        viewModelScope.launch {
            _events.send(ChatEvent.ShowError("Voice recognition error: $error"))
        }
    }

    // Image Input Methods

    /**
     * Processes an image for text extraction via OCR with language detection.
     *
     * @param imageUri URI of the image to process
     */
    fun processImage(imageUri: Uri) {
        Logger.i("ChatVM", "processImage called with URI: $imageUri")

        if (_uiState.value.imageInputState.isProcessing) {
            Logger.w("ChatVM", "Image already being processed, ignoring")
            return
        }

        viewModelScope.launch {
            Logger.d("ChatVM", "Setting image processing state")
            _uiState.update { state ->
                state.copy(
                    imageInputState = state.imageInputState.copy(
                        isProcessing = true,
                        extractedText = "",
                        detectedLanguage = null,
                        imageData = null,
                        imageUri = imageUri,
                        error = null
                    )
                )
            }

            // Load image data from URI
            Logger.d("ChatVM", "Loading image data from content resolver")
            val imageData = try {
                context.contentResolver.openInputStream(imageUri)?.use { inputStream ->
                    val bytes = inputStream.readBytes()
                    Logger.d("ChatVM", "Image data loaded successfully, size: ${bytes.size} bytes")
                    bytes
                }
            } catch (e: Exception) {
                Logger.e("ChatVM", "Failed to load image data from URI", e)
                null
            }

            if (imageData == null) {
                Logger.e("ChatVM", "Image data is null, cannot proceed with OCR")
                onOcrError("Failed to load image data")
                return@launch
            }

            Logger.d("ChatVM", "Calling ocrManager.recognizeTextWithLanguage")
            try {
                val result = ocrManager.recognizeTextWithLanguage(imageUri)
                result.fold(
                    onSuccess = { ocrResult ->
                        Logger.i("ChatVM", "OCR result received, text length: ${ocrResult.text.length}")
                        onOcrResult(
                            text = ocrResult.text,
                            detectedLanguage = ocrResult.detectedLanguage,
                            imageData = imageData,
                            imageUri = imageUri
                        )
                    },
                    onFailure = { error ->
                        Logger.e("ChatVM", "OCR failed: ${error.message}")
                        onOcrError(error.message ?: "OCR failed")
                    }
                )
            } catch (e: Exception) {
                Logger.e("ChatVM", "OCR exception: ${e.message}")
                onOcrError(e.message ?: "OCR failed")
            }
        }
    }

    /**
     * Handles successful OCR result and shows confirmation dialog.
     *
     * @param text Extracted text
     * @param detectedLanguage Detected language code
     * @param imageData Raw image data
     * @param imageUri Image URI
     */
    fun onOcrResult(text: String, detectedLanguage: String?, imageData: ByteArray, imageUri: Uri) {
        Logger.i("ChatVM", "onOcrResult called - showing confirmation dialog")
        Logger.d("ChatVM", "Extracted text preview: ${text.take(100)}")
        Logger.d("ChatVM", "Detected language: $detectedLanguage")
        Logger.d("ChatVM", "Image data size: ${imageData.size} bytes")

        _uiState.update { state ->
            state.copy(
                imageInputState = state.imageInputState.copy(
                    isProcessing = false,
                    extractedText = text,
                    detectedLanguage = detectedLanguage,
                    imageData = imageData,
                    imageBase64 = Base64.encodeToString(imageData, Base64.NO_WRAP),
                    imageUri = imageUri,
                    showConfirmationDialog = true,
                    error = null
                )
            )
        }

        Logger.d("ChatVM", "Confirmation dialog state updated, showConfirmationDialog = true")
    }

    /**
     * Confirms the OCR result and sends as fact-check message using the new backend flow.
     *
     * @param confirmedText The final text after user edits
     */
    fun confirmFactCheck(confirmedText: String) {
        Logger.i("ChatVM", "confirmFactCheck (streaming) called with text: ${confirmedText.take(100)}")

        val currentState = _uiState.value
        val imageState = currentState.imageInputState
        val imageData = imageState.imageData
        val imageBase64 = imageState.imageBase64
        val imageUrl = imageState.imageUrl
        val detectedLanguage = imageState.detectedLanguage

        if (imageData == null) {
            Logger.e("ChatVM", "Missing image data for fact-check confirmation")
            return
        }

        Logger.d("ChatVM", "Dismissing confirmation dialog and starting backend stream")
        
        // Clear image state and set loading
        _uiState.update { it.copy(
            imageInputState = ImageInputState(),
            isLoading = true,
            thinkingMessages = listOf(DEFAULT_THINKING_MESSAGE),
            streamingMessage = null
        )}

        viewModelScope.launch {
            try {
                // 1. Save user message locally first
                val userMessage = Message(
                    id = UUID.randomUUID().toString(),
                    content = confirmedText,
                    isUserMessage = true,
                    timestamp = System.currentTimeMillis(),
                    imageData = imageData,
                    detectedLanguage = detectedLanguage,
                    isFactCheckMessage = true
                )

                val actualConversationId = _uiState.value.conversationId ?: run {
                    val title = if (confirmedText.length > 50) confirmedText.take(50) + "..." else confirmedText
                    val conv = conversationRepository.createConversation(title)
                    conv.id
                }

                conversationRepository.saveMessage(userMessage, actualConversationId)
                _uiState.update { it.copy(
                    conversationId = actualConversationId,
                    messages = it.messages + userMessage
                )}

                // If new conversation, sync observer
                if (currentState.conversationId == null) {
                    loadConversation(actualConversationId, showHydrationUi = false)
                }

                // 2. Start backend fact-check stream.
                // Try without uploading image first (for backends where image_url is optional),
                // then retry with uploaded image_url only if backend explicitly requires it.
                var resolvedImageUrl = imageUrl?.trim()?.takeIf { it.isNotBlank() }
                if (factCheckRequiresImageUrl && resolvedImageUrl == null) {
                    resolvedImageUrl = resolveFactCheckImageUrl(
                        existingImageUrl = imageUrl,
                        imageBase64 = imageBase64,
                        threadId = currentState.threadId,
                        languageHint = detectedLanguage
                    )
                }

                var retriedWithUploadedImage = false
                while (true) {
                    try {
                        val stream = confirmFactCheckUseCase(
                            reviewedText = confirmedText,
                            imageUrl = resolvedImageUrl,
                            threadId = currentState.threadId,
                            languagePreference = resolveLanguagePreference(),
                            enableThinking = true
                        )

                        var assembledContent = ""
                        var assistantMessageId: String? = null

                        stream.collect { event ->
                            when (event.type) {
                                "metadata" -> {
                                    val continuityId = event.threadId ?: event.sessionId
                                    continuityId?.let { tid ->
                                        _uiState.update { it.copy(threadId = tid) }
                                        persistConversationThreadIdIfNeeded(actualConversationId, tid)
                                    }
                                }
                                "thinking" -> {
                                    event.content?.let { thinking ->
                                        if (thinking.isNotBlank()) {
                                            _uiState.update { it.copy(thinkingMessages = listOf(thinking)) }
                                        }
                                    }
                                }
                                "chunk" -> {
                                    val piece = event.content ?: ""
                                    assembledContent += piece
                                    if (assistantMessageId == null) assistantMessageId = UUID.randomUUID().toString()

                                    _uiState.update { s ->
                                        s.copy(
                                            streamingMessage = Message(
                                                id = assistantMessageId!!,
                                                content = assembledContent,
                                                isUserMessage = false,
                                                timestamp = System.currentTimeMillis()
                                            )
                                        )
                                    }
                                }
                                "done" -> {
                                    val finalContent = event.fullAnswer ?: event.content ?: assembledContent
                                    _uiState.update { it.copy(
                                        isLoading = false,
                                        thinkingMessages = emptyList(),
                                        streamingMessage = null
                                    )}

                                    val finalId = assistantMessageId ?: UUID.randomUUID().toString()
                                    conversationRepository.saveMessage(
                                        Message(
                                            id = finalId,
                                            content = finalContent,
                                            isUserMessage = false,
                                            timestamp = System.currentTimeMillis(),
                                            isFactCheckMessage = true
                                        ),
                                        actualConversationId
                                    )

                                    _events.send(ChatEvent.MessageSent)
                                    _events.send(ChatEvent.ScrollToBottom)
                                }
                            }
                        }

                        if (resolvedImageUrl == null) {
                            factCheckRequiresImageUrl = false
                        }
                        break
                    } catch (error: Exception) {
                        if (!retriedWithUploadedImage &&
                            resolvedImageUrl == null &&
                            isMissingImageUrlValidation(error)
                        ) {
                            Logger.w("ChatVM", "Backend requires image_url for fact-check; retrying after OCR upload")
                            factCheckRequiresImageUrl = true
                            resolvedImageUrl = resolveFactCheckImageUrl(
                                existingImageUrl = imageUrl,
                                imageBase64 = imageBase64,
                                threadId = currentState.threadId,
                                languageHint = detectedLanguage
                            )
                            retriedWithUploadedImage = true
                            continue
                        }
                        throw error
                    }
                }
            } catch (e: Exception) {
                Logger.e("ChatVM", "Fact-check stream failed", e)
                _uiState.update { it.copy(isLoading = false, error = e.message ?: "Fact-check failed") }
                _events.send(ChatEvent.ShowError(e.message ?: "Fact-check failed"))
            }
        }
    }

    private suspend fun resolveFactCheckImageUrl(
        existingImageUrl: String?,
        imageBase64: String?,
        threadId: String?,
        languageHint: String?
    ): String {
        existingImageUrl
            ?.trim()
            ?.takeIf { it.isNotBlank() }
            ?.let { return it }

        val encodedImage = imageBase64
            ?.trim()
            ?.takeIf { it.isNotBlank() }
            ?: throw IllegalStateException("Missing image payload for fact-check")

        Logger.i("ChatVM", "Uploading fact-check image to resolve image_url")
        val ocrResponse = ocrUseCase(
            imageBase64 = encodedImage,
            threadId = threadId,
            languageHint = languageHint
        ).getOrElse { error ->
            throw IllegalStateException(
                "Failed to upload fact-check image: ${error.message ?: "unknown error"}",
                error
            )
        }

        return ocrResponse.imageUrl.trim().takeIf { it.isNotBlank() }
            ?: throw IllegalStateException("Fact-check image upload returned empty image_url")
    }

    private fun isMissingImageUrlValidation(error: Exception): Boolean {
        val httpError = error as? NetworkError.HttpError ?: return false
        if (httpError.code != 422) return false
        val body = httpError.errorBody ?: return false
        return body.contains("\"image_url\"") && body.contains("Field required", ignoreCase = true)
    }

    /**
     * Dismisses the OCR confirmation dialog.
     */
    fun dismissOcrConfirmation() {
        _uiState.update { state ->
            state.copy(
                imageInputState = ImageInputState()
            )
        }
    }

    /**
     * Handles OCR error.
     *
     * @param error Error message
     */
    fun onOcrError(error: String) {
        Logger.e("ChatVM", "OCR error occurred: $error")

        _uiState.update { state ->
            state.copy(
                imageInputState = state.imageInputState.copy(
                    isProcessing = false,
                    error = error
                )
            )
        }

        Logger.d("ChatVM", "Sending ShowError event to UI")
        viewModelScope.launch {
            _events.send(ChatEvent.ShowError("OCR error: $error"))
        }
    }

    /**
     * Clears OCR error state after it has been shown.
     */
    fun clearOcrError() {
        _uiState.update { state ->
            state.copy(
                imageInputState = state.imageInputState.copy(error = null)
            )
        }
    }

    override fun onCleared() {
        super.onCleared()
        voiceInputManager.destroy()
        ocrManager.close()
    }

    private fun createFreshUiState(): ChatUiState {
        val capability = voiceInputManager.getCapability()
        val unavailableReason = if (capability == VoiceInputCapability.UNAVAILABLE) {
            voiceInputManager.getUnavailableMessage()
        } else {
            null
        }

        return ChatUiState(
            voiceInputState = VoiceInputState(
                isAvailable = capability != VoiceInputCapability.UNAVAILABLE,
                requiresMicPermission = capability == VoiceInputCapability.DIRECT,
                unavailableReason = unavailableReason
            )
        )
    }

    private fun resolveLanguagePreference(): String {
        preferencesManager?.getSelectedLanguage()
            ?.trim()
            ?.takeIf { it.isNotBlank() }
            ?.let { return it }

        val fromResources = context.resources.configuration.locales
            .takeIf { it.size() > 0 }
            ?.get(0)
            ?.language
            ?.trim()
            ?.takeIf { it.isNotBlank() }
        if (fromResources != null) {
            return fromResources
        }

        return Locale.getDefault().language.ifBlank { "en" }
    }

    private suspend fun persistConversationThreadIdIfNeeded(conversationId: String, threadId: String) {
        runCatching {
            val current = conversationRepository.getConversationById(conversationId)
            if (current?.threadId != threadId) {
                conversationRepository.updateConversationThread(conversationId, threadId)
                Logger.d(TAG, "Saved continuity token for conversationId=${Logger.redactedId(conversationId)}")
            }
        }.onFailure { error ->
            Logger.w(TAG, "Failed to save continuity token for conversationId=${Logger.redactedId(conversationId)}: ${error.message}")
        }
    }

    private companion object {
        const val DEFAULT_THINKING_MESSAGE = "Thinking..."
        @Volatile
        var factCheckRequiresImageUrl: Boolean = false
    }
}
