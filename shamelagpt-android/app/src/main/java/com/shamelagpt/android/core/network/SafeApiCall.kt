package com.shamelagpt.android.core.network

import retrofit2.HttpException
import java.io.IOException

/**
 * Wrapper function for safe API calls with error handling.
 *
 * @param apiCall The suspend API call to execute
 * @return Result with data or error
 */
suspend fun <T> safeApiCall(apiCall: suspend () -> T): Result<T> {
    return try {
        Result.success(apiCall())
    } catch (e: HttpException) {
        Result.failure(
            NetworkError.HttpError(
                code = e.code(),
                message = e.message() ?: "HTTP error ${e.code()}"
            )
        )
    } catch (e: IOException) {
        Result.failure(
            NetworkError.NetworkException(
                message = e.message ?: "Network connection error"
            )
        )
    } catch (e: Exception) {
        Result.failure(
            NetworkError.UnknownError(
                message = e.message ?: "An unknown error occurred"
            )
        )
    }
}
