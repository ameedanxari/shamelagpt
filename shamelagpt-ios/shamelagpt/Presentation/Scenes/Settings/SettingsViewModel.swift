//
//  SettingsViewModel.swift
//  ShamelaGPT
//
//  Created by Codex on 12/01/2026.
//

import Foundation
import Combine
import UIKit

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var customPrompt: String = ""
    @Published var lengthPref: String = ""
    @Published var stylePref: String = ""
    @Published var focusPref: String = ""
    
    @Published var isLoading = false
    @Published var error: String?
    
    @Published var showDeleteAccountConfirmation = false
    @Published var isDeletingAccount = false
    @Published var deleteAccountError: String?
    
    private let preferencesRepository: PreferencesRepository?
    private let authRepository: AuthRepository?
    private let languageManager: LanguageManager
    
    init(
        preferencesRepository: PreferencesRepository? = DependencyContainer.shared.resolve(PreferencesRepository.self),
        authRepository: AuthRepository? = DependencyContainer.shared.resolve(AuthRepository.self),
        languageManager: LanguageManager = LanguageManager.shared
    ) {
        self.preferencesRepository = preferencesRepository
        self.authRepository = authRepository
        self.languageManager = languageManager
    }
    
    func loadPreferences(force: Bool = false) async {
        guard let repo = preferencesRepository else { return }
        isLoading = true
        error = nil
        do {
            let prefs = try await repo.fetchPreferences()
            customPrompt = prefs.customSystemPrompt ?? ""
            lengthPref = prefs.responsePreferences?.length ?? ""
            stylePref = prefs.responsePreferences?.style ?? ""
            focusPref = prefs.responsePreferences?.focus ?? ""
        } catch {
            AppLogger.app.logError("Failed to load preferences", error: error)
            self.error = LanguageManager.shared.localizedString(forKey: LocalizationKeys.preferencesLoadFailed)
        }
        isLoading = false
    }
    
    func savePreferences() async {
        guard let repo = preferencesRepository else { return }
        isLoading = true
        error = nil
        do {
            let prefs = UserPreferencesModel(
                languagePreference: languageManager.currentLanguage.rawValue,
                customSystemPrompt: customPrompt.isEmpty ? nil : customPrompt,
                responsePreferences: ResponsePreferencesRequest(
                    length: lengthPref.isEmpty ? nil : lengthPref,
                    style: stylePref.isEmpty ? nil : stylePref,
                    focus: focusPref.isEmpty ? nil : focusPref
                )
            )
            try await repo.updatePreferences(prefs)
        } catch {
            AppLogger.app.logError("Failed to save preferences", error: error)
            self.error = LanguageManager.shared.localizedString(forKey: LocalizationKeys.preferencesSaveFailed)
        }
        isLoading = false
    }
    
    func deleteAccount(onSuccess: @escaping () -> Void) async {
        guard let repo = authRepository else {
            deleteAccountError = LanguageManager.shared.localizedString(forKey: LocalizationKeys.deleteAccountServiceUnavailable)
            return
        }
        isDeletingAccount = true
        deleteAccountError = nil
        do {
            try await repo.deleteCurrentUser()
            isDeletingAccount = false
            onSuccess()
        } catch {
            isDeletingAccount = false
            AppLogger.app.logError("Failed to delete account", error: error)
            deleteAccountError = LanguageManager.shared.localizedString(forKey: LocalizationKeys.deleteAccountError)
        }
    }
}
