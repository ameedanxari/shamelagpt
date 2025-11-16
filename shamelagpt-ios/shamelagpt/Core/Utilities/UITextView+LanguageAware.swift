import UIKit

extension UITextView {
    /// Applies language-aware font to the full text. For editing flows consider applying per-run fonts.
    public func setLanguageAwareText(_ text: String, metadataLanguage: String? = nil, textStyle: UIFont.TextStyle = .body) {
        let languageCode: String?
        if let meta = metadataLanguage {
            languageCode = meta
        } else {
            languageCode = LanguageDetector.detectLanguage(for: text)
        }

        AppLogger.ui.logDebug("UITextView.setLanguageAwareText called; detectedLanguage=\(languageCode ?? "nil"), textPreview=\(text.prefix(40))")

        let font: UIFont = FontRegistry.shared.uiFont(forLanguage: languageCode, textStyle: textStyle)

        AppLogger.font.logDebug("UITextView will apply font=\(font.fontName) size=\(font.pointSize) for language=\(languageCode ?? "nil")")

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = self.textAlignment

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraph
        ]

        self.adjustsFontForContentSizeCategory = true
        self.attributedText = NSAttributedString(string: text, attributes: attrs)
    }
}
