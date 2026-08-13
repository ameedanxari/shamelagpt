//
//  NetworkError.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Errors that can occur during network operations
enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    /// HTTP 429. Carried separately from `httpError` because the `Retry-After` header is
    /// the only thing that lets the UI say *when* to try again, and `httpError` has
    /// nowhere to put it. `retryAfter` is in seconds, `nil` when the header was absent or
    /// not an integer (the spec also allows an HTTP-date, which we do not parse).
    case rateLimited(retryAfter: Int?)
    case badRequest
    case serverError(Int)
    case decodingError(Error)
    case noConnection
    case timeout
    case unknown(Error)

    // MARK: - Debug Information
    
    /// Debug error code for tracking and support (e.g., "E-NET-001")
    var debugCode: String {
        switch self {
        case .invalidURL:
            return "E-NET-001"
        case .invalidResponse:
            return "E-NET-002"
        case .noConnection:
            return "E-NET-003"
        case .timeout:
            return "E-NET-004"
        case .badRequest:
            return "E-REQ-001"
        case .httpError(let code):
            return "E-HTTP-\(code)"
        case .rateLimited:
            return "E-HTTP-429"
        case .serverError(let code):
            return "E-SRV-\(code)"
        case .decodingError:
            return "E-DEC-001"
        case .unknown:
            return "E-UNK-001"
        }
    }
    
    /// Technical description for logging/debugging (not shown to users)
    var debugDescription: String {
        switch self {
        case .invalidURL:
            return "[\(debugCode)] Invalid URL format"
        case .invalidResponse:
            return "[\(debugCode)] Server returned invalid response format"
        case .httpError(let statusCode):
            return "[\(debugCode)] HTTP error with status code \(statusCode)"
        case .rateLimited(let retryAfter):
            return "[\(debugCode)] Rate limited, retryAfter=\(retryAfter.map(String.init) ?? "nil")"
        case .badRequest:
            return "[\(debugCode)] Bad request - invalid parameters"
        case .serverError(let code):
            return "[\(debugCode)] Server error with status code \(code)"
        case .decodingError(let error):
            return "[\(debugCode)] Failed to decode response: \(error.localizedDescription)"
        case .noConnection:
            return "[\(debugCode)] No network connection available"
        case .timeout:
            return "[\(debugCode)] Request timed out"
        case .unknown(let error):
            return "[\(debugCode)] Unknown error: \(error.localizedDescription)"
        }
    }

    // MARK: - LocalizedError (for system/logging)
    
    var errorDescription: String? {
        return debugDescription
    }

    // MARK: - User-Facing Messages
    
    /// User-friendly error message for display in UI
    var userMessage: String {
        switch self {
        case .invalidURL, .invalidResponse:
            return LocalizationKeys.networkInvalidURL
        case .httpError(let statusCode):
            switch statusCode {
            case 400:
                return LocalizationKeys.networkInvalidRequest
            case 401:
                return LocalizationKeys.networkAuthRequired
            case 403:
                return LocalizationKeys.networkAccessForbidden
            case 404:
                return LocalizationKeys.networkResourceNotFound
            case 429:
                return LocalizationKeys.networkTooManyRequests
            case 500...599:
                return LocalizationKeys.networkServerError
            default:
                return LocalizationKeys.networkGenericError
            }
        case .rateLimited:
            return LocalizationKeys.networkTooManyRequests
        case .badRequest:
            return LocalizationKeys.networkInvalidRequest
        case .serverError:
            return LocalizationKeys.networkServerError
        case .decodingError:
            return LocalizationKeys.networkDecodingError
        case .noConnection:
            return LocalizationKeys.networkNoConnection
        case .timeout:
            return LocalizationKeys.networkTimeout
        case .unknown:
            return LocalizationKeys.networkUnexpectedError
        }
    }
    
    /// User message with debug code appended (for support tickets)
    var userMessageWithCode: String {
        UserErrorFormatter.format(messageKey: userMessage, code: debugCode)
    }

    // MARK: - Retry Logic
    
    /// Whether the error is retryable
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .rateLimited:
            return true
        case .httpError(let code):
            // Retry on 5xx server errors and 429 rate limiting
            return code >= 500 || code == 429
        case .serverError:
            return true
        default:
            return false
        }
    }

    // MARK: - Equatable
    
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.noConnection, .noConnection),
             (.timeout, .timeout),
             (.badRequest, .badRequest):
            return true
        case (.serverError(let l), .serverError(let r)):
            return l == r
        case (.httpError(let lhsCode), .httpError(let rhsCode)):
            return lhsCode == rhsCode
        case (.rateLimited(let lhsRetry), .rateLimited(let rhsRetry)):
            return lhsRetry == rhsRetry
        case (.decodingError(let lhsError), .decodingError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
