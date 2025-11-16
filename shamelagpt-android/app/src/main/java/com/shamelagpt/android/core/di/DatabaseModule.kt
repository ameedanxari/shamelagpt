package com.shamelagpt.android.core.di

import androidx.room.Room
import com.shamelagpt.android.core.database.AppDatabase
import com.shamelagpt.android.data.repository.ConversationRepositoryImpl
import com.shamelagpt.android.domain.repository.ConversationRepository
import com.shamelagpt.android.data.remote.datasource.ConversationRemoteDataSource
import com.shamelagpt.android.core.preferences.SessionManager
import com.shamelagpt.android.core.preferences.ConversationSyncMetadataStore
import org.koin.android.ext.koin.androidContext
import org.koin.dsl.module

/**
 * Koin module for database-related dependencies.
 *
 * Provides:
 * - AppDatabase instance (singleton)
 * - ConversationDao (singleton)
 * - MessageDao (singleton)
 * - ConversationRepository (singleton)
 */
val databaseModule = module {

    // Provide AppDatabase instance
    single {
        Room.databaseBuilder(
            androidContext(),
            AppDatabase::class.java,
            AppDatabase.DATABASE_NAME
        )
            .fallbackToDestructiveMigration() // For development; use migrations in production
            .build()
    }

    // Provide ConversationDao
    single { get<AppDatabase>().conversationDao() }

    // Provide MessageDao
    single { get<AppDatabase>().messageDao() }

    // Provide ConversationRepository
    single { ConversationSyncMetadataStore(androidContext()) }

    // Provide ConversationRepository
    single<ConversationRepository> {
        ConversationRepositoryImpl(
            conversationDao = get(),
            messageDao = get(),
            conversationRemoteDataSource = getOrNull<ConversationRemoteDataSource>(),
            sessionManager = getOrNull<SessionManager>(),
            syncMetadataStore = get()
        )
    }
}
