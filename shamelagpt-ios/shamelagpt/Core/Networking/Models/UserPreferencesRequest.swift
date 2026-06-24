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
