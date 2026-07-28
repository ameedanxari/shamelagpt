package com.shamelagpt.android.core.error

import android.content.Context
import com.shamelagpt.android.R
import com.shamelagpt.android.core.network.NetworkError
import java.util.concurrent.CancellationException

enum class ChatOperation {
    SEND_MESSAGE,
    LOAD_CONVERSATION,
    SYNC_MESSAGES,
    FACT_CHECK,
    OCR,
    SHARE_IMPORT,
    MODE_PREFERENCE,
    CONTINUITY
}

data class ChatOperationFailure(
    val userMessage: String,
    val debugCode: String,
    val retryable: Boolean,
    val requiresAuth: Boolean = false
)

class ChatOperationException(
    val operation: ChatOperation,
    val code: String,
    message: String,
    val retryable: Boolean = true,
    cause: Throwable? = null
) : Exception(message, cause)

object ChatOperationError {
    fun from(context: Context, operation: ChatOperation, throwable: Throwable): ChatOperationFailure {
        return when (throwable) {
            is NetworkError.GuestQuotaExceeded -> ChatOperationFailure(
                userMessage = throwable.getUserMessage(context),
                debugCode = throwable.debugCode,
                retryable = throwable.isRetryable,
                requiresAuth = true
            )
            is NetworkError -> ChatOperationFailure(
                userMessage = throwable.getUserMessageWithCode(context),
                debugCode = throwable.debugCode,
                retryable = throwable.isRetryable,
                requiresAuth = throwable is NetworkError.Unauthorized ||
                    (throwable is NetworkError.HttpError && (throwable.code == 401 || throwable.code == 403))
            )
            is ChatOperationException -> ChatOperationFailure(
                userMessage = UserErrorMessage.format(context, messageFor(context, throwable.operation), throwable.code),
                debugCode = throwable.code,
                retryable = throwable.retryable
            )
            is CancellationException -> ChatOperationFailure(
                userMessage = UserErrorMessage.format(context, context.getString(R.string.chat_error_request_cancelled), "E-CHAT-CANCELLED"),
                debugCode = "E-CHAT-CANCELLED",
                retryable = true
            )
            is AppError -> ChatOperationFailure(
                userMessage = UserErrorMessage.format(context, throwable.getUserMessage(context), throwable.debugCode),
                debugCode = throwable.debugCode,
                retryable = true
            )
            else -> ChatOperationFailure(
                userMessage = UserErrorMessage.format(context, messageFor(context, operation), codeFor(operation)),
                debugCode = codeFor(operation),
                retryable = true
            )
        }
    }

    fun warning(context: Context, operation: ChatOperation): String {
        return messageFor(context, operation)
    }

    private fun messageFor(context: Context, operation: ChatOperation): String {
        val resId = when (operation) {
            ChatOperation.SEND_MESSAGE -> R.string.chat_error_send_failed
            ChatOperation.LOAD_CONVERSATION -> R.string.chat_error_conversation_unavailable
            ChatOperation.SYNC_MESSAGES -> R.string.chat_warning_showing_saved_messages
            ChatOperation.FACT_CHECK -> R.string.chat_error_fact_check_failed
            ChatOperation.OCR -> R.string.ocr_error_failed
            ChatOperation.SHARE_IMPORT -> R.string.chat_error_share_import_failed
            ChatOperation.MODE_PREFERENCE -> R.string.chat_warning_mode_preference_not_saved
            ChatOperation.CONTINUITY -> R.string.chat_warning_continuity_not_saved
        }
        return context.getString(resId)
    }

    private fun codeFor(operation: ChatOperation): String {
        return when (operation) {
            ChatOperation.SEND_MESSAGE -> "E-CHAT-SEND"
            ChatOperation.LOAD_CONVERSATION -> "E-CHAT-LOAD"
            ChatOperation.SYNC_MESSAGES -> "E-CHAT-SYNC"
            ChatOperation.FACT_CHECK -> "E-CHAT-FACT"
            ChatOperation.OCR -> "E-CHAT-OCR"
            ChatOperation.SHARE_IMPORT -> "E-CHAT-SHARE"
            ChatOperation.MODE_PREFERENCE -> "E-CHAT-MODE"
            ChatOperation.CONTINUITY -> "E-CHAT-CONTINUITY"
        }
    }
}
