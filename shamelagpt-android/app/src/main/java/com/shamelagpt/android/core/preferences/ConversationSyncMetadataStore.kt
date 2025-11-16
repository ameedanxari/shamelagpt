package com.shamelagpt.android.core.preferences

import android.content.Context

/**
 * Persists freshness metadata for conversation and message sync operations.
 */
class ConversationSyncMetadataStore(context: Context) {

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun shouldSyncConversations(forceRefresh: Boolean, nowMs: Long = System.currentTimeMillis()): Boolean {
        if (forceRefresh) return true
        val lastSyncedAt = prefs.getLong(KEY_CONVERSATIONS_SYNC_AT, 0L)
        return isStale(lastSyncedAt, CONVERSATIONS_TTL_MS, nowMs)
    }

    fun markConversationsSynced(nowMs: Long = System.currentTimeMillis()) {
        prefs.edit().putLong(KEY_CONVERSATIONS_SYNC_AT, nowMs).apply()
    }

    fun shouldSyncMessages(
        conversationId: String,
        forceRefresh: Boolean,
        nowMs: Long = System.currentTimeMillis()
    ): Boolean {
        if (forceRefresh) return true
        val key = "$KEY_MESSAGES_SYNC_PREFIX$conversationId"
        val lastSyncedAt = prefs.getLong(key, 0L)
        return isStale(lastSyncedAt, MESSAGES_TTL_MS, nowMs)
    }

    fun markMessagesSynced(conversationId: String, nowMs: Long = System.currentTimeMillis()) {
        val key = "$KEY_MESSAGES_SYNC_PREFIX$conversationId"
        prefs.edit().putLong(key, nowMs).apply()
    }

    private fun isStale(lastSyncedAt: Long, ttlMs: Long, nowMs: Long): Boolean {
        if (lastSyncedAt <= 0L) return true
        return nowMs - lastSyncedAt >= ttlMs
    }

    private companion object {
        private const val PREFS_NAME = "conversation_sync_metadata"
        private const val KEY_CONVERSATIONS_SYNC_AT = "conversations_sync_at"
        private const val KEY_MESSAGES_SYNC_PREFIX = "messages_sync_at_"
        private const val CONVERSATIONS_TTL_MS = 5 * 60 * 1000L
        private const val MESSAGES_TTL_MS = 5 * 60 * 1000L
    }
}

