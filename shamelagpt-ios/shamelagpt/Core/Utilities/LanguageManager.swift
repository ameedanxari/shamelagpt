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
    case urdu = "ur"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .arabic:
            return "العربية"
        case .urdu:
            return "اردو"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .english:
            return "en"
        case .arabic:
            return "ar"
        case .urdu:
            return "ur_PK"
        }
    }
}

/// Manages app language selection and localization
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    static let selectedLanguageKey = "selectedLanguage"

    @Published var currentLanguage: Language {
        didSet {
            saveLanguage()
            applyLanguage()
        }
    }

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private init() {
        // Check for forced language via launch arguments (highest priority)
        if let argIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "-Language"),
           argIndex + 1 < ProcessInfo.processInfo.arguments.count {
            let forcedLanguage = ProcessInfo.processInfo.arguments[argIndex + 1]
            if let language = Language(rawValue: forcedLanguage) {
                currentLanguage = language
                applyLanguage() // Ensure it's applied to system defaults
                return
            }
        }
        
        // If we are running in a UI test, also check for forced language env
        if let forcedLanguage = ProcessInfo.processInfo.environment["FORCED_LANGUAGE"],
           let language = Language(rawValue: forcedLanguage) {
            currentLanguage = language
            applyLanguage() // Ensure it's applied to system defaults
            return
        }
        
        // Load saved language, check system language, or default to English
        if let savedLanguage = UserDefaults.standard.string(forKey: Self.selectedLanguageKey),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        } else if let systemLang = Locale.preferredLanguages.first?.prefix(2).lowercased(),
                  let language = Language(rawValue: String(systemLang)) {
            currentLanguage = language
        } else {
            currentLanguage = .english
        }
    }

    /// Save current language to UserDefaults
    private func saveLanguage() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.selectedLanguageKey)
    }

    /// Apply language change to the app
    private func applyLanguage() {
        // Post notification for language change
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }

    /// Update language and notify observers
    func setLanguage(_ language: Language) {
        currentLanguage = language
    }

    /// Get display name for current language (localized based on current app locale)
    var currentLanguageDisplayName: String {
        LocalizationKeys.currentLanguage.localized
    }

    /// Localize a key using the app-selected language bundle (runtime-switch safe).
    func localizedString(forKey key: String, table: String = "Localizable") -> String {
        let bundle = localizationBundle(for: currentLanguage)
        let localized = bundle.localizedString(forKey: key, value: nil, table: table)
        return localized == key ? Bundle.main.localizedString(forKey: key, value: nil, table: table) : localized
    }

    private func localizationBundle(for language: Language) -> Bundle {
        let code = language.rawValue
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main
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
