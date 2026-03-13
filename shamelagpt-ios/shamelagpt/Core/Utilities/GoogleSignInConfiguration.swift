//
//  GoogleSignInConfiguration.swift
//  ShamelaGPT
//
//  Created by Codex on 12/03/2026.
//

import Foundation
import GoogleSignIn

enum GoogleSignInConfiguration {
    private static let iOSClientIDKey = "GIDClientID"
    private static let serverClientIDKey = "GIDServerClientID"

    static func configureSharedInstance() {
        guard let iOSClientID = infoString(for: iOSClientIDKey) else {
            AppLogger.auth.logWarning("google sign-in configuration skipped: missing \(iOSClientIDKey)")
            return
        }
        let serverClientID = infoString(for: serverClientIDKey)
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: iOSClientID,
            serverClientID: serverClientID
        )
        AppLogger.auth.logInfo("google sign-in configuration ready serverClientIdPresent=\(serverClientID != nil)")
    }

    private static func infoString(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
