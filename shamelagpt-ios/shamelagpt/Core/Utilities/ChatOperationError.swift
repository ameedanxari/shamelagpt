import Foundation

enum ChatOperation {
    case sendMessage
    case loadConversation
    case syncMessages
    case factCheck
    case ocr
    case shareImport
    case modePreference
    case continuity
}

struct ChatOperationFailure {
    let userMessage: String
    let debugCode: String
    let retryable: Bool
    let requiresAuth: Bool
}

struct ChatOperationException: LocalizedError {
    let operation: ChatOperation
    let code: String
    let retryable: Bool
    let description: String

    var errorDescription: String? { description }
}

enum ChatOperationError {
    static func from(_ error: Error, operation: ChatOperation) -> ChatOperationFailure {
        if let networkError = error as? NetworkError {
            let requiresAuth: Bool
            if case .httpError(let statusCode) = networkError {
                requiresAuth = statusCode == 401 || statusCode == 403
            } else {
                requiresAuth = false
            }
            return ChatOperationFailure(
                userMessage: networkError.userMessageWithCode,
                debugCode: networkError.debugCode,
                retryable: networkError.isRetryable,
                requiresAuth: requiresAuth
            )
        }

        if let chatError = error as? ChatOperationException {
            return ChatOperationFailure(
                userMessage: UserErrorFormatter.format(messageKey: messageKey(for: chatError.operation), code: chatError.code),
                debugCode: chatError.code,
                retryable: chatError.retryable,
                requiresAuth: false
            )
        }

        if error is CancellationError {
            return ChatOperationFailure(
                userMessage: UserErrorFormatter.format(messageKey: LocalizationKeys.chatErrorRequestCancelled, code: "E-CHAT-CANCELLED"),
                debugCode: "E-CHAT-CANCELLED",
                retryable: true,
                requiresAuth: false
            )
        }

        return ChatOperationFailure(
            userMessage: UserErrorFormatter.format(messageKey: messageKey(for: operation), code: code(for: operation)),
            debugCode: code(for: operation),
            retryable: true,
            requiresAuth: false
        )
    }

    static func warningMessage(for operation: ChatOperation) -> String {
        LanguageManager.shared.localizedString(forKey: messageKey(for: operation))
    }

    private static func messageKey(for operation: ChatOperation) -> String {
        switch operation {
        case .sendMessage:
            return LocalizationKeys.chatErrorSendFailed
        case .loadConversation:
            return LocalizationKeys.chatErrorConversationUnavailable
        case .syncMessages:
            return LocalizationKeys.chatWarningShowingSavedMessages
        case .factCheck:
            return LocalizationKeys.chatErrorFactCheckFailed
        case .ocr:
            return LocalizationKeys.ocrRecognitionFailed
        case .shareImport:
            return LocalizationKeys.chatErrorShareImportFailed
        case .modePreference:
            return LocalizationKeys.chatWarningModePreferenceNotSaved
        case .continuity:
            return LocalizationKeys.chatWarningContinuityNotSaved
        }
    }

    private static func code(for operation: ChatOperation) -> String {
        switch operation {
        case .sendMessage:
            return "E-CHAT-SEND"
        case .loadConversation:
            return "E-CHAT-LOAD"
        case .syncMessages:
            return "E-CHAT-SYNC"
        case .factCheck:
            return "E-CHAT-FACT"
        case .ocr:
            return "E-CHAT-OCR"
        case .shareImport:
            return "E-CHAT-SHARE"
        case .modePreference:
            return "E-CHAT-MODE"
        case .continuity:
            return "E-CHAT-CONTINUITY"
        }
    }
}
