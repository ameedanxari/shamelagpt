import SwiftUI
import UIKit

/// SwiftUI ViewModifier that applies a language-aware font to text-bearing views.
/// It uses `FontRegistry` and `LanguageDetector` if available, and falls back to
/// `AppTheme.Typography` if not.
public struct LanguageAwareFontModifier: ViewModifier {
    private let explicitLanguage: String?
    private let textStyle: UIFont.TextStyle
    private let size: CGFloat?
    private let textContent: String?

    public init(language: String? = nil, textStyle: UIFont.TextStyle = .body, size: CGFloat? = nil, text: String? = nil) {
        self.explicitLanguage = language
        self.textStyle = textStyle
        self.size = size
        self.textContent = text
    }

    public func body(content: Content) -> some View {
        // Determine the language to use:
        // 1. Explicit language if provided
        // 2. Detected language from text content if available
        // 3. Fallback (handled by FontRegistry or nil)
        let languageCode = explicitLanguage ?? textContent?.detectedLanguage()
        
        // Use the centralized FontRegistry if available
        let swiftUIFont = FontRegistry.shared.swiftUIFont(forLanguage: languageCode, textStyle: textStyle)
        AppLogger.font.logDebug("LanguageAwareFontModifier resolved language=\(languageCode ?? "nil") -> swiftUIFont=\(swiftUIFont)")
        return content.font(swiftUIFont)
    }
}

public extension View {
    func languageAwareFont(language: String? = nil, textStyle: UIFont.TextStyle = .body, size: CGFloat? = nil, text: String? = nil) -> some View {
        modifier(LanguageAwareFontModifier(language: language, textStyle: textStyle, size: size, text: text))
    }
}
