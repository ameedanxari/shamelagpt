package com.shamelagpt.android.core.util

import java.net.URI
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

/**
 * Public share URL: `https://shamelagpt.com/shared?chatid=<id>`.
 * Older backends return `/shared/<id>`; normalize that so the web SPA can open it.
 */
object ShareLink {

    private const val PRODUCTION_ORIGIN = "https://shamelagpt.com"

    fun targetId(conversationId: String, threadId: String?): String {
        return threadId?.trim()?.takeIf { it.isNotEmpty() } ?: conversationId
    }

    fun conversationIdFrom(
        path: String,
        chatIdQuery: String?,
        idQuery: String?
    ): String? {
        chatIdQuery?.trim()?.takeIf { it.isNotEmpty() }?.let { return it }
        idQuery?.trim()?.takeIf { it.isNotEmpty() }?.let { return it }
        val segments = path.split("/").filter { it.isNotEmpty() }
        if (segments.size >= 2 && segments.first().equals("shared", ignoreCase = true)) {
            return segments[1].takeIf { it.isNotBlank() }
        }
        return null
    }

    fun normalize(raw: String?, conversationId: String): String {
        val canonical = canonical(conversationId)
        val trimmed = raw?.trim().orEmpty()
        if (trimmed.isEmpty()) {
            return canonical
        }

        val uri = try {
            URI(trimmed)
        } catch (_: Exception) {
            return canonical
        }

        val scheme = uri.scheme
        val host = uri.host
        if (scheme.isNullOrBlank() || host.isNullOrBlank()) {
            return canonical
        }

        val hasChatId = uri.rawQuery
            ?.split("&")
            ?.any { part ->
                val name = part.substringBefore("=")
                val value = part.substringAfter("=", missingDelimiterValue = "")
                name == "chatid" && value.isNotEmpty()
            } == true
        if (hasChatId) {
            return trimmed
        }

        val segments = uri.path.orEmpty().split("/").filter { it.isNotEmpty() }
        if (segments.firstOrNull()?.equals("shared", ignoreCase = true) != true) {
            return canonical
        }

        var origin = "$scheme://$host"
        if (uri.port != -1) {
            origin += ":${uri.port}"
        }
        return canonical(conversationId, origin)
    }

    private fun canonical(conversationId: String, origin: String = PRODUCTION_ORIGIN): String {
        val escaped = URLEncoder.encode(conversationId, StandardCharsets.UTF_8.name())
            .replace("+", "%20")
        return "$origin/shared?chatid=$escaped"
    }
}
