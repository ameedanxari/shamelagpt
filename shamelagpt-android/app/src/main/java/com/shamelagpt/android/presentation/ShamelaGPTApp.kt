package com.shamelagpt.android.presentation

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.shamelagpt.android.presentation.navigation.*
import org.koin.compose.koinInject

/**
 * Main app composable with bottom navigation and navigation host.
 *
 * Features:
 * - Scaffold with bottom navigation bar
 * - Bottom bar visibility controlled based on current route
 * - Type-safe navigation using Kotlin Serialization
 * - Proper backstack management
 *
 * The bottom bar is only shown on main tabs (Chat, History, Settings)
 * and hidden on other screens like Welcome and Language Selection.
 */
@Composable
fun ShamelaGPTApp(
    startDestination: Any? = null
) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    val sessionManager = koinInject<com.shamelagpt.android.core.preferences.SessionManager>()

    // Determine if bottom bar should be shown
    // Show only on main tabs: Chat, History, Settings
    val showBottomBar = currentDestination?.let { destination ->
        destination.hasRoute<ChatRoute>() ||
        destination.hasRoute<HistoryRoute>() ||
        destination.hasRoute<SettingsRoute>()
    } ?: false

    val finalStartDest = startDestination ?: if (sessionManager.isLoggedIn()) ChatRoute() else AuthRoute

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                BottomNavigationBar(navController = navController)
            }
        }
    ) { paddingValues ->
        ShamelaGPTNavGraph(
            navController = navController,
            startDestination = finalStartDest,
            isAuthenticated = { sessionManager.isLoggedIn() },
            modifier = Modifier.padding(paddingValues)
        )
    }
}
