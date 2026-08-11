//
//  ConversationMode.swift
//  ShamelaGPT
//
//  The answering mode the backend applies to a conversation.
//

import Foundation

/// How the assistant should answer.
///
/// The wire format is an integer, matching the `mode_preference` column
/// (`CHECK (mode_preference IN (0,1,2))`). `unset` is the value a brand-new account starts
/// with and is what triggers the one-time mode picker; the server treats it as `research`
/// so chat still works if the user never chooses.
///
/// **The mode is not sent per message.** The backend re-reads `mode_preference` from the
/// database on every stream, so changing mode means calling `PUT /api/auth/me/mode` and
/// nothing else. Putting a mode field in the chat body does nothing — `ChatRequest` has no
/// such field server-side and Pydantic silently ignores extras.
enum ConversationMode: Int, CaseIterable, Identifiable, Sendable {
    case unset = 0
    case research = 1
    case factCheck = 2

    var id: Int { rawValue }

    /// Modes a user can actually pick. `unset` is a server state, not a choice.
    static var selectable: [ConversationMode] { [.research, .factCheck] }

    /// Fact-check is sign-in only: guests are blocked in the web picker and the guest
    /// chat route never sets a mode server-side, so a guest would silently get research
    /// anyway. Better to say so than to appear to change something that cannot change.
    var requiresAuthentication: Bool {
        self == .factCheck
    }

    var titleKey: String {
        switch self {
        case .research, .unset: return LocalizationKeys.modeResearchTitle
        case .factCheck: return LocalizationKeys.modeFactCheckTitle
        }
    }

    var taglineKey: String {
        switch self {
        case .research, .unset: return LocalizationKeys.modeResearchTagline
        case .factCheck: return LocalizationKeys.modeFactCheckTagline
        }
    }

    /// SF Symbol standing in for the web's emoji (graduation cap / shield).
    var symbolName: String {
        switch self {
        case .research, .unset: return "graduationcap.fill"
        case .factCheck: return "checkmark.shield.fill"
        }
    }

    var bulletKeys: [String] {
        switch self {
        case .research, .unset:
            return [
                LocalizationKeys.modeResearchBullet1,
                LocalizationKeys.modeResearchBullet2,
                LocalizationKeys.modeResearchBullet3,
                LocalizationKeys.modeResearchBullet4
            ]
        case .factCheck:
            return [
                LocalizationKeys.modeFactCheckBullet1,
                LocalizationKeys.modeFactCheckBullet2,
                LocalizationKeys.modeFactCheckBullet3,
                LocalizationKeys.modeFactCheckBullet4
            ]
        }
    }
}
