//
//  AppError.swift
//  ShamelaGPT
//

import Foundation

/**
 * Standardized error types for the ShamelaGPT application.
 */
enum AppError: LocalizedError {
    case network(Error?)
    case auth(Error?)
    case api(Int, String?)
    case database(Error?)
    case unknown(Error?)
    
    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error?.localizedDescription ?? "Network error occurred"
        case .auth(let error):
            return error?.localizedDescription ?? "Authentication error"
        case .api(let code, let message):
            return message ?? "API error (\(code))"
        case .database(let error):
            return error?.localizedDescription ?? "Database error"
        case .unknown(let error):
            return error?.localizedDescription ?? "An unknown error occurred"
        }
    }
    
    /// User message with debug code appended (for support tickets)
    var userMessageWithCode: String {
        let messageKey: String
        let debugCode: String
        
        switch self {
        case .network:
            messageKey = LocalizationKeys.noInternetConnection
            debugCode = "E-APP-001"
        case .auth:
            messageKey = LocalizationKeys.somethingWentWrong
            debugCode = "E-APP-002"
        case .api(let code, _):
            messageKey = LocalizationKeys.somethingWentWrong
            debugCode = "E-APP-\(code)"
        case .database:
            messageKey = LocalizationKeys.somethingWentWrong
            debugCode = "E-APP-003"
        case .unknown:
            messageKey = LocalizationKeys.somethingWentWrong
            debugCode = "E-APP-004"
        }
        
        return UserErrorFormatter.format(messageKey: messageKey, code: debugCode)
    }
    
    /**
     * Map a generic error to an AppError
     */
    static func mapping(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .network(error)
        }
        
        // Add more specific mapping as needed
        return .unknown(error)
    }
}
