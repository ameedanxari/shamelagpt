package com.shamelagpt.android.presentation.chat

import com.shamelagpt.android.domain.model.Message

/**
 * UI state for the chat screen.
 *
 * @property messages List of messages in the current conversation
 * @property inputText Current text in the input field
 * @property isLoading Whether the app is waiting for an AI response
 * @property error Error message to display, null if no error
 * @property conversationId Current conversation ID, null for new conversation
 * @property threadId API thread ID for maintaining context across messages
 * @property conversationTitle Title of the current conversation
 * @property voiceInputState State of voice input
 * @property imageInputState State of image input
 */
data class ChatUiState(
    val messages: List<Message> = emptyList(),
    val streamingMessage: Message? = null,
    val inputText: String = "",
    val isLoading: Boolean = false,
    val isHydratingConversation: Boolean = false,
    val error: String? = null,
    val conversationId: String? = null,
    val threadId: String? = null,
    val conversationTitle: String? = null,
    val thinkingMessages: List<String> = emptyList(),
    val voiceInputState: VoiceInputState = VoiceInputState(),
    val imageInputState: ImageInputState = ImageInputState()
)

/**
 * State for voice input functionality.
 *
 * @property isRecording Whether voice recording is currently active
 * @property transcribedText Text transcribed from voice input
 * @property error Error message for voice input, null if no error
 */
data class VoiceInputState(
    val isRecording: Boolean = false,
    val transcribedText: String = "",
    val error: String? = null,
    val isAvailable: Boolean = true,
    val requiresMicPermission: Boolean = true,
    val unavailableReason: String? = null
)

/**
 * State for image input functionality.
 *
 * @property isProcessing Whether image OCR is currently processing
 * @property extractedText Text extracted from image via OCR
 * @property detectedLanguage Detected language from OCR
 * @property imageData Raw image data for fact-checking
 * @property imageUri URI of the captured/selected image
 * @property showConfirmationDialog Whether to show OCR confirmation dialog
 * @property error Error message for image input, null if no error
 */
data class ImageInputState(
    val isProcessing: Boolean = false,
    val extractedText: String = "",
    val detectedLanguage: String? = null,
    val imageUrl: String? = null,
    val imageBase64: String? = null,
    val imageData: ByteArray? = null,
    val imageUri: android.net.Uri? = null,
    val showConfirmationDialog: Boolean = false,
    val error: String? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as ImageInputState

        if (isProcessing != other.isProcessing) return false
        if (imageUrl != other.imageUrl) return false
        if (imageBase64 != other.imageBase64) return false
        if (imageData != null) {
            if (other.imageData == null) return false
            if (!imageData.contentEquals(other.imageData)) return false
        } else if (other.imageData != null) return false
        if (imageUri != other.imageUri) return false
        if (showConfirmationDialog != other.showConfirmationDialog) return false
        if (error != other.error) return false

        return true
    }

    override fun hashCode(): Int {
        var result = isProcessing.hashCode()
        result = 31 * result + extractedText.hashCode()
        result = 31 * result + (detectedLanguage?.hashCode() ?: 0)
        result = 31 * result + (imageUrl?.hashCode() ?: 0)
        result = 31 * result + (imageBase64?.hashCode() ?: 0)
        result = 31 * result + (imageData?.contentHashCode() ?: 0)
        result = 31 * result + (imageUri?.hashCode() ?: 0)
        result = 31 * result + showConfirmationDialog.hashCode()
        result = 31 * result + (error?.hashCode() ?: 0)
        return result
    }
}
