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

    /// - Parameter owner: Whose cache is being asked about. A marker left by a different
    ///   owner is not staleness the TTL can express — it is a marker about somebody else —
    ///   so it never counts as fresh. This is what makes account switching, and a session
    ///   that expired and was replaced without a logout, re-sync immediately instead of
    ///   showing an empty History for the rest of the TTL.
    func shouldSyncConversations(forceRefresh: Bool, owner: String? = nil, now: Date = Date()) -> Bool {
        if forceRefresh { return true }
        if userDefaults.string(forKey: conversationsSyncOwnerKey) != owner { return true }
        let lastSyncedAt = userDefaults.double(forKey: conversationsSyncAtKey)
        return isStale(lastSyncedAt: lastSyncedAt, ttl: conversationsTTL, now: now)
    }

    func markConversationsSynced(owner: String? = nil, now: Date = Date()) {
        userDefaults.set(now.timeIntervalSince1970, forKey: conversationsSyncAtKey)
        if let owner {
            userDefaults.set(owner, forKey: conversationsSyncOwnerKey)
        } else {
            userDefaults.removeObject(forKey: conversationsSyncOwnerKey)
        }
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

    /// Forgets every "synced at" marker.
    ///
    /// Must run whenever the local cache is wiped. The TTL is the only thing stopping
    /// `syncRemoteConversations` from hitting the network, so a marker left behind after a
    /// wipe would make the next user's History look permanently empty until the TTL expired.
    func clear() {
        userDefaults.removeObject(forKey: conversationsSyncAtKey)
        userDefaults.removeObject(forKey: conversationsSyncOwnerKey)
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix(messagesSyncPrefix) {
            userDefaults.removeObject(forKey: key)
        }
    }

    private func isStale(lastSyncedAt: TimeInterval, ttl: TimeInterval, now: Date) -> Bool {
        if lastSyncedAt <= 0 { return true }
        return now.timeIntervalSince1970 - lastSyncedAt >= ttl
    }

    private let conversationsSyncAtKey = "conversation_sync_conversations_at"
    private let conversationsSyncOwnerKey = "conversation_sync_conversations_owner"
    private let messagesSyncPrefix = "conversation_sync_messages_at_"
    private let conversationsTTL: TimeInterval = 5 * 60
    private let messagesTTL: TimeInterval = 5 * 60
}
