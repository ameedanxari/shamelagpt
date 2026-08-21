//
//  KeychainHelper.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation
import Security

enum KeychainHelper {
    static func set(_ value: String, for key: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // Without an explicit accessibility attribute the item defaults to
            // kSecAttrAccessibleWhenUnlocked, which is carried in encrypted device
            // backups and restored onto a new phone. ThisDeviceOnly keeps the session
            // on the device that created it; AfterFirstUnlock still allows a token
            // refresh to run before the user unlocks after a reboot.
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
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
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static func remove(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        // print() goes to the device console in release builds too. This now runs on
        // every login via clearCredentials(), so route it through the logger, which is
        // already the convention everywhere else in the app.
        let status = SecItemDelete(query as CFDictionary)
        AppLogger.session.logDebug("keychain remove key=\(key) status=\(status)")
    }
}
