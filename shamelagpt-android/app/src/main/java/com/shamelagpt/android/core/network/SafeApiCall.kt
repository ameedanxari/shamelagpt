package com.shamelagpt.android.core.network

import com.shamelagpt.android.core.util.Logger
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
suspend fun <T> safeApiCall(
    authRetry: (suspend () -> Boolean)? = null,
    apiCall: suspend () -> T
): Result<T> {
    val tag = "SafeApiCall"
    return try {
        Result.success(apiCall())
    } catch (e: HttpException) {
        val errorBody = e.response()?.errorBody()?.string()
        val status = e.code()
        Logger.w(tag, "http error status=$status")
        if ((status == 401 || status == 403) && authRetry != null) {
            Logger.i(tag, "attempting auth retry for status=$status")
            val relogged = try { authRetry() } catch (_: Exception) { false }
            if (relogged) {
                Logger.i(tag, "auth retry succeeded; repeating request once")
                // Retry once without another authRetry to avoid loops
                return safeApiCall(apiCall = apiCall)
            }
            Logger.w(tag, "auth retry failed")
        }
        when (status) {
            401, 403 -> Result.failure(NetworkError.Unauthorized)
            429 -> Result.failure(NetworkError.TooManyRequests)
            else -> Result.failure(NetworkError.HttpError(code = status, errorBody = errorBody))
        }
    } catch (e: SocketTimeoutException) {
        Logger.w(tag, "request timeout")
        Result.failure(NetworkError.Timeout)
    } catch (e: UnknownHostException) {
        Logger.w(tag, "request failed: no connection")
        Result.failure(NetworkError.NoConnection)
    } catch (e: IOException) {
        // Check if it's a connection issue
        val message = e.message?.lowercase() ?: ""
        if (message.contains("unable to resolve host") || 
            message.contains("no address associated") ||
            message.contains("network is unreachable")) {
            Logger.w(tag, "request failed: network unreachable")
            Result.failure(NetworkError.NoConnection)
        } else {
            Logger.w(tag, "io exception during request: ${e::class.simpleName}")
            Result.failure(
                NetworkError.NetworkException(
                    originalMessage = e.message ?: "Network connection error"
                )
            )
        }
    } catch (e: Exception) {
        Logger.e(tag, "unexpected error during api call", e)
        Result.failure(
            NetworkError.UnknownError(
                originalMessage = e.message ?: "An unknown error occurred"
            )
        )
    }
}
