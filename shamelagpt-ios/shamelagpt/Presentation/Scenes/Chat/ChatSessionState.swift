//
//  ChatSessionState.swift
//  ShamelaGPT
//
//  Created by Codex on 13/12/2025.
//

import Foundation

/// Centralized chat session state that keeps a single source of truth for the active conversation.
@MainActor
final class ChatSessionState: ObservableObject {

    enum State: Equatable {
        case new
        case existing(id: String)
    }

    @Published private(set) var state: State
    @Published private(set) var viewKey: String

    private let userDefaults: UserDefaults
    private let sessionManager: SessionManager
    private let authConversationKey = "lastConversationId"
    private let guestConversationKey = "guest_conversation_id"

    init(sessionManager: SessionManager, userDefaults: UserDefaults = .standard) {
        self.sessionManager = sessionManager
        self.userDefaults = userDefaults

        let restored = Self.restoreState(sessionManager: sessionManager, userDefaults: userDefaults)
        self.state = restored
        self.viewKey = Self.makeViewKey(for: restored)
    }

    var conversationId: String? {
        if case let .existing(id) = state { return id }
        return nil
    }

    /// Sets the current state and persists it.
    /// - Parameters:
    ///   - newState: target state to apply
    ///   - preserveViewKey: when true, keep the existing view identity (useful when the active ChatView is already streaming)
    func set(_ newState: State, preserveViewKey: Bool = false) {
        let isSame = state == newState
        state = newState
        if !preserveViewKey && (!isSame || newState == .new) {
            viewKey = Self.makeViewKey(for: newState)
        }
        persist(newState)
    }

    /// Resets to a fresh chat (no persisted conversation id).
    func resetToNew() {
        set(.new)
    }

    /// Re-applies persisted state from disk (used on app launch/appear).
    func refreshFromStorage() {
        let restored = Self.restoreState(sessionManager: sessionManager, userDefaults: userDefaults)
        set(restored)
    }

    private func persist(_ state: State) {
        let key = sessionManager.isGuest() ? guestConversationKey : authConversationKey
        switch state {
        case .existing(let id):
            userDefaults.set(id, forKey: key)
        case .new:
            userDefaults.removeObject(forKey: key)
        }
    }

    private static func restoreState(sessionManager: SessionManager, userDefaults: UserDefaults) -> State {
        let key = sessionManager.isGuest() ? "guest_conversation_id" : "lastConversationId"
        if let id = userDefaults.string(forKey: key), !id.isEmpty {
            return .existing(id: id)
        }
        return .new
    }

    private static func makeViewKey(for state: State) -> String {
        switch state {
        case .new:
            return "new-\(UUID().uuidString)"
        case .existing(let id):
            return "conversation-\(id)"
        }
    }
}
