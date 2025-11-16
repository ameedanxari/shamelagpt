package com.shamelagpt.android.core.util

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

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
fun formatRelativeTimestamp(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diff = now - timestamp

    return when {
        diff < 60_000 -> "Just now"
        diff < 3600_000 -> "${diff / 60_000}m ago"
        diff < 86400_000 -> "${diff / 3600_000}h ago"
        diff < 604800_000 -> "${diff / 86400_000}d ago"
        else -> SimpleDateFormat("MMM dd", Locale.getDefault()).format(Date(timestamp))
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
