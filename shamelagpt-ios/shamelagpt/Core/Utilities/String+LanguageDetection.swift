import Foundation
import NaturalLanguage

extension String {
    /// Detects the language of the string using NaturalLanguage framework and custom heuristics.
    /// Returns "ar" for Arabic, "ur" for Urdu, or nil if indeterminate/other.
    func detectedLanguage() -> String? {
        // 1. Check for specific Urdu characters that are rarely/never used in standard Arabic.
        // These include:
        // ٹ (U+0679), ڈ (U+0688), ڑ (U+0691), ں (U+06BA), ے (U+06D2), ہ (U+06C1), ھ (U+06BE)
        // ژ (U+0698) is also Persian/Urdu but not Arabic.
        // گ (U+06AF), چ (U+0686), پ (U+067E) are Persian/Urdu.
        
        let urduSpecificChars = CharacterSet(charactersIn: "ٹڈڑںےہھژگچپ")
        if self.rangeOfCharacter(from: urduSpecificChars) != nil {
            return "ur"
        }
        
        // 2. Use NLLanguageRecognizer for general script detection
        if let dominantLanguage = NLLanguageRecognizer.dominantLanguage(for: self) {
            let langCode = dominantLanguage.rawValue
            // NLLanguageRecognizer might return "ur" or "ar" correctly.
            if langCode == "ur" || langCode == "ar" || langCode == "fa" {
                return langCode
            }
        }
        
        // 3. Fallback: Check if the text contains Arabic script characters.
        // If it looks like Arabic script but we didn't find Urdu chars, default to "ar".
        // Arabic block is roughly U+0600 to U+06FF.
        let arabicScript = CharacterSet(charactersIn: Unicode.Scalar(0x0600)!...Unicode.Scalar(0x06FF)!)
        if self.rangeOfCharacter(from: arabicScript) != nil {
            return "ar"
        }
        
        return nil
    }
}
