//
//  UITestEnvironment.swift
//  shamelagptUITests
//
//  Environment helpers for UI tests.
//

import Foundation

enum UITestEnvironment {
    /// Reads environment values using `getenv` to ensure updates after `setenv` are visible.
    static func value(_ key: String) -> String? {
        if let raw = getenv(key) {
            return String(cString: raw)
        }
        return ProcessInfo.processInfo.environment[key]
    }
}

enum UITestLanguageContext {
    private static var overrideLanguage: String?

    static var current: String? {
        overrideLanguage
    }

    static func set(_ language: String) {
        overrideLanguage = language
    }

    static func clear() {
        overrideLanguage = nil
    }

    static func forcedLanguage() -> String? {
        if let overrideLanguage {
            return overrideLanguage
        }
        return UITestEnvironment.value("FORCED_LANGUAGE")
    }
}
