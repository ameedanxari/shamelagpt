package com.shamelagpt.android.core.util

import java.text.SimpleDateFormat
import java.text.DecimalFormatSymbols
import java.util.Date
import java.util.Locale
import android.text.format.DateUtils

/**
 * Formats a timestamp into a relative time string.
 *
 * Examples:
 * - "Just now" (< 1 minute)
 * - "5m ago" (< 1 hour)
 * - "2h ago" (< 1 day)
 * - "3d ago" (< 1 week)
 * - "Jan 15" (>= 1 week)
 *
 * @param timestamp The timestamp in milliseconds
 * @return Formatted relative time string
 */
fun formatRelativeTimestamp(timestamp: Long, locale: Locale = Locale.getDefault()): String {
    val now = System.currentTimeMillis()
    val relative = DateUtils.getRelativeTimeSpanString(
        timestamp,
        now,
        DateUtils.MINUTE_IN_MILLIS,
        DateUtils.FORMAT_ABBREV_RELATIVE
    ).toString()

    if (now - timestamp < DateUtils.WEEK_IN_MILLIS) {
        return localizeDigits(relative, locale)
    }

    return localizeDigits(
        SimpleDateFormat("MMM dd", locale).format(Date(timestamp)),
        locale
    )
}

fun localizeDigits(input: String, locale: Locale = Locale.getDefault()): String {
    val zeroDigit = DecimalFormatSymbols.getInstance(locale).zeroDigit
    if (zeroDigit == '0') {
        return input
    }

    val offset = zeroDigit.code - '0'.code
    return buildString(input.length) {
        input.forEach { char ->
            if (char in '0'..'9') {
                append((char.code + offset).toChar())
            } else {
                append(char)
            }
        }
    }
}

/**
 * Generates a conversation title from the first user message.
 *
 * Truncates the message to a maximum length with ellipsis if needed.
 *
 * @param firstMessage The first message in the conversation
 * @param maxLength Maximum length of the title (default 50)
 * @return Generated conversation title
 */
fun generateConversationTitle(firstMessage: String, maxLength: Int = 50): String {
    return if (firstMessage.length > maxLength) {
        firstMessage.take(maxLength).trim() + "..."
    } else {
        firstMessage.trim()
    }
}
