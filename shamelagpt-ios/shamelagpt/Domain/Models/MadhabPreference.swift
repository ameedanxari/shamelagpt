//
//  MadhabPreference.swift
//  ShamelaGPT
//
//  Created by Codex on 21/08/2026.
//

import Foundation

/// The school of jurisprudence (madhhab) the backend uses to filter fiqh
/// sources during retrieval.
///
/// The API speaks raw slugs, so this enum is the single place that knows which
/// slugs are legal. Anything the server sends that we do not recognise collapses
/// to `.all`, which is also the backend default — an unknown value must never
/// leave the picker with no selection.
enum MadhabPreference: String, CaseIterable, Identifiable, Equatable {
    case all
    case hanafi
    case maliki
    case shafii
    case hanbali

    var id: String { rawValue }

    /// Maps a raw server value onto a known school, defaulting to `.all`.
    static func normalized(_ raw: String?) -> MadhabPreference {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return MadhabPreference(rawValue: trimmed) ?? .all
    }

    /// Localized school name, e.g. "Hanafi".
    var titleKey: String {
        switch self {
        case .all: return LocalizationKeys.madhabAll
        case .hanafi: return LocalizationKeys.madhabHanafi
        case .maliki: return LocalizationKeys.madhabMaliki
        case .shafii: return LocalizationKeys.madhabShafii
        case .hanbali: return LocalizationKeys.madhabHanbali
        }
    }

    /// The school's Arabic name, e.g. "حنفي". Always Arabic script regardless of
    /// the app language, matching the web.
    var arabicNameKey: String {
        switch self {
        case .all: return LocalizationKeys.madhabAllArabic
        case .hanafi: return LocalizationKeys.madhabHanafiArabic
        case .maliki: return LocalizationKeys.madhabMalikiArabic
        case .shafii: return LocalizationKeys.madhabShafiiArabic
        case .hanbali: return LocalizationKeys.madhabHanbaliArabic
        }
    }

    /// Founder and death year, e.g. "Abu Hanifa (d. 767 CE)".
    var descriptionKey: String {
        switch self {
        case .all: return LocalizationKeys.madhabAllDescription
        case .hanafi: return LocalizationKeys.madhabHanafiDescription
        case .maliki: return LocalizationKeys.madhabMalikiDescription
        case .shafii: return LocalizationKeys.madhabShafiiDescription
        case .hanbali: return LocalizationKeys.madhabHanbaliDescription
        }
    }
}
