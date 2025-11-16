package com.shamelagpt.android.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.toRoute
import com.shamelagpt.android.presentation.chat.ChatScreen
import com.shamelagpt.android.presentation.history.HistoryScreen
import com.shamelagpt.android.presentation.settings.LanguageSelectionScreen
import com.shamelagpt.android.presentation.settings.SettingsScreen
import com.shamelagpt.android.presentation.welcome.WelcomeScreen

/**
 * Main navigation graph for ShamelaGPT app.
 * Uses type-safe navigation with Kotlin Serialization.
 *
 * @param navController NavHostController for managing navigation
 * @param startDestination Starting destination (route object)
 * @param modifier Modifier for the NavHost
 */
@Composable
fun ShamelaGPTNavGraph(
    navController: NavHostController,
    startDestination: Any,
    modifier: Modifier = Modifier
) {
    NavHost(
        navController = navController,
        startDestination = startDestination,
        modifier = modifier
    ) {
        // Welcome Screen - First launch only
        composable<WelcomeRoute> {
            WelcomeScreen(
                onGetStarted = {
                    // Navigate to chat and clear backstack
                    navController.navigate(ChatRoute()) {
                        popUpTo<WelcomeRoute> { inclusive = true }
                    }
                },
                onSkipToChat = {
                    // Navigate to chat and clear backstack
                    navController.navigate(ChatRoute()) {
                        popUpTo<WelcomeRoute> { inclusive = true }
                    }
                }
            )
        }

        // Chat Screen - Main conversation interface
        composable<ChatRoute> { backStackEntry ->
            val route = backStackEntry.toRoute<ChatRoute>()
            ChatScreen(
                conversationId = route.conversationId,
                onMenuClick = {
                    // Optional: Implement menu/drawer functionality
                }
            )
        }

        // History Screen - Past conversations
        composable<HistoryRoute> {
            HistoryScreen(
                onNavigateToChat = { conversationId ->
                    navController.navigate(ChatRoute(conversationId = conversationId))
                }
            )
        }

        // Settings Screen - App configuration
        composable<SettingsRoute> {
            SettingsScreen(
                onNavigateToLanguage = {
                    navController.navigate(LanguageSelectionRoute)
                }
            )
        }

        // Language Selection Screen
        composable<LanguageSelectionRoute> {
            LanguageSelectionScreen(
                onNavigateBack = {
                    navController.navigateUp()
                }
            )
        }
    }
}
