import UIKit

extension UILabel {
    /// Sets plain text applying a language-aware font. For mixed-language text, this applies a single
    /// font chosen by `LanguageDetector` for the dominant language. For richer per-run styling, use
    /// the attributed string helpers (todo: segmented runs using NSLinguisticTagger).
    public func setLanguageAwareText(_ text: String, metadataLanguage: String? = nil, textStyle: UIFont.TextStyle = .body) {
        let languageCode: String?
        if let meta = metadataLanguage {
            languageCode = meta
        } else {
            languageCode = LanguageDetector.detectLanguage(for: text)
        }

        AppLogger.ui.logDebug("UILabel.setLanguageAwareText called; detectedLanguage=\(languageCode ?? "nil"), textPreview=\(text.prefix(40))")

        let font: UIFont = FontRegistry.shared.uiFont(forLanguage: languageCode, textStyle: textStyle)

        AppLogger.font.logDebug("UILabel will apply font=\(font.fontName) size=\(font.pointSize) for language=\(languageCode ?? "nil")")

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = self.textAlignment

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraph
        ]

        self.numberOfLines = 0
        self.adjustsFontForContentSizeCategory = true
        self.attributedText = NSAttributedString(string: text, attributes: attrs)
    }
}
