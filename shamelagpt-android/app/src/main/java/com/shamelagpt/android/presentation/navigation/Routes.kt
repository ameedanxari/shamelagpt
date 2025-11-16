package com.shamelagpt.android.presentation.navigation

import androidx.annotation.Keep
import kotlinx.serialization.Serializable

/**
 * Type-safe navigation routes using Kotlin Serialization
 */

@Keep
@Serializable
object WelcomeRoute

@Keep
@Serializable
object AuthRoute

@Keep
@Serializable
data class ChatRoute(val conversationId: String? = null)

@Keep
@Serializable
object HistoryRoute

@Keep
@Serializable
object SettingsRoute

@Keep
@Serializable
object LanguageSelectionRoute

@Keep
@Serializable
object AboutRoute
