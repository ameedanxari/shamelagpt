package com.shamelagpt.android.core.network

import com.google.common.truth.Truth.assertThat
import org.junit.Test

/**
 * Unit tests for NetworkError sealed class.
 */
class NetworkErrorTest {

    @Test
    fun testNetworkErrorHttpError() {
        // Given
        val code = 404
        val message = "Not Found"

        // When
        val error = NetworkError.HttpError(code, message)

        // Then
        assertThat(error.code).isEqualTo(404)
        assertThat(error.message).contains("Not Found")
        assertThat(error).isInstanceOf(NetworkError::class.java)
    }

    @Test
    fun testNetworkErrorNetworkException() {
        // Given
        val message = "No internet connection"

        // When
        val error = NetworkError.NetworkException(message)

        // Then
        assertThat(error.message).contains("No internet connection")
        assertThat(error).isInstanceOf(NetworkError::class.java)
    }

    @Test
    fun testNetworkErrorUnknownError() {
        // Given
        val message = "Something went wrong"

        // When
        val error = NetworkError.UnknownError(message)

        // Then
        assertThat(error.message).contains("Something went wrong")
        assertThat(error).isInstanceOf(NetworkError::class.java)
    }

    @Test
    fun testHttpError400BadRequest() {
        // When
        val error = NetworkError.HttpError(400, "Bad Request")

        // Then
        assertThat(error.code).isEqualTo(400)
        assertThat(error.message).contains("Bad Request")
    }

    @Test
    fun testHttpError401Unauthorized() {
        // When
        val error = NetworkError.HttpError(401, "Unauthorized")

        // Then
        assertThat(error.code).isEqualTo(401)
        assertThat(error.message).contains("Unauthorized")
    }

    @Test
    fun testHttpError500ServerError() {
        // When
        val error = NetworkError.HttpError(500, "Internal Server Error")

        // Then
        assertThat(error.code).isEqualTo(500)
        assertThat(error.message).contains("Internal Server Error")
    }

    @Test
    fun testNetworkExceptionTimeout() {
        // When
        val error = NetworkError.NetworkException("Request timed out")

        // Then
        assertThat(error.message).contains("timed out")
    }

    @Test
    fun testNetworkExceptionConnectionRefused() {
        // When
        val error = NetworkError.NetworkException("Connection refused")

        // Then
        assertThat(error.message).contains("Connection refused")
    }

    @Test
    fun testUnknownErrorGeneric() {
        // When
        val error = NetworkError.UnknownError("Unknown error occurred")

        // Then
        assertThat(error.message).contains("Unknown error")
    }

    @Test
    fun testNetworkErrorIsException() {
        // Given
        val httpError = NetworkError.HttpError(404, "Not Found")
        val networkException = NetworkError.NetworkException("No connection")
        val unknownError = NetworkError.UnknownError("Unknown")

        // Then - All should be instances of Exception
        assertThat(httpError).isInstanceOf(Exception::class.java)
        assertThat(networkException).isInstanceOf(Exception::class.java)
        assertThat(unknownError).isInstanceOf(Exception::class.java)
    }
}
