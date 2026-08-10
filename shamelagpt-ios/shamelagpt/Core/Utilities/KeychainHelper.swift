//
//  KeychainHelper.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation
import Security

enum KeychainHelper {
    @discardableResult
    static func set(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // Without this the item defaults to `WhenUnlocked`, which is also carried into
            // iCloud/iTunes backups. Auth tokens should stay on the device that earned them.
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            // This status used to be discarded. A failed write left the app believing it
            // was signed in while every later request went out with no bearer token, which
            // the server answered with 403 and the app surfaced as a sign-out.
            AppLogger.session.logError(
                "Keychain WRITE failed key='\(key)' status=\(status) (\(describe(status)))"
            )
            return false
        }
        return true
    }

    static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                AppLogger.session.logError(
                    "Keychain READ failed key='\(key)' status=\(status) (\(describe(status)))"
                )
            }
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Human-readable name for the statuses that actually show up in practice.
    private static func describe(_ status: OSStatus) -> String {
        switch status {
        case errSecItemNotFound: return "errSecItemNotFound"
        case errSecDuplicateItem: return "errSecDuplicateItem"
        case errSecAuthFailed: return "errSecAuthFailed"
        case errSecInteractionNotAllowed: return "errSecInteractionNotAllowed"
        case -34018: return "errSecMissingEntitlement (app unsigned / no keychain access group)"
        default: return (SecCopyErrorMessageString(status, nil) as String?) ?? "unknown"
        }
    }

    static func remove(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        print("KeychainHelper: Removed key '\(key)' with status: \(status)")
    }
}
