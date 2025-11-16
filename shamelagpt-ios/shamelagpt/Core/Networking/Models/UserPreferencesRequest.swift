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
