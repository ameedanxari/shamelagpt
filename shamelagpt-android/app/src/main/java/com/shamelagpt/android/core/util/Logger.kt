package com.shamelagpt.android.core.util

import android.util.Log
import com.shamelagpt.android.BuildConfig

/**
 * Centralized logging utility with:
 * - Build-aware verbosity
 * - Consistent tag formatting
 * - Basic PII-safe helpers
 */
object Logger {
    enum class Level(val priority: Int) {
        DEBUG(3),
        INFO(4),
        WARN(5),
        ERROR(6)
    }

    private const val TAG_PREFIX = "ShamelaGPT"
    private val minimumLevel: Level = if (BuildConfig.DEBUG) Level.DEBUG else Level.INFO

    fun shouldLog(level: Level): Boolean = level.priority >= minimumLevel.priority

    fun d(tag: String, message: String) {
        if (!shouldLog(Level.DEBUG)) return
        Log.d("$TAG_PREFIX:$tag", message)
    }

    fun i(tag: String, message: String) {
        if (!shouldLog(Level.INFO)) return
        Log.i("$TAG_PREFIX:$tag", message)
    }

    fun w(tag: String, message: String) {
        if (!shouldLog(Level.WARN)) return
        Log.w("$TAG_PREFIX:$tag", message)
    }

    fun e(tag: String, message: String, throwable: Throwable? = null) {
        if (!shouldLog(Level.ERROR)) return
        if (throwable != null) {
            Log.e("$TAG_PREFIX:$tag", message, throwable)
        } else {
            Log.e("$TAG_PREFIX:$tag", message)
        }
    }

    /**
     * Returns short redacted identifier for log correlation.
     */
    fun redactedId(value: String?): String {
        if (value.isNullOrBlank()) return "null"
        val trimmed = value.trim()
        return when {
            trimmed.length <= 4 -> "***"
            else -> "***${trimmed.takeLast(4)}"
        }
    }

    /**
     * Returns redacted email for safe diagnostic logs.
     */
    fun redactedEmail(email: String?): String {
        if (email.isNullOrBlank()) return "null"
        val trimmed = email.trim()
        val atIndex = trimmed.indexOf('@')
        if (atIndex <= 0 || atIndex == trimmed.lastIndex) return "***"
        return "${trimmed.first()}***${trimmed.substring(atIndex)}"
    }
}
