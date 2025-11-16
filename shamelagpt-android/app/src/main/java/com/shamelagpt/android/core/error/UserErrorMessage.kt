package com.shamelagpt.android.core.error

import android.content.Context
import com.shamelagpt.android.R
import com.shamelagpt.android.core.network.NetworkError

/**
 * Central formatter for user-facing error messages with support guidance and error codes.
 */
object UserErrorMessage {
    fun format(context: Context, message: String, code: String): String {
        val codeLabel = context.getString(R.string.error_code_format, code)
        val suffix = context.getString(R.string.error_support_suffix)
        return "$message $codeLabel. $suffix"
    }

    fun from(context: Context, throwable: Throwable, fallbackCode: String = "E-APP-000"): String {
        return when (throwable) {
            is NetworkError -> format(context, throwable.getUserMessage(context), throwable.debugCode)
            is OcrError -> format(context, context.getString(throwable.messageRes), throwable.debugCode)
            is AppError -> format(context, throwable.getUserMessage(context), throwable.debugCode)
            else -> format(context, context.getString(R.string.error_generic_message), fallbackCode)
        }
    }
}
