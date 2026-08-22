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
    private let installMarkerKey = "install_marker"
    private let currentUserIdKey = "current_user_id"
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
        if let expires = expiresInSeconds, expires > 0 {
            let expiryDate = Date().addingTimeInterval(expires)
            defaults.set(expiryDate.timeIntervalSince1970, forKey: expiresAtKey)
        } else {
            // A zero or negative lifetime would stamp the expiry at or before now, so
            // token() would discard a token the server considers perfectly valid and
            // every request after it would go out unauthenticated. Record no expiry
            // instead and let the backend be the one to reject it. Removing rather than
            // leaving the key also clears any expiry from a previous session.
            if let expires = expiresInSeconds {
                AppLogger.session.logWarning(
                    "ignoring non-positive session lifetime \(expires); no local expiry recorded"
                )
            }
            defaults.removeObject(forKey: expiresAtKey)
        }
    }

    func clearSession() {
        AppLogger.session.logInfo("clearSession called")
        removeItem(tokenKey)
        removeItem(refreshTokenKey)
        defaults.removeObject(forKey: expiresAtKey)
        defaults.removeObject(forKey: currentUserIdKey)
    }

    // MARK: - Signed-in Identity

    /// The Firebase uid of the account this session belongs to.
    ///
    /// Kept in UserDefaults rather than the keychain on purpose: it is a pseudonymous
    /// identifier, not a credential, and UserDefaults is wiped when the app is deleted —
    /// which is exactly the lifetime we want for anything that says who the cache belongs
    /// to. Keychain items outlive a delete and would attach a fresh install's data to the
    /// previous owner.
    func currentUserId() -> String? {
        guard let id = defaults.string(forKey: currentUserIdKey), !id.isEmpty else { return nil }
        return id
    }

    /// Records who is signed in. Every successful auth response and `GET /api/auth/me`
    /// funnels through here so there is one answer to "whose device is this right now".
    func setCurrentUserId(_ id: String?) {
        guard let id, !id.isEmpty else {
            defaults.removeObject(forKey: currentUserIdKey)
            return
        }
        if currentUserId() == id { return }
        AppLogger.session.logInfo("recording signed-in user id=\(AppLogger.redactedId(id))")
        defaults.set(id, forKey: currentUserIdKey)
    }

    /// The identity locally cached conversations are filed under.
    ///
    /// Guests get the existing device-local guest session id rather than a second notion of
    /// identity, so one predicate covers both auth states. `nil` means the app cannot name
    /// anybody — no account and not a guest — and rows written before scoping existed also
    /// carry a nil owner. Those two are deliberately allowed to meet: a fetch that cannot
    /// name an owner returns only the unowned rows, and an identified user never sees them.
    func conversationOwnerId() -> String? {
        if let userId = currentUserId() { return userId }
        if isGuest() { return getOrCreateGuestSessionId() }
        return nil
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

    // MARK: - Legacy Credential Purge

    /// Builds before this change persisted the user's email and password so the app
    /// could silently re-login on launch. Nothing writes those keys any more, but
    /// upgrading installs still carry them, so every session teardown removes them.
    func clearCredentials() {
        AppLogger.session.logInfo("clearCredentials called")
        removeItem(credentialsEmailKey)
        removeItem(credentialsPasswordKey)
    }

    // MARK: - Fresh Install Detection

    /// Keychain items outlive app deletion on iOS, so a delete-and-reinstall would
    /// otherwise restore the previous session and look like an unrequested auto-login.
    /// UserDefaults *is* cleared on delete, which is what makes it usable as evidence
    /// that an install is new.
    ///
    /// The marker alone is not enough: it ships for the first time in this build, so
    /// installs upgrading in place are also missing it and must not be logged out.
    /// Session metadata in UserDefaults distinguishes them — it is written at login and
    /// survives an upgrade, whereas a genuine reinstall starts with UserDefaults empty
    /// and only the keychain carried over.
    func clearKeychainResidueIfFreshInstall() {
        guard !defaults.bool(forKey: installMarkerKey) else { return }
        defer { defaults.set(true, forKey: installMarkerKey) }

        if defaults.object(forKey: expiresAtKey) != nil {
            AppLogger.session.logInfo("existing install upgraded; session retained")
            return
        }

        AppLogger.session.logInfo("fresh install detected; clearing keychain residue")
        clearSession()
        clearCredentials()
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
