package com.shamelagpt.android.domain.model

/**
 * Domain model representing a message in a conversation.
 *
 * @property id Unique identifier (UUID)
 * @property content Message text content
 * @property isUserMessage True if sent by user, false if AI response
 * @property timestamp Message timestamp in milliseconds
 * @property sources List of source citations (for AI responses)
 * @property imageData Compressed image thumbnail as byte array (for fact-check messages)
 * @property detectedLanguage ISO language code of detected text (e.g., "en", "ar")
 * @property isFactCheckMessage True if this is a fact-checking message
 */
data class Message(
    val id: String,
    val content: String,
    val isUserMessage: Boolean,
    val timestamp: Long,
    val sources: List<Source>? = null,
    val imageData: ByteArray? = null,
    val detectedLanguage: String? = null,
    val isFactCheckMessage: Boolean = false
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as Message

        if (id != other.id) return false
        if (content != other.content) return false
        if (isUserMessage != other.isUserMessage) return false
        if (timestamp != other.timestamp) return false
        if (sources != other.sources) return false
        if (imageData != null) {
            if (other.imageData == null) return false
            if (!imageData.contentEquals(other.imageData)) return false
        } else if (other.imageData != null) return false
        if (detectedLanguage != other.detectedLanguage) return false
        if (isFactCheckMessage != other.isFactCheckMessage) return false

        return true
    }

    override fun hashCode(): Int {
        var result = id.hashCode()
        result = 31 * result + content.hashCode()
        result = 31 * result + isUserMessage.hashCode()
        result = 31 * result + timestamp.hashCode()
        result = 31 * result + (sources?.hashCode() ?: 0)
        result = 31 * result + (imageData?.contentHashCode() ?: 0)
        result = 31 * result + (detectedLanguage?.hashCode() ?: 0)
        result = 31 * result + isFactCheckMessage.hashCode()
        return result
    }
}
