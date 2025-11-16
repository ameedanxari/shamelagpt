//
//  PreferencesRepository.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

struct UserPreferencesModel: Equatable {
    let languagePreference: String?
    let customSystemPrompt: String?
    let responsePreferences: ResponsePreferencesRequest?
}

protocol PreferencesRepository {
    func fetchPreferences() async throws -> UserPreferencesModel
    func updatePreferences(_ prefs: UserPreferencesModel) async throws
}
