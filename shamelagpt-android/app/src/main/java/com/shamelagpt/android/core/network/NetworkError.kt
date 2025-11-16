package com.shamelagpt.android.core.network

import android.content.Context
import com.shamelagpt.android.R
import com.shamelagpt.android.core.error.UserErrorMessage

/**
 * Sealed class representing network errors with user-friendly messages and debug information.
 * 
 * Each error type provides:
 * - [debugCode]: Technical code for tracking (e.g., "E-NET-001")
 * - [debugMessage]: Technical description for logging
 * - [getUserMessage]: Localized user-friendly message
 * - [isRetryable]: Whether the operation can be retried
 */
sealed class NetworkError : Exception() {
    
    /** Debug error code for tracking and support */
    abstract val debugCode: String
    
    /** Technical description for logging (not shown to users) */
    abstract val debugMessage: String
    
    /** Whether the error is retryable */
    open val isRetryable: Boolean = false
    
    /** Get localized user message from string resources */
    abstract fun getUserMessage(context: Context): String
    
    /** Get user message with debug code appended (for support tickets) */
    fun getUserMessageWithCode(context: Context): String {
        return UserErrorMessage.format(context, getUserMessage(context), debugCode)
    }
    
    // -------------------------------------------------------------------------
    // Error Types
    // -------------------------------------------------------------------------
    
    /**
     * No internet connection available.
     */
    object NoConnection : NetworkError() {
        override val debugCode = "E-NET-001"
        override val debugMessage = "[$debugCode] No network connection available"
        override val isRetryable = true
        override val message = debugMessage
        
        override fun getUserMessage(context: Context): String {
            return context.getString(R.string.network_no_connection)
        }
    }
    
    /**
     * Request timed out.
     */
    object Timeout : NetworkError() {
        override val debugCode = "E-NET-002"
        override val debugMessage = "[$debugCode] Request timed out"
        override val isRetryable = true
        override val message = debugMessage
        
        override fun getUserMessage(context: Context): String {
            return context.getString(R.string.network_timeout)
        }
    }
    
    /**
     * HTTP error with specific status code.
     */
    data class HttpError(val code: Int, val errorBody: String? = null) : NetworkError() {
        override val debugCode = "E-HTTP-$code"
        override val debugMessage = "[$debugCode] HTTP error: ${errorBody ?: "No details"}"
        override val isRetryable = code >= 500 || code == 429
        override val message = debugMessage
        
        override fun getUserMessage(context: Context): String {
            return when (code) {
                400 -> context.getString(R.string.network_invalid_request)
                401 -> context.getString(R.string.network_auth_required)
                403 -> context.getString(R.string.network_access_forbidden)
                404 -> context.getString(R.string.network_not_found)
                429 -> context.getString(R.string.network_too_many_requests)
                in 500..599 -> context.getString(R.string.network_server_error)
                else -> context.getString(R.string.network_generic_error)
            }
        }
    }
    
    /**
     * Unauthorized or authentication required.
     */
    object Unauthorized : NetworkError() {
        override val debugCode = "E-AUTH-001"
        override val debugMessage = "[$debugCode] Authentication required"
        override val message = debugMessage
        
        override fun getUserMessage(context: Context): String {
            return context.getString(R.string.network_auth_required)
        }
    }
    
    /**
     * Too many requests / rate limited.
     */
    object TooManyRequests : NetworkError() {
        override val debugCode = "E-RATE-001"
        override val debugMessage = "[$debugCode] Rate limited - too many requests"
        override val isRetryable = true
        override val message = debugMessage
        
        override fun getUserMessage(context: Context): String {
            return context.getString(R.string.network_too_many_requests)
        }
    }
    
    /**
     * Network exception (connectivity issues, DNS, etc.).
     */
    data class NetworkException(val originalMessage: String) : NetworkError() {
        override val debugCode = "E-NET-003"
        override val debugMessage = "[$debugCode] Network exception: $originalMessage"
        override val isRetryable = true
        override val message = debugMessage
        
        override fun getUserMessage(context: Context): String {
            return context.getString(R.string.network_connection_error)
        }
    }
    
    /**
     * Failed to decode/parse server response.
     */
    data class DecodingError(val originalMessage: String) : NetworkError() {
        override val debugCode = "E-DEC-001"
        override val debugMessage = "[$debugCode] Decoding failed: $originalMessage"
        override val message = debugMessage
        
        override fun getUserMessage(context: Context): String {
            return context.getString(R.string.network_decoding_error)
        }
    }
    
    /**
     * Unknown or unexpected error.
     */
    data class UnknownError(val originalMessage: String) : NetworkError() {
        override val debugCode = "E-UNK-001"
        override val debugMessage = "[$debugCode] Unknown error: $originalMessage"
        override val message = debugMessage
        
        override fun getUserMessage(context: Context): String {
            return context.getString(R.string.network_unexpected_error)
        }
    }
}
