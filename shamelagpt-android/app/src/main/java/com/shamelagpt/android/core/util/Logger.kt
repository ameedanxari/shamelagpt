package com.shamelagpt.android.core.util

import android.util.Log

/**
 * Simple logging utility for the Android app.
 * Provides consistent logging across the application.
 */
object Logger {
    private const val TAG_PREFIX = "ShamelaGPT"

    /**
     * Log debug message
     */
    fun d(tag: String, message: String) {
        Log.d("$TAG_PREFIX:$tag", message)
    }

    /**
     * Log info message
     */
    fun i(tag: String, message: String) {
        Log.i("$TAG_PREFIX:$tag", message)
    }

    /**
     * Log warning message
     */
    fun w(tag: String, message: String) {
        Log.w("$TAG_PREFIX:$tag", message)
    }

    /**
     * Log error message
     */
    fun e(tag: String, message: String, throwable: Throwable? = null) {
        if (throwable != null) {
            Log.e("$TAG_PREFIX:$tag", message, throwable)
        } else {
            Log.e("$TAG_PREFIX:$tag", message)
        }
    }
}
