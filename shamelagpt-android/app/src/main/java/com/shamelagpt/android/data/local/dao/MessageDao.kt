package com.shamelagpt.android.data.local.dao

import androidx.room.*
import com.shamelagpt.android.data.local.entity.MessageEntity
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object for message operations.
 */
@Dao
interface MessageDao {

    /**
     * Retrieves all messages for a specific conversation.
     *
     * @param conversationId Conversation ID
     * @return Flow of message list sorted by timestamp
     */
    @Query("SELECT * FROM messages WHERE conversationId = :conversationId ORDER BY timestamp ASC")
    fun getMessagesByConversationId(conversationId: String): Flow<List<MessageEntity>>

    @Query("SELECT COUNT(*) FROM messages WHERE conversationId = :conversationId")
    suspend fun countMessagesByConversationId(conversationId: String): Int

    /**
     * Inserts a new message.
     *
     * @param message Message to insert
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessage(message: MessageEntity)

    /**
     * Deletes all messages for a specific conversation.
     *
     * @param conversationId Conversation ID
     */
    @Query("DELETE FROM messages WHERE conversationId = :conversationId")
    suspend fun deleteMessagesByConversationId(conversationId: String)
}
