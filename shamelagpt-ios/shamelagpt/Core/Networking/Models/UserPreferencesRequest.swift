//
//  UserPreferencesRequest.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

struct UserPreferencesRequest: Codable, Equatable {
    let languagePreference: String?
    let customSystemPrompt: String?
    let responsePreferences: ResponsePreferencesRequest?
}

struct ModePreferenceRequest: Codable, Equatable {
    let modePreference: Int
}

struct ModePreferenceResponse: Codable, Equatable {
    let modePreference: Int
    let modeName: String?
}

/// `PUT /api/auth/me/madhab` body. The wire type is the raw school slug
/// ("all", "hanafi", ...); `MadhabPreference` owns the set of valid values.
struct MadhabPreferenceRequest: Codable, Equatable {
    let madhabPreference: String
}

/// `GET`/`PUT /api/auth/me/madhab` response. `madhabName` is a server-rendered
/// display string; the app localizes its own labels, but decoding it keeps the
/// contract explicit and lets tests assert on it.
struct MadhabPreferenceResponse: Codable, Equatable {
    let madhabPreference: String
    let madhabName: String?
}
