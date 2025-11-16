package com.shamelagpt.android.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Room entity representing a message in the local database.
 *
 * @property id Unique identifier (UUID)
 * @property conversationId Foreign key to ConversationEntity
 * @property content Message text content
 * @property isUserMessage True if sent by user, false if AI response
 * @property timestamp Message timestamp in milliseconds
 * @property sources JSON string of source citations (nullable)
 * @property imageData Compressed image thumbnail as byte array (nullable, for fact-check messages)
 * @property detectedLanguage ISO language code of detected text (nullable, e.g., "en", "ar")
 * @property isFactCheckMessage True if this is a fact-checking message
 */
@Entity(
    tableName = "messages",
    foreignKeys = [
        ForeignKey(
            entity = ConversationEntity::class,
            parentColumns = ["id"],
            childColumns = ["conversationId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["conversationId"])]
)
data class MessageEntity(
    @PrimaryKey
    val id: String,
    val conversationId: String,
    val content: String,
    val isUserMessage: Boolean,
    val timestamp: Long,
    val sources: String? = null,
    val imageData: ByteArray? = null,
    val detectedLanguage: String? = null,
    val isFactCheckMessage: Boolean = false
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as MessageEntity

        if (id != other.id) return false
        if (conversationId != other.conversationId) return false
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
        result = 31 * result + conversationId.hashCode()
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
