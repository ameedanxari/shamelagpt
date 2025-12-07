package com.shamelagpt.android.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.toRoute
import com.shamelagpt.android.presentation.auth.AuthScreen
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
    isAuthenticated: () -> Boolean,
    modifier: Modifier = Modifier
) {
    NavHost(
        navController = navController,
        startDestination = startDestination,
        modifier = modifier
    ) {
        // Auth Screen
        composable<AuthRoute> {
            AuthScreen(
                onAuthenticated = {
                    navController.navigate(ChatRoute()) {
                        popUpTo<AuthRoute> { inclusive = true }
                    }
                },
                onContinueAsGuest = {
                    navController.navigate(ChatRoute()) {
                        popUpTo<AuthRoute> { inclusive = true }
                    }
                }
            )
        }

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
                },
                onRequireAuth = {
                    navController.navigate(AuthRoute) {
                        popUpTo<ChatRoute> { inclusive = true }
                    }
                }
            )
        }

        // History Screen - Past conversations
        composable<HistoryRoute> {
            HistoryScreen(
                isAuthenticated = isAuthenticated(),
                onNavigateToChat = { conversationId ->
                    navController.navigate(ChatRoute(conversationId = conversationId))
                },
                onNavigateToAuth = {
                    navController.navigate(AuthRoute) {
                        popUpTo<ChatRoute> { inclusive = true }
                    }
                }
            )
        }

        // Settings Screen - App configuration
        composable<SettingsRoute> {
            SettingsScreen(
                isAuthenticated = isAuthenticated(),
                onNavigateToLanguage = {
                    navController.navigate(LanguageSelectionRoute)
                },
                onNavigateToAuth = {
                    navController.navigate(AuthRoute) {
                        popUpTo<ChatRoute> { inclusive = true }
                    }
                },
                onLogout = {
                    navController.navigate(AuthRoute) {
                        popUpTo<ChatRoute> { inclusive = true }
                    }
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
