package com.shamelagpt.android.core.network

/**
 * Sealed class representing network errors.
 */
sealed class NetworkError : Exception() {
    /**
     * HTTP error with status code.
     */
    data class HttpError(val code: Int, override val message: String) : NetworkError()

    /**
     * Network exception (connectivity issues, timeout, etc.).
     */
    data class NetworkException(override val message: String) : NetworkError()

    /**
     * Unknown error.
     */
    data class UnknownError(override val message: String) : NetworkError()
}
