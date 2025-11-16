import Foundation
import UIKit
import SwiftUI

/// Central font registry for UI font resolution.
/// Current behavior intentionally returns system fonts for all languages.
final class FontRegistry {
    static let shared = FontRegistry()

    private init() {}

    /// Cache for resolved fonts to avoid redundant lookups
    private var fontCache: [String: UIFont] = [:]
    private let cacheLock = NSLock()

    /// Returns a scaled `UIFont` for the given language (nil = fallback) and text style.
    func uiFont(forLanguage _: String?, textStyle: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        let cacheKey = "system-\(textStyle.rawValue)-\(weight.rawValue)"
        cacheLock.lock()
        if let cached = fontCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let pointSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize
        let system = UIFont.systemFont(ofSize: pointSize, weight: weight)
        let scaled = UIFontMetrics(forTextStyle: textStyle).scaledFont(for: system)

        cacheLock.lock()
        fontCache[cacheKey] = scaled
        cacheLock.unlock()
        return scaled
    }

    /// Returns a SwiftUI `Font` bridged from the registry's UIFont
    func swiftUIFont(forLanguage languageCode: String?, textStyle: UIFont.TextStyle, weight: Font.Weight = .regular) -> Font {
        let ui = uiFont(forLanguage: languageCode, textStyle: textStyle, weight: UIFont.Weight(weight))
        return Font(ui)
    }
}

// Helper to convert SwiftUI Font.Weight to UIFont.Weight where needed
fileprivate extension UIFont.Weight {
    init(_ weight: Font.Weight) {
        switch weight {
        case .ultraLight: self = .ultraLight
        case .thin: self = .thin
        case .light: self = .light
        case .regular: self = .regular
        case .medium: self = .medium
        case .semibold: self = .semibold
        case .bold: self = .bold
        case .heavy: self = .heavy
        case .black: self = .black
        default: self = .regular
        }
    }
}
