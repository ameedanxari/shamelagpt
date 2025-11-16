package com.shamelagpt.android.core.network

import com.google.common.truth.Truth.assertThat
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Test
import retrofit2.HttpException
import retrofit2.Response
import java.io.IOException

/**
 * Unit tests for safeApiCall function.
 */
class SafeApiCallTest {

    @Test
    fun testSafeApiCallSuccess() = runTest {
        // Given
        val expectedData = "Success Response"
        val apiCall: suspend () -> String = { expectedData }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(expectedData)
    }

    @Test
    fun testSafeApiCallHttpException404() = runTest {
        // Given
        val httpException = HttpException(
            Response.error<Any>(404, "Not Found".toResponseBody())
        )
        val apiCall: suspend () -> String = { throw httpException }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isFailure).isTrue()
        val error = result.exceptionOrNull() as? NetworkError.HttpError
        assertThat(error).isNotNull()
        assertThat(error?.code).isEqualTo(404)
    }

    @Test
    fun testSafeApiCallHttpException500() = runTest {
        // Given
        val httpException = HttpException(
            Response.error<Any>(500, "Internal Server Error".toResponseBody())
        )
        val apiCall: suspend () -> String = { throw httpException }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isFailure).isTrue()
        val error = result.exceptionOrNull() as? NetworkError.HttpError
        assertThat(error).isNotNull()
        assertThat(error?.code).isEqualTo(500)
    }

    @Test
    fun testSafeApiCallHttpException400() = runTest {
        // Given
        val httpException = HttpException(
            Response.error<Any>(400, "Bad Request".toResponseBody())
        )
        val apiCall: suspend () -> String = { throw httpException }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isFailure).isTrue()
        val error = result.exceptionOrNull() as? NetworkError.HttpError
        assertThat(error).isNotNull()
        assertThat(error?.code).isEqualTo(400)
    }

    @Test
    fun testSafeApiCallHttpException401() = runTest {
        // Given
        val httpException = HttpException(
            Response.error<Any>(401, "Unauthorized".toResponseBody())
        )
        val apiCall: suspend () -> String = { throw httpException }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isFailure).isTrue()
        val error = result.exceptionOrNull()
        assertThat(error).isEqualTo(NetworkError.Unauthorized)
    }

    @Test
    fun testSafeApiCallHttpException403() = runTest {
        // Given
        val httpException = HttpException(
            Response.error<Any>(403, "Forbidden".toResponseBody())
        )
        val apiCall: suspend () -> String = { throw httpException }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isFailure).isTrue()
        val error = result.exceptionOrNull()
        assertThat(error).isEqualTo(NetworkError.Unauthorized)
    }

    @Test
    fun testSafeApiCallHttpException429() = runTest {
        // Given
        val httpException = HttpException(
            Response.error<Any>(429, "Too Many Requests".toResponseBody())
        )
        val apiCall: suspend () -> String = { throw httpException }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isFailure).isTrue()
        val error = result.exceptionOrNull()
        assertThat(error).isEqualTo(NetworkError.TooManyRequests)
    }

    @Test
    fun testSafeApiCallHttpException422ValidationError() = runTest {
        // Given
        val httpException = HttpException(
            Response.error<Any>(422, "Validation Error".toResponseBody())
        )
        val apiCall: suspend () -> String = { throw httpException }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isFailure).isTrue()
        val error = result.exceptionOrNull() as? NetworkError.HttpError
        assertThat(error).isNotNull()
        assertThat(error?.code).isEqualTo(422)
    }

    @Test
    fun testSafeApiCallIOException() = runTest {
        // Given
        val ioException = IOException("Network connection error")
        val apiCall: suspend () -> String = { throw ioException }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isFailure).isTrue()
        val error = result.exceptionOrNull() as? NetworkError.NetworkException
        assertThat(error).isNotNull()
        assertThat(error?.message).contains("Network connection error")
    }

    @Test
    fun testSafeApiCallIOExceptionWithoutMessage() = runTest {
        // Given
        val ioException = IOException()
        val apiCall: suspend () -> String = { throw ioException }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isFailure).isTrue()
        val error = result.exceptionOrNull() as? NetworkError.NetworkException
        assertThat(error).isNotNull()
        assertThat(error?.message).contains("Network connection error")
    }

    @Test
    fun testSafeApiCallGenericException() = runTest {
        // Given
        val genericException = RuntimeException("Something went wrong")
        val apiCall: suspend () -> String = { throw genericException }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isFailure).isTrue()
        val error = result.exceptionOrNull() as? NetworkError.UnknownError
        assertThat(error).isNotNull()
        assertThat(error?.message).contains("Something went wrong")
    }

    @Test
    fun testSafeApiCallGenericExceptionWithoutMessage() = runTest {
        // Given
        val genericException = RuntimeException()
        val apiCall: suspend () -> String = { throw genericException }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isFailure).isTrue()
        val error = result.exceptionOrNull() as? NetworkError.UnknownError
        assertThat(error).isNotNull()
        assertThat(error?.message).contains("An unknown error occurred")
    }

    @Test
    fun testSafeApiCallWithComplexObject() = runTest {
        // Given
        data class TestData(val id: Int, val name: String)
        val expectedData = TestData(1, "Test")
        val apiCall: suspend () -> TestData = { expectedData }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(expectedData)
    }

    @Test
    fun testSafeApiCallPreservesHttpErrorCode() = runTest {
        // Given
        val httpException = HttpException(
            Response.error<Any>(404, "Not Found".toResponseBody())
        )
        val apiCall: suspend () -> String = { throw httpException }

        // When
        val result = safeApiCall { apiCall() }

        // Then
        val error = result.exceptionOrNull() as? NetworkError.HttpError
        assertThat(error?.code).isEqualTo(404)
    }
}
