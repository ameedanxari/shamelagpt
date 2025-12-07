import Foundation

/// Utility to detect language or script for a given text.
/// Uses `NSLinguisticTagger` dominant language and falls back to Unicode script heuristics for short text.
struct LanguageDetector {

    /// Detects a likely language code (ISO 639-1) for the given text.
    /// Returns nil if detection is inconclusive.
    static func detectLanguage(for text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Primary: NSLinguisticTagger dominant language
        if let dominant = NSLinguisticTagger.dominantLanguage(for: trimmed) {
            return dominant
        }

        // Fallback: check for Arabic-script characters
        if containsArabicScript(in: trimmed) {
            return "ar"
        }

        // Fallback: check for common Urdu characters (extended Arabic range + additional marks)
        if containsUrduIndicatives(in: trimmed) {
            return "ur"
        }

        return nil
    }

    /// Returns true if the string contains at least one Arabic-script scalar
    static func containsArabicScript(in text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // Arabic blocks: 0600–06FF, 0750–077F, 08A0–08FF, FB50–FDFF, FE70–FEFF
            let v = scalar.value
            if (v >= 0x0600 && v <= 0x06FF) || (v >= 0x0750 && v <= 0x077F) || (v >= 0x08A0 && v <= 0x08FF) || (v >= 0xFB50 && v <= 0xFDFF) || (v >= 0xFE70 && v <= 0xFEFF) {
                return true
            }
        }
        return false
    }

    /// Heuristic check for Urdu-specific indications (narrow heuristic)
    static func containsUrduIndicatives(in text: String) -> Bool {
        // Urdu uses Arabic script; we look for characters commonly present in Urdu (e.g., U+0691, U+06C1)
        let urduCodePoints: [UInt32] = [0x0691, 0x06C1, 0x06C2, 0x06BE]
        for scalar in text.unicodeScalars {
            if urduCodePoints.contains(scalar.value) {
                return true
            }
        }
        return false
    }
}
