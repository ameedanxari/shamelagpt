package com.shamelagpt.android.core.util

import java.net.URI
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

/**
 * Builds the canonical public share link for a conversation.
 *
 * The app and backend deploy independently. An older backend still returns the
 * legacy path-segment form `https://shamelagpt.com/shared/<id>`, which the web
 * SPA does not route. Normalizing client-side makes the shared link work
 * regardless of which side ships first.
 */
object ShareLink {

    const val PRODUCTION_ORIGIN = "https://shamelagpt.com"

    fun canonical(conversationId: String, origin: String = PRODUCTION_ORIGIN): String {
        val escaped = URLEncoder.encode(conversationId, StandardCharsets.UTF_8.name())
            .replace("+", "%20")
        return "$origin/shared?chatid=$escaped"
    }

    /**
     * Normalizes a server-supplied share URL into the working query form.
     *
     * @param raw The `share_url` returned by the backend, if any.
     * @param conversationId The conversation the link should point at.
     * @return A link of the shape `<origin>/shared?chatid=<id>`.
     */
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
}
