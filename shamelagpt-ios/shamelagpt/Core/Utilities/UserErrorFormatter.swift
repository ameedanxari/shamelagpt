import Foundation

/// Formats user-facing error messages with a support suffix and error code.
enum UserErrorFormatter {
    static func format(messageKey: String, code: String) -> String {
        let message = LanguageManager.shared.localizedString(forKey: messageKey)
        return format(message: message, code: code)
    }

    static func format(message: String, code: String) -> String {
        let codeLabel = String(format: LanguageManager.shared.localizedString(forKey: LocalizationKeys.errorCodeFormat), code)
        let suffix = LanguageManager.shared.localizedString(forKey: LocalizationKeys.errorSupportSuffix)
        // What went wrong, then the diagnostics, separated by a blank line rather than run
        // into one paragraph. Previously the code and the reporting instructions were two
        // further sentences appended to the message, so the part the user needed to read
        // was a third of a wall of text and the retry button competed with it.
        return "\(message)\n\n\(codeLabel) · \(suffix)"
    }
}

extension Error {
    /// Consistent user-facing error message that includes a support suffix and error code.
    var userFacingMessage: String {
        if let networkError = self as? NetworkError {
            return networkError.userMessageWithCode
        }
        if let voiceError = self as? VoiceInputError {
            return voiceError.userMessageWithCode
        }
        if let ocrError = self as? OCRError {
            return ocrError.userMessageWithCode
        }
        if let appError = self as? AppError {
            return appError.userMessageWithCode
        }
        return UserErrorFormatter.format(messageKey: LocalizationKeys.somethingWentWrong, code: "E-APP-000")
    }
}
