package com.shamelagpt.android.data.local.dao

import androidx.room.*
import com.shamelagpt.android.data.local.entity.ConversationEntity
import kotlinx.coroutines.flow.Flow
import androidx.room.ColumnInfo
import androidx.room.Embedded


/**
 * Data Access Object for conversation operations.
 */
@Dao
interface ConversationDao {

    /**
     * Retrieves all conversations sorted by most recent update.
     *
     * @return Flow of conversation list
     */
    @Query("""
        SELECT c.*, 
               m.content as last_message_content, 
               MAX(COALESCE(m.timestamp, c.updatedAt)) as latest_timestamp 
        FROM conversations c
        LEFT JOIN (
            SELECT conversationId, content, timestamp
            FROM messages
            WHERE (conversationId, timestamp) IN (
                SELECT conversationId, MAX(timestamp)
                FROM messages
                GROUP BY conversationId
            )
        ) m ON c.id = m.conversationId
        GROUP BY c.id
        ORDER BY latest_timestamp DESC
    """)
    fun getAllConversations(): Flow<List<ConversationWithLastMessageEntity>>


    /**
     * Retrieves a specific conversation by ID.
     *
     * @param id Conversation ID
     * @return Conversation entity or null if not found
     */
    @Query("SELECT * FROM conversations WHERE id = :id")
    suspend fun getConversationById(id: String): ConversationEntity?

    /**
     * Inserts a new conversation.
     *
     * @param conversation Conversation to insert
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertConversation(conversation: ConversationEntity)

    /**
     * Updates an existing conversation.
     *
     * @param conversation Conversation to update
     */
    @Update
    suspend fun updateConversation(conversation: ConversationEntity)

    /**
     * Deletes a specific conversation.
     *
     * @param conversation Conversation to delete
     */
    @Delete
    suspend fun deleteConversation(conversation: ConversationEntity)

    /**
     * Deletes all conversations.
     */
    @Query("DELETE FROM conversations")
    suspend fun deleteAllConversations()
}

/**
 * POJO for conversation with its last message details.
 */
data class ConversationWithLastMessageEntity(
    @Embedded val conversation: ConversationEntity,
    @ColumnInfo(name = "last_message_content") val lastMessageContent: String?,
    @ColumnInfo(name = "latest_timestamp") val latestTimestamp: Long?
)
