package com.shamelagpt.android.core.error

import android.content.Context
import com.shamelagpt.android.R
import java.io.IOException

/**
 * Standardized error types for the ShamelaGPT application.
 */
sealed class AppError : Exception() {

    /** Debug code used for support tickets and logging */
    abstract val debugCode: String

    /** Localized, user-facing message */
    abstract fun getUserMessage(context: Context): String

    data class Network(val originalError: Throwable? = null) : AppError() {
        override val debugCode: String = "E-APP-001"
        override val message: String? = originalError?.message ?: "Network error occurred"

        override fun getUserMessage(context: Context): String {
            return context.getString(R.string.no_internet)
        }
    }

    data class Auth(val originalError: Throwable? = null) : AppError() {
        override val debugCode: String = "E-APP-002"
        override val message: String? = originalError?.message ?: "Authentication error"

        override fun getUserMessage(context: Context): String {
            return context.getString(R.string.error_generic_message)
        }
    }

    data class Api(val code: Int, val apiMessage: String?) : AppError() {
        override val debugCode: String = "E-APP-$code"
        override val message: String? = apiMessage ?: "API error ($code)"

        override fun getUserMessage(context: Context): String {
            return apiMessage ?: context.getString(R.string.error_generic_message)
        }
    }

    data class Database(val originalError: Throwable? = null) : AppError() {
        override val debugCode: String = "E-APP-003"
        override val message: String? = originalError?.message ?: "Database error"

        override fun getUserMessage(context: Context): String {
            return context.getString(R.string.error_generic_message)
        }
    }

    data class Unknown(val originalError: Throwable? = null) : AppError() {
        override val debugCode: String = "E-APP-004"
        override val message: String? = originalError?.message ?: "An unknown error occurred"

        override fun getUserMessage(context: Context): String {
            return context.getString(R.string.error_generic_message)
        }
    }

    /**
     * Map a throwable to an AppError
     */
    companion object {
        fun from(throwable: Throwable): AppError {
            return when (throwable) {
                is AppError -> throwable
                is IOException -> Network(throwable)
                // Add more specific mapping as needed
                else -> Unknown(throwable)
            }
        }
    }
}
