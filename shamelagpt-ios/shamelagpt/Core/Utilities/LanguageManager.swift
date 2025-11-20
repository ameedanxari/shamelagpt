//
//  LanguageManager.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import SwiftUI

/// Language options supported by the app
enum Language: String, CaseIterable, Identifiable {
    case english = "en"
    case arabic = "ar"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .arabic:
            return "العربية"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .english:
            return "en"
        case .arabic:
            return "ar"
        }
    }
}

/// Manages app language selection and localization
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var currentLanguage: Language {
        didSet {
            saveLanguage()
            applyLanguage()
        }
    }

    private let languageKey = "selectedLanguage"

    private init() {
        // Load saved language or default to English
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            currentLanguage = .english
        }
    }

    /// Save current language to UserDefaults
    private func saveLanguage() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
    }

    /// Apply language change to the app
    private func applyLanguage() {
        // Set the app's language preference
        UserDefaults.standard.set([currentLanguage.localeIdentifier], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        // Post notification for language change
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }

    /// Update language and notify observers
    func setLanguage(_ language: Language) {
        currentLanguage = language
    }

    /// Get display name for current language
    var currentLanguageDisplayName: String {
        currentLanguage.displayName
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - AppStorage Support
extension Language {
    init?(appStorageValue: String) {
        self.init(rawValue: appStorageValue)
    }

    var appStorageValue: String {
        rawValue
    }
}
