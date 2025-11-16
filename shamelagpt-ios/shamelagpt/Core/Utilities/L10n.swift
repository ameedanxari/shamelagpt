import SwiftUI

/// Small localization helpers to make SwiftUI `Text` usage consistent.
/// Use `Text(someKey.localizedKey)` or `Text(L10n.key("settings.pref.length.title"))`.
struct L10n {
    static func key(_ key: String) -> LocalizedStringKey {
        return LocalizedStringKey(key)
    }

    /// Format a localization `key` with runtime string arguments and return a `LocalizedStringKey`.
    /// Useful when you need a formatted, already-localized string to be used with SwiftUI `Text`.
    static func formattedKey(_ key: String, _ args: CVarArg...) -> LocalizedStringKey {
        let format = LanguageManager.shared.localizedString(forKey: key)
        let formatted = String(format: format, arguments: args)
        return LocalizedStringKey(formatted)
    }

    /// Format a localization `key` with argument localization keys. Each `argKeys` entry
    /// will be localized first, then injected into the `key` format string.
    static func formattedKeyWithLocalizedArgs(_ key: String, argKeys: String...) -> LocalizedStringKey {
        let localizedArgs = argKeys.map { LanguageManager.shared.localizedString(forKey: $0) }
        let format = LanguageManager.shared.localizedString(forKey: key)
        let formatted = String(format: format, arguments: localizedArgs)
        return LocalizedStringKey(formatted)
    }
}

extension String {
    /// Convert a raw localization key to a `LocalizedStringKey` for use in `Text(...)`.
    var localizedKey: LocalizedStringKey { LocalizedStringKey(self) }

    /// Convenience to create a `Text` directly from a localization key string.
    var localizedText: Text { Text(LocalizedStringKey(self)) }
}
