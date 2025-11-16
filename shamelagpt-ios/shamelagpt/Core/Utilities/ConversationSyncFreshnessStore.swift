//
//  ConversationSyncFreshnessStore.swift
//  ShamelaGPT
//

import Foundation

/// Persists freshness metadata for conversation/message remote syncs.
final class ConversationSyncFreshnessStore: @unchecked Sendable {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func shouldSyncConversations(forceRefresh: Bool, now: Date = Date()) -> Bool {
        if forceRefresh { return true }
        let lastSyncedAt = userDefaults.double(forKey: conversationsSyncAtKey)
        return isStale(lastSyncedAt: lastSyncedAt, ttl: conversationsTTL, now: now)
    }

    func markConversationsSynced(now: Date = Date()) {
        userDefaults.set(now.timeIntervalSince1970, forKey: conversationsSyncAtKey)
    }

    func shouldSyncMessages(conversationId: String, forceRefresh: Bool, now: Date = Date()) -> Bool {
        if forceRefresh { return true }
        let key = messagesSyncPrefix + conversationId
        let lastSyncedAt = userDefaults.double(forKey: key)
        return isStale(lastSyncedAt: lastSyncedAt, ttl: messagesTTL, now: now)
    }

    func markMessagesSynced(conversationId: String, now: Date = Date()) {
        let key = messagesSyncPrefix + conversationId
        userDefaults.set(now.timeIntervalSince1970, forKey: key)
    }

    private func isStale(lastSyncedAt: TimeInterval, ttl: TimeInterval, now: Date) -> Bool {
        if lastSyncedAt <= 0 { return true }
        return now.timeIntervalSince1970 - lastSyncedAt >= ttl
    }

    private let conversationsSyncAtKey = "conversation_sync_conversations_at"
    private let messagesSyncPrefix = "conversation_sync_messages_at_"
    private let conversationsTTL: TimeInterval = 5 * 60
    private let messagesTTL: TimeInterval = 5 * 60
}
