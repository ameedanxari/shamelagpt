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
    private let credentialsEmailKey = "auth_email"
    private let credentialsPasswordKey = "auth_password"
    private let useKeychain: Bool
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard, useKeychain: Bool = true) {
        self.defaults = defaults
        self.useKeychain = useKeychain
    }

    func saveSession(token: String, refreshToken: String?, expiresInSeconds: TimeInterval?) {
        AppLogger.session.logInfo(
            "saveSession called refreshTokenPresent=\(refreshToken != nil) hasExpiry=\(expiresInSeconds != nil)"
        )
        setItem(token, for: tokenKey)
        if let refresh = refreshToken {
            setItem(refresh, for: refreshTokenKey)
        }
        if let expires = expiresInSeconds {
            let expiryDate = Date().addingTimeInterval(expires)
            defaults.set(expiryDate.timeIntervalSince1970, forKey: expiresAtKey)
        }
    }

    func clearSession() {
        AppLogger.session.logInfo("clearSession called")
        removeItem(tokenKey)
        removeItem(refreshTokenKey)
        defaults.removeObject(forKey: expiresAtKey)
    }

    func token() -> String? {
        guard let token = getItem(tokenKey) else { return nil }
        let expiresAt = defaults.double(forKey: expiresAtKey)
        if expiresAt == 0 { return token }
        let isValid = Date().timeIntervalSince1970 < expiresAt
        if !isValid {
            AppLogger.session.logWarning("token considered expired by local expiry timestamp")
            return nil
        }
        return token
    }

    func refreshToken() -> String? {
        getItem(refreshTokenKey)
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

    // MARK: - Credential Storage (username/password)

    func saveCredentials(email: String, password: String) {
        AppLogger.session.logInfo("saveCredentials called")
        setItem(email, for: credentialsEmailKey)
        setItem(password, for: credentialsPasswordKey)
    }

    func storedCredentials() -> (email: String, password: String)? {
        guard
            let email = getItem(credentialsEmailKey),
            let password = getItem(credentialsPasswordKey),
            !email.isEmpty,
            !password.isEmpty
        else {
            return nil
        }
        return (email, password)
    }

    func clearCredentials() {
        AppLogger.session.logInfo("clearCredentials called")
        removeItem(credentialsEmailKey)
        removeItem(credentialsPasswordKey)
    }
    
    // MARK: - Storage Helpers
    
    private func setItem(_ value: String, for key: String) {
        if useKeychain {
            KeychainHelper.set(value, for: key)
        } else {
            defaults.set(value, forKey: "mock_keychain_" + key)
        }
    }
    
    private func getItem(_ key: String) -> String? {
        if useKeychain {
            return KeychainHelper.get(key)
        } else {
            return defaults.string(forKey: "mock_keychain_" + key)
        }
    }
    
    private func removeItem(_ key: String) {
        if useKeychain {
            KeychainHelper.remove(key)
        } else {
            defaults.removeObject(forKey: "mock_keychain_" + key)
        }
    }
}
