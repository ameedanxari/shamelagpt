//
//  PreferencesRepositoryImpl.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

final class PreferencesRepositoryImpl: PreferencesRepository {
    private let apiClient: APIClientProtocol
    private let userDefaults: UserDefaults
    private let cacheKey = "cached_user_preferences"

    init(apiClient: APIClientProtocol, userDefaults: UserDefaults = .standard) {
        self.apiClient = apiClient
        self.userDefaults = userDefaults
    }

    func fetchPreferences() async throws -> UserPreferencesModel {
        // Try returning cached preferences immediately for snappy UX
        if let data = userDefaults.data(forKey: cacheKey) {
            do {
                let decoder = JSONDecoder()
                let cached = try decoder.decode(UserPreferencesRequest.self, from: data)
                let model = UserPreferencesModel(
                    languagePreference: cached.languagePreference,
                    customSystemPrompt: cached.customSystemPrompt,
                    responsePreferences: cached.responsePreferences
                )

                // Fire-and-forget refresh from API to update cache in background
                Task.detached { [apiClient, userDefaults, cacheKey] in
                    do {
                        let fresh = try await apiClient.getPreferences()
                        let enc = JSONEncoder()
                        if let d = try? enc.encode(fresh) {
                            userDefaults.set(d, forKey: cacheKey)
                        }
                    } catch {
                        AppLogger.network.logDebug("Background preferences refresh failed: \(error.localizedDescription)")
                    }
                }

                return model
            } catch {
                AppLogger.app.logWarning("Failed to decode cached preferences, will fetch from API: \(error.localizedDescription)")
                // fall through to fetch from API
            }
        }

        let response = try await apiClient.getPreferences()
        // Cache response locally
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(response)
            userDefaults.set(data, forKey: cacheKey)
        } catch {
            AppLogger.app.logWarning("Failed to encode preferences for cache: \(error.localizedDescription)")
        }

        return UserPreferencesModel(
            languagePreference: response.languagePreference,
            customSystemPrompt: response.customSystemPrompt,
            responsePreferences: response.responsePreferences
        )
    }

    func updatePreferences(_ prefs: UserPreferencesModel) async throws {
        let request = UserPreferencesRequest(
            languagePreference: prefs.languagePreference,
            customSystemPrompt: prefs.customSystemPrompt,
            responsePreferences: prefs.responsePreferences
        )
        try await apiClient.setPreferences(request)

        // On success, update local cache
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(request)
            userDefaults.set(data, forKey: cacheKey)
        } catch {
            AppLogger.app.logWarning("Failed to update cached preferences after setPreferences: \(error.localizedDescription)")
        }
    }
}
