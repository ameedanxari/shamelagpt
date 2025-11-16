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
fun ShamelaGPTApp() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    // Determine if bottom bar should be shown
    // Show only on main tabs: Chat, History, Settings
    val showBottomBar = currentDestination?.let { destination ->
        destination.hasRoute<ChatRoute>() ||
        destination.hasRoute<HistoryRoute>() ||
        destination.hasRoute<SettingsRoute>()
    } ?: false

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                BottomNavigationBar(navController = navController)
            }
        }
    ) { paddingValues ->
        ShamelaGPTNavGraph(
            navController = navController,
            startDestination = ChatRoute(),
            modifier = Modifier.padding(paddingValues)
        )
    }
}
