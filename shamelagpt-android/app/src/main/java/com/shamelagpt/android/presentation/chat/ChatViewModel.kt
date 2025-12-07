package com.shamelagpt.android.presentation.chat

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shamelagpt.android.core.util.Logger
import com.shamelagpt.android.core.util.OCRManager
import com.shamelagpt.android.core.util.VoiceInputManager
import com.shamelagpt.android.domain.repository.ConversationRepository
import com.shamelagpt.android.domain.usecase.SendMessageUseCase
import com.shamelagpt.android.core.network.NetworkError
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.Locale

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
    private val conversationRepository: ConversationRepository,
    private val voiceInputManager: VoiceInputManager,
    private val ocrManager: OCRManager,
    private val context: Context
) : ViewModel() {

    // UI State
    private val _uiState = MutableStateFlow(ChatUiState())
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()

    // One-time events channel
    private val _events = Channel<ChatEvent>(Channel.BUFFERED)
    val events: Flow<ChatEvent> = _events.receiveAsFlow()

    init {
        // Initialize with no conversation - start fresh
        loadConversation(null)
    }

    /**
     * Loads a conversation by ID.
     * If conversationId is null, starts a new conversation.
     *
     * @param conversationId Conversation ID to load, or null for new conversation
     */
    fun loadConversation(conversationId: String?) {
        viewModelScope.launch {
            try {
                if (conversationId != null) {
                    // Load existing conversation
                    val conversation = conversationRepository.getConversationById(conversationId)
                    if (conversation != null) {
                        _uiState.update { state ->
                            state.copy(
                                conversationId = conversation.id,
                                threadId = conversation.threadId,
                                conversationTitle = conversation.title
                            )
                        }

                        // Observe messages for this conversation
                        conversationRepository.getMessagesByConversationId(conversationId)
                            .collect { messages ->
                                _uiState.update { state ->
                                    state.copy(messages = messages)
                                }
                            }
                    }
                } else {
                    // New conversation - reset state
                    _uiState.update {
                        ChatUiState()
                    }
                }
            } catch (e: Exception) {
                _events.send(ChatEvent.ShowError("Failed to load conversation: ${e.message}"))
            }
        }
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
     * Sends a message to the API.
     *
     * @param text Message text to send
     */
    fun sendMessage(text: String = _uiState.value.inputText) {
        val trimmedText = text.trim()
        if (trimmedText.isEmpty() || _uiState.value.isLoading) {
            return
        }

        viewModelScope.launch {
            try {
                // Clear input and set loading state
                _uiState.update { state ->
                    state.copy(
                        inputText = "",
                        isLoading = true,
                        error = null
                    )
                }

                // Send message via use case
                val result = sendMessageUseCase(
                    question = trimmedText,
                    conversationId = _uiState.value.conversationId,
                    threadId = _uiState.value.threadId
                )

                result.fold(
                    onSuccess = { (response, conversationId) ->
                        // The ChatRepository already saved both messages
                        val wasNewConversation = _uiState.value.conversationId == null

                        // Update UI state
                        _uiState.update { state ->
                            state.copy(
                                isLoading = false,
                                conversationId = conversationId,
                                threadId = response.threadId
                            )
                        }

                        // If this was a new conversation, start observing messages
                        if (wasNewConversation) {
                            viewModelScope.launch {
                                conversationRepository.getMessagesByConversationId(conversationId)
                                    .collect { messages ->
                                        _uiState.update { state ->
                                            state.copy(messages = messages)
                                        }
                                    }
                            }
                        }

                        // Emit events
                        _events.send(ChatEvent.MessageSent)
                        _events.send(ChatEvent.ScrollToBottom)
                    },
                    onFailure = { exception ->
                        _uiState.update { state ->
                            state.copy(
                                isLoading = false,
                                error = exception.message ?: "Failed to send message"
                            )
                        }
                        when (exception) {
                            is NetworkError.Unauthorized -> _events.send(ChatEvent.RequireAuth)
                            is NetworkError.TooManyRequests -> _events.send(
                                ChatEvent.ShowError("Rate limit exceeded. Please wait.")
                            )
                            else -> _events.send(
                                ChatEvent.ShowError(
                                    exception.message ?: "Failed to send message"
                                )
                            )
                        }
                    }
                )
            } catch (e: Exception) {
                _uiState.update { state ->
                    state.copy(
                        isLoading = false,
                        error = e.message ?: "An unexpected error occurred"
                    )
                }
                _events.send(ChatEvent.ShowError(e.message ?: "An unexpected error occurred"))
            }
        }
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
            return
        }

        _uiState.update { state ->
            state.copy(
                voiceInputState = state.voiceInputState.copy(
                    isRecording = true,
                    transcribedText = "",
                    error = null
                )
            )
        }

        voiceInputManager.startListening(
            locale = locale,
            onResult = { text ->
                onVoiceResult(text)
            },
            onPartialResult = { partialText ->
                _uiState.update { state ->
                    state.copy(
                        voiceInputState = state.voiceInputState.copy(
                            transcribedText = partialText
                        )
                    )
                }
            },
            onError = { error ->
                onVoiceError(error)
            }
        )
    }

    /**
     * Stops voice input recording.
     */
    fun stopVoiceInput() {
        voiceInputManager.stopListening()
        _uiState.update { state ->
            state.copy(
                voiceInputState = state.voiceInputState.copy(
                    isRecording = false
                )
            )
        }
    }

    /**
     * Handles successful voice recognition result.
     *
     * @param text Transcribed text
     */
    fun onVoiceResult(text: String) {
        _uiState.update { state ->
            state.copy(
                inputText = text,
                voiceInputState = state.voiceInputState.copy(
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
        _uiState.update { state ->
            state.copy(
                voiceInputState = state.voiceInputState.copy(
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
                        imageUri = null,
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

            Logger.d("ChatVM", "Calling OCR manager to recognize text")
            val result = ocrManager.recognizeTextWithLanguage(imageUri)

            result.fold(
                onSuccess = { ocrResult ->
                    Logger.i("ChatVM", "OCR succeeded, text length: ${ocrResult.text.length}, language: ${ocrResult.detectedLanguage}")
                    onOcrResult(ocrResult.text, ocrResult.detectedLanguage, imageData, imageUri)
                },
                onFailure = { exception ->
                    Logger.e("ChatVM", "OCR failed: ${exception.message}", exception)
                    onOcrError(exception.message ?: "Failed to extract text from image")
                }
            )
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
                    imageUri = imageUri,
                    showConfirmationDialog = true,
                    error = null
                )
            )
        }

        Logger.d("ChatVM", "Confirmation dialog state updated, showConfirmationDialog = true")
    }

    /**
     * Confirms the OCR result and sends as fact-check message.
     *
     * @param confirmedText The final text after user edits
     */
    fun confirmFactCheck(confirmedText: String) {
        Logger.i("ChatVM", "confirmFactCheck called with text: ${confirmedText.take(100)}")

        val state = _uiState.value.imageInputState
        val imageData = state.imageData
        val detectedLanguage = state.detectedLanguage

        Logger.d("ChatVM", "Image data present: ${imageData != null}")
        Logger.d("ChatVM", "Detected language: $detectedLanguage")

        if (imageData == null) {
            Logger.e("ChatVM", "Image data is null, cannot send fact-check message")
            return
        }

        Logger.d("ChatVM", "Dismissing confirmation dialog")
        // Dismiss dialog
        _uiState.update { it.copy(
            imageInputState = ImageInputState()
        )}

        Logger.i("ChatVM", "Calling sendFactCheckMessage")
        // Send fact-check message
        sendFactCheckMessage(confirmedText, imageData, detectedLanguage)
    }

    /**
     * Sends a fact-check message with image data and language.
     *
     * @param text The fact-check text
     * @param imageData The image data
     * @param detectedLanguage The detected language
     */
    private fun sendFactCheckMessage(text: String, imageData: ByteArray, detectedLanguage: String?) {
        Logger.i("ChatVM", "sendFactCheckMessage called")
        Logger.d("ChatVM", "Text: ${text.take(100)}")
        Logger.d("ChatVM", "Image data size: ${imageData.size} bytes")
        Logger.d("ChatVM", "Detected language: $detectedLanguage")

        val trimmedText = text.trim()
        if (trimmedText.isEmpty() || _uiState.value.isLoading) {
            Logger.w("ChatVM", "Cannot send fact-check message - text empty: ${trimmedText.isEmpty()}, already loading: ${_uiState.value.isLoading}")
            return
        }

        viewModelScope.launch {
            try {
                Logger.d("ChatVM", "Setting loading state")
                // Set loading state
                _uiState.update { state ->
                    state.copy(
                        isLoading = true,
                        error = null
                    )
                }

                Logger.d("ChatVM", "Creating user message with fact-check data")
                // Create user message with fact-check data
                val userMessage = com.shamelagpt.android.domain.model.Message(
                    id = java.util.UUID.randomUUID().toString(),
                    content = trimmedText,
                    isUserMessage = true,
                    timestamp = System.currentTimeMillis(),
                    sources = null,
                    imageData = imageData,
                    detectedLanguage = detectedLanguage,
                    isFactCheckMessage = true
                )
                Logger.d("ChatVM", "User message created with ID: ${userMessage.id}")

                // Get or create conversation ID
                val currentConversationId = _uiState.value.conversationId
                Logger.d("ChatVM", "Current conversation ID: $currentConversationId")

                val actualConversationId = currentConversationId ?: run {
                    Logger.i("ChatVM", "Creating new conversation for fact-check")
                    val title = if (trimmedText.length > 50) {
                        trimmedText.take(50).trim() + "..."
                    } else {
                        trimmedText.trim()
                    }
                    Logger.d("ChatVM", "Conversation title: $title")
                    val conversation = conversationRepository.createConversation(title)
                    Logger.i("ChatVM", "New conversation created with ID: ${conversation.id}")
                    conversation.id
                }

                Logger.d("ChatVM", "Saving user message to conversation: $actualConversationId")
                // Save user message
                conversationRepository.saveMessage(userMessage, actualConversationId)
                Logger.i("ChatVM", "User message saved successfully")

                // Wrap text for fact-checking API prompt
                val factCheckPrompt = """
                    Fact check this. If it is a Hadith, Quran, or other book reference, provide a definitive Yes/No answer regarding whether it was found in verified sources.
                    Especially if the text contains citations (e.g., file names or numbers), specifically verify those references against the actual text.
                    Your goal is to clarify the context and veracity of the shared text to remove any confusion.

                    Text to check:
                    $trimmedText
                """.trimIndent()
                Logger.d("ChatVM", "Fact-check prompt created: ${factCheckPrompt.take(100)}")

                Logger.i("ChatVM", "Sending fact-check request to API")
                // Send to API (don't save user message again - we already saved it with metadata)
                val result = sendMessageUseCase(
                    question = factCheckPrompt,
                    conversationId = actualConversationId,
                    threadId = _uiState.value.threadId,
                    saveUserMessage = false
                )

                result.fold(
                    onSuccess = { (response, conversationId) ->
                        Logger.i("ChatVM", "API request successful")
                        Logger.d("ChatVM", "Response conversation ID: $conversationId")
                        Logger.d("ChatVM", "Response thread ID: ${response.threadId}")

                        val wasNewConversation = currentConversationId == null
                        Logger.d("ChatVM", "Was new conversation: $wasNewConversation")

                        _uiState.update { state ->
                            state.copy(
                                isLoading = false,
                                conversationId = conversationId,
                                threadId = response.threadId
                            )
                        }

                        // If this was a new conversation, start observing messages
                        if (wasNewConversation) {
                            Logger.i("ChatVM", "Setting up messages Flow observer for new conversation")
                            viewModelScope.launch {
                                conversationRepository.getMessagesByConversationId(conversationId)
                                    .collect { messages ->
                                        Logger.d("ChatVM", "Received ${messages.size} messages from Flow")
                                        _uiState.update { state ->
                                            state.copy(messages = messages)
                                        }
                                    }
                            }
                        }

                        Logger.i("ChatVM", "Sending MessageSent and ScrollToBottom events")
                        _events.send(ChatEvent.MessageSent)
                        _events.send(ChatEvent.ScrollToBottom)
                    },
                    onFailure = { exception ->
                        Logger.e("ChatVM", "API request failed: ${exception.message}", exception)
                        _uiState.update { state ->
                            state.copy(
                                isLoading = false,
                                error = exception.message ?: "Failed to send fact-check message"
                            )
                        }
                        _events.send(
                            ChatEvent.ShowError(
                                exception.message ?: "Failed to send fact-check message"
                            )
                        )
                    }
                )
            } catch (e: Exception) {
                Logger.e("ChatVM", "Unexpected error in sendFactCheckMessage", e)
                _uiState.update { state ->
                    state.copy(
                        isLoading = false,
                        error = e.message ?: "An unexpected error occurred"
                    )
                }
                _events.send(ChatEvent.ShowError(e.message ?: "An unexpected error occurred"))
            }
        }
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
}
