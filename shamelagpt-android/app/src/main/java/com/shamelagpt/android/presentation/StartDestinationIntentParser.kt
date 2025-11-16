package com.shamelagpt.android.presentation

import android.content.Intent
import android.net.Uri
import com.shamelagpt.android.presentation.navigation.ChatRoute
import com.shamelagpt.android.presentation.navigation.HistoryRoute
import com.shamelagpt.android.presentation.navigation.SettingsRoute

/**
 * Maps incoming intents (share + deep links) to a start destination route.
 */
object StartDestinationIntentParser {

    private const val EXTRA_SHARED_TEXT = "shamela_shared_text"
    private const val EXTRA_SHARED_URIS = "shamela_shared_uris"

    fun parse(intent: Intent?): Any? {
        if (intent == null) return null

        if (intent.hasExtra(EXTRA_SHARED_TEXT) || intent.hasExtra(EXTRA_SHARED_URIS)) {
            return ChatRoute()
        }

        val data = intent.data ?: return null
        return parseDeepLink(data)
    }

    private fun parseDeepLink(data: Uri): Any? {
        val scheme = data.scheme?.lowercase()
        val host = data.host?.lowercase()
        val path = data.path?.lowercase().orEmpty()

        if ((scheme == "https" || scheme == "http") &&
            (host == "shamelagpt.com" || host == "www.shamelagpt.com")
        ) {
            return routeFromPath(path, data)
        }

        if (scheme == "shamelagpt") {
            return routeFromHostOrPath(host, path, data)
        }

        return null
    }

    private fun routeFromHostOrPath(host: String?, path: String, data: Uri): Any? {
        return when (host) {
            "chat" -> chatRouteFromUri(data)
            "history" -> HistoryRoute
            "settings" -> SettingsRoute
            else -> routeFromPath(path, data)
        }
    }

    private fun routeFromPath(path: String, data: Uri): Any? {
        return when {
            path.startsWith("/chat") -> chatRouteFromUri(data)
            path.startsWith("/history") -> HistoryRoute
            path.startsWith("/settings") -> SettingsRoute
            else -> null
        }
    }

    private fun chatRouteFromUri(data: Uri): ChatRoute {
        val conversationId = data.getQueryParameter("id")?.takeIf { it.isNotBlank() }
        return ChatRoute(conversationId)
    }
}
