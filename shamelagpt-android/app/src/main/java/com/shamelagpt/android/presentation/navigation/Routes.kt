package com.shamelagpt.android.presentation.navigation

import kotlinx.serialization.Serializable

/**
 * Type-safe navigation routes using Kotlin Serialization
 */

@Serializable
object WelcomeRoute

@Serializable
object AuthRoute

@Serializable
data class ChatRoute(val conversationId: String? = null)

@Serializable
object HistoryRoute

@Serializable
object SettingsRoute

@Serializable
object LanguageSelectionRoute

@Serializable
object AboutRoute
