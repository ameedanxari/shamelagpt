//
//  NetworkError.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Errors that can occur during network operations
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case noConnection
    case timeout
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return LocalizationKeys.networkInvalidURL.localized
        case .invalidResponse:
            return LocalizationKeys.networkInvalidResponse.localized
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noConnection:
            return LocalizationKeys.networkNoConnection.localized
        case .timeout:
            return LocalizationKeys.networkTimeout.localized
        case .unknown(let error):
            return LocalizationKeys.networkUnknownError.localized + ": \(error.localizedDescription)"
        }
    }

    /// User-friendly error message
    var userMessage: String {
        switch self {
        case .invalidURL, .invalidResponse:
            return LocalizationKeys.networkInvalidURL.localized
        case .httpError(let statusCode):
            switch statusCode {
            case 400:
                return LocalizationKeys.networkInvalidRequest.localized
            case 401:
                return LocalizationKeys.networkAuthRequired.localized
            case 403:
                return LocalizationKeys.networkAccessForbidden.localized
            case 404:
                return LocalizationKeys.networkResourceNotFound.localized
            case 429:
                return LocalizationKeys.networkTooManyRequests.localized
            case 500...599:
                return LocalizationKeys.networkServerError.localized
            default:
                return LocalizationKeys.networkGenericError.localized
            }
        case .decodingError:
            return LocalizationKeys.networkDecodingError.localized
        case .noConnection:
            return LocalizationKeys.networkNoConnection.localized
        case .timeout:
            return LocalizationKeys.networkTimeout.localized
        case .unknown:
            return LocalizationKeys.networkUnexpectedError.localized
        }
    }

    /// Whether the error is retryable
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout:
            return true
        case .httpError(let code):
            // Retry on 5xx server errors
            return code >= 500
        default:
            return false
        }
    }
}
