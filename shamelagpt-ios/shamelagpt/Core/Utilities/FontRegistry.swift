import Foundation
import UIKit
import SwiftUI
import CoreText
import CoreGraphics

/// Central font registry mapping language codes to PostScript font names and providing scaled fonts.
final class FontRegistry {
    static let shared = FontRegistry()

    private init() {}

    /// Map language code (ISO 639-1) to preferred PostScript font name (bundle-installed or system).
    /// Update these names when bundling custom fonts in the project.
    private let languageToFontName: [String: String] = [
        "ar": "NotoNaskhArabic-Regular",
        "ur": "NotoNastaliqUrdu-Regular",
        "fa": "NotoNaskhArabic-Regular",
        "sd": "NotoNaskhArabic-Regular"
    ]

    /// Map language code to bundled font file to try as a fallback when PostScript names fail.
    /// These files are relative to the app bundle resource path.
    private let languageToFontFile: [String: String] = [
        "ar": "NotoNaskhArabic-wght.ttf",
        "ur": "NotoNastaliqUrdu-wght.ttf",
        "fa": "NotoNaskhArabic-wght.ttf",
        "sd": "NotoNaskhSindhi-Regular.ttf"
    ]

    // After bundling real fonts, prefer the Arabic registry font as a safer default for Arabic-script content.
    // Update this if you change the bundled font PostScript name.
    private let defaultFontName = "NotoNaskhArabic-Regular"

    /// Returns a scaled `UIFont` for the given language (nil = fallback) and text style.
    func uiFont(forLanguage languageCode: String?, textStyle: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        // Prefer the detected language. If no language is detected, fall back to the app language.
        // Only then consider the default registry font. This prevents unrelated languages (e.g., English UI text)
        // from picking the Arabic font when the app language is Arabic.
        let appLangCode = Locale.preferredLanguages.first.flatMap { Locale(identifier: $0).languageCode }
        var candidateLanguages: [String] = []
        if let lang = languageCode {
            candidateLanguages.append(lang)
        } else if let appLang = appLangCode {
            candidateLanguages.append(appLang)
        }
        // Always include a final fallback entry to try the registry default mapping
        candidateLanguages.append("default")

        // Use the preferred font size for the text style as a base
        let baseSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize

        // Helper to attempt loading a font for a given language code
        func attemptFont(for lang: String?) -> UIFont? {
            let resolvedFontName: String? = {
                if lang == "default" { return defaultFontName }
                if let lang = lang { return languageToFontName[lang] }
                return nil
            }()

            if let name = resolvedFontName, let named = UIFont(name: name, size: baseSize) {
                AppLogger.font.logDebug("UIFont(name:) succeeded for name=\(name), lang=\(lang ?? "nil"), returnedFont=\(named.fontName)")
                return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: named)
            }

            if let lang = lang, let fileRelative = languageToFontFile[lang] {
                let resourceURL = URL(fileURLWithPath: fileRelative)
                let fileNameOnly = resourceURL.lastPathComponent
                let subdirectory = resourceURL.deletingLastPathComponent().path

                var fontFileCandidates: [(name: String, subdirectory: String?)] = []
                if !subdirectory.isEmpty {
                    fontFileCandidates.append((name: fileNameOnly, subdirectory: subdirectory))
                }
                fontFileCandidates.append((name: fileNameOnly, subdirectory: nil))
                if fileRelative != fileNameOnly {
                    fontFileCandidates.append((name: fileRelative, subdirectory: nil))
                }

                AppLogger.font.logDebug("UIFont(name:) failed, attempting bundled file lookup for lang=\(lang), candidates=\(fontFileCandidates)")
                for candidate in fontFileCandidates {
                    guard let url = Bundle.main.url(forResource: candidate.name, withExtension: nil, subdirectory: candidate.subdirectory) else {
                        let locationDescription: String
                        if let subdir = candidate.subdirectory, !subdir.isEmpty {
                            locationDescription = "\(subdir)/\(candidate.name)"
                        } else {
                            locationDescription = candidate.name
                        }
                        AppLogger.font.logDebug("Bundled font candidate not found: \(locationDescription)")
                        continue
                    }

                    if let registeredFont = registerFontFromBundle(url: url, baseSize: baseSize, textStyle: textStyle) {
                        return registeredFont
                    }
                }

                let attemptedPaths = fontFileCandidates.map { candidate -> String in
                    if let subdir = candidate.subdirectory, !subdir.isEmpty {
                        return "\(subdir)/\(candidate.name)"
                    }
                    return candidate.name
                }

                AppLogger.font.logWarning("Bundled font file not found for lang=\(lang), attempted paths=\(attemptedPaths)")
            } else {
                AppLogger.font.logDebug("No bundled font file configured for languageCode=\(lang ?? "nil")")
            }

            return nil
        }

        AppLogger.font.logDebug("uiFont called with languageCode=\(languageCode ?? "nil"), appLanguage=\(appLangCode ?? "nil"), candidates=\(candidateLanguages), textStyle=\(textStyle), baseSize=\(baseSize)")

        // Try each candidate language in order
        for lang in candidateLanguages {
            if let font = attemptFont(for: lang == "default" ? nil : lang) {
                return font
            }
        }

        // Final fallback to system preferred font
        let fallback = UIFont.preferredFont(forTextStyle: textStyle)
        AppLogger.font.logDebug("Falling back to system font: \(fallback.fontName)")
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: fallback)
    }

    /// Returns a SwiftUI `Font` bridged from the registry's UIFont
    func swiftUIFont(forLanguage languageCode: String?, textStyle: UIFont.TextStyle, weight: Font.Weight = .regular) -> Font {
        let ui = uiFont(forLanguage: languageCode, textStyle: textStyle, weight: UIFont.Weight(weight))
        return Font(ui)
    }

    /// Attempt to register a bundled font file and return a scaled UIFont if successful.
    private func registerFontFromBundle(url: URL, baseSize: CGFloat, textStyle: UIFont.TextStyle) -> UIFont? {
        AppLogger.font.logDebug("Found bundled font file at: \(url.path)")
        guard let cgFont = CGFontCreateFromDataURL(url: url) else {
            AppLogger.font.logWarning("Failed to create CGFont from bundled file at: \(url.path)")
            return nil
        }

        if let postScriptCF = cgFont.postScriptName as CFString? {
            let postScript = postScriptCF as String
            AppLogger.font.logDebug("Bundled CGFont postScript name: \(postScript)")
            var registrationError: Unmanaged<CFError>?
            let registered = CTFontManagerRegisterGraphicsFont(cgFont, &registrationError)
            if !registered {
                let msg = registrationError?.takeRetainedValue().localizedDescription ?? "unknown"
                AppLogger.font.logWarning("Failed to register graphics font: \(msg)")
            } else {
                AppLogger.font.logDebug("Successfully registered graphics font: \(postScript)")
            }

            if let uiFromName = UIFont(name: postScript, size: baseSize) {
                AppLogger.font.logDebug("UIFont(name:) succeeded after registration, name=\(postScript), fontName=\(uiFromName.fontName)")
                return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: uiFromName)
            }
        }

        let ctFont = CTFontCreateWithGraphicsFont(cgFont, baseSize, nil, nil)
        let descriptor = CTFontCopyFontDescriptor(ctFont) as UIFontDescriptor
        let ui = UIFont(descriptor: descriptor, size: baseSize)
        AppLogger.font.logDebug("Created UIFont from CTFont fallback: \(ui.fontName)")
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: ui)
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

// Convenience helper to create CGFont from a file URL
fileprivate extension CGFont {
    static func create(from url: URL) -> CGFont? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        return CGFont(provider)
    }
}

// Helper to bridge to a CGFont and return it
fileprivate func CGFontCreateFromDataURL(url: URL) -> CGFont? {
    return CGFont.create(from: url)
}
