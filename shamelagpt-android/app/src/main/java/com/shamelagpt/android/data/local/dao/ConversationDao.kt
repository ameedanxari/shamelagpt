package com.shamelagpt.android.data.local.dao

import androidx.room.*
import com.shamelagpt.android.data.local.entity.ConversationEntity
import kotlinx.coroutines.flow.Flow

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
    @Query("SELECT * FROM conversations ORDER BY updatedAt DESC")
    fun getAllConversations(): Flow<List<ConversationEntity>>

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
