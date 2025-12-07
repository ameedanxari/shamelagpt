//
//  SessionManager.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

/// Manages auth tokens and session metadata.
final class SessionManager {
    private let refreshTokenKey = "refresh_token"
    private let tokenKey = "id_token"
    private let expiresAtKey = "expires_at"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveSession(token: String, refreshToken: String?, expiresInSeconds: TimeInterval?) {
        KeychainHelper.set(token, for: tokenKey)
        if let refresh = refreshToken {
            KeychainHelper.set(refresh, for: refreshTokenKey)
        }
        if let expires = expiresInSeconds {
            let expiryDate = Date().addingTimeInterval(expires)
            defaults.set(expiryDate.timeIntervalSince1970, forKey: expiresAtKey)
        }
    }

    func clearSession() {
        KeychainHelper.remove(tokenKey)
        KeychainHelper.remove(refreshTokenKey)
        defaults.removeObject(forKey: expiresAtKey)
    }

    func token() -> String? {
        guard let token = KeychainHelper.get(tokenKey) else { return nil }
        let expiresAt = defaults.double(forKey: expiresAtKey)
        if expiresAt == 0 { return token }
        return Date().timeIntervalSince1970 < expiresAt ? token : nil
    }

    func refreshToken() -> String? {
        KeychainHelper.get(refreshTokenKey)
    }

    func isLoggedIn() -> Bool {
        token() != nil
    }

    // MARK: - Guest Mode

    private let guestKey = "is_guest"
    private let guestSessionIdKey = "guest_session_id"

    func setGuest(_ isGuest: Bool) {
        defaults.set(isGuest, forKey: guestKey)
    }

    func isGuest() -> Bool {
        defaults.bool(forKey: guestKey)
    }

    /// Returns the persisted guest session id if present
    func guestSessionId() -> String? {
        return defaults.string(forKey: guestSessionIdKey)
    }

    /// Returns existing guest session id or creates, persists and returns a new one
    func getOrCreateGuestSessionId() -> String {
        if let existing = guestSessionId() {
            return existing
        }
        let newId = "guest_\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString.prefix(6))"
        defaults.set(newId, forKey: guestSessionIdKey)
        return newId
    }

    /// Clears the guest session id
    func clearGuestSessionId() {
        defaults.removeObject(forKey: guestSessionIdKey)
    }
}
