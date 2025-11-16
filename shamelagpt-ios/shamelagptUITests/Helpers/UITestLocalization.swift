//
//  UITestLocalization.swift
//  shamelagptUITests
//
//  Reads app localization files directly for deterministic UI tests.
//

import Foundation

enum UITestLocalization {
    private static let resourcesRoot: URL = {
        let fileURL = URL(fileURLWithPath: #file)
        let shamelagptIOS = fileURL
            .deletingLastPathComponent() // Helpers
            .deletingLastPathComponent() // shamelagptUITests
            .deletingLastPathComponent() // shamelagpt-ios
        return shamelagptIOS.appendingPathComponent("shamelagpt/Resources")
    }()

    private static var cache: [String: [String: String]] = [:]

    static func localizedString(for key: String, language: String) -> String {
        let normalized = normalize(language)
        if let value = table(for: normalized)[key] {
            return value
        }
        if normalized != "en", let fallback = table(for: "en")[key] {
            return fallback
        }
        return key
    }

    private static func table(for language: String) -> [String: String] {
        if let cached = cache[language] {
            return cached
        }
        let path = resourcesRoot
            .appendingPathComponent("\(language).lproj")
            .appendingPathComponent("Localizable.strings")
            .path
        if let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
            cache[language] = dict
            return dict
        }
        cache[language] = [:]
        return [:]
    }

    private static func normalize(_ language: String) -> String {
        let trimmed = language.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 2 {
            return String(trimmed.prefix(2)).lowercased()
        }
        return trimmed.lowercased()
    }
}
