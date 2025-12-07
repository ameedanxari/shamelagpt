package com.shamelagpt.android.core.network

import retrofit2.HttpException
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException

/**
 * Wrapper function for safe API calls with user-friendly error handling.
 *
 * Maps exceptions to [NetworkError] types with:
 * - User-friendly messages (via getUserMessage)
 * - Debug codes for tracking
 * - Retry logic hints
 *
 * @param apiCall The suspend API call to execute
 * @return Result with data or NetworkError
 */
suspend fun <T> safeApiCall(apiCall: suspend () -> T): Result<T> {
    return try {
        Result.success(apiCall())
    } catch (e: HttpException) {
        val errorBody = e.response()?.errorBody()?.string()
        when (e.code()) {
            401, 403 -> Result.failure(NetworkError.Unauthorized)
            429 -> Result.failure(NetworkError.TooManyRequests)
            else -> Result.failure(
                NetworkError.HttpError(
                    code = e.code(),
                    errorBody = errorBody
                )
            )
        }
    } catch (e: SocketTimeoutException) {
        Result.failure(NetworkError.Timeout)
    } catch (e: UnknownHostException) {
        Result.failure(NetworkError.NoConnection)
    } catch (e: IOException) {
        // Check if it's a connection issue
        val message = e.message?.lowercase() ?: ""
        if (message.contains("unable to resolve host") || 
            message.contains("no address associated") ||
            message.contains("network is unreachable")) {
            Result.failure(NetworkError.NoConnection)
        } else {
            Result.failure(
                NetworkError.NetworkException(
                    originalMessage = e.message ?: "Network connection error"
                )
            )
        }
    } catch (e: Exception) {
        Result.failure(
            NetworkError.UnknownError(
                originalMessage = e.message ?: "An unknown error occurred"
            )
        )
    }
}

