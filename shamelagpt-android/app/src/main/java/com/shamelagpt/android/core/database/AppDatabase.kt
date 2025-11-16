package com.shamelagpt.android.core.database

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.shamelagpt.android.data.local.dao.ConversationDao
import com.shamelagpt.android.data.local.dao.MessageDao
import com.shamelagpt.android.data.local.entity.ConversationEntity
import com.shamelagpt.android.data.local.entity.MessageEntity

/**
 * Room database for ShamelaGPT application.
 *
 * Contains conversations and messages tables with proper relationships.
 */
@Database(
    entities = [
        ConversationEntity::class,
        MessageEntity::class
    ],
    version = 3,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {

    /**
     * Provides access to conversation operations.
     */
    abstract fun conversationDao(): ConversationDao

    /**
     * Provides access to message operations.
     */
    abstract fun messageDao(): MessageDao

    companion object {
        const val DATABASE_NAME = "shamelagpt_database"
    }
}
