package com.shamelagpt.android.presentation.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.currentBackStackEntryAsState

/**
 * Bottom navigation bar with three tabs: Chat, History, Settings
 *
 * Features:
 * - Material Design 3 NavigationBar
 * - Current selection indicated
 * - Proper backstack handling (save/restore state)
 * - Single top launch mode
 *
 * @param navController NavHostController for navigation
 * @param modifier Modifier for the NavigationBar
 */
@Composable
fun BottomNavigationBar(
    navController: NavHostController,
    modifier: Modifier = Modifier
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    NavigationBar(modifier = modifier) {
        // Chat Tab
        NavigationBarItem(
            icon = {
                Icon(
                    imageVector = Icons.Default.Chat,
                    contentDescription = "Chat"
                )
            },
            label = { Text("Chat") },
            selected = currentDestination.isRouteInHierarchy<ChatRoute>(),
            onClick = {
                navController.navigate(ChatRoute()) {
                    // Pop up to the start destination of the graph to
                    // avoid building up a large stack of destinations
                    popUpTo(navController.graph.findStartDestination().id) {
                        saveState = true
                    }
                    // Avoid multiple copies of the same destination
                    launchSingleTop = true
                    // Restore state when reselecting a previously selected item
                    restoreState = true
                }
            }
        )

        // History Tab
        NavigationBarItem(
            icon = {
                Icon(
                    imageVector = Icons.Default.History,
                    contentDescription = "History"
                )
            },
            label = { Text("History") },
            selected = currentDestination.isRouteInHierarchy<HistoryRoute>(),
            onClick = {
                navController.navigate(HistoryRoute) {
                    popUpTo(navController.graph.findStartDestination().id) {
                        saveState = true
                    }
                    launchSingleTop = true
                    restoreState = true
                }
            }
        )

        // Settings Tab
        NavigationBarItem(
            icon = {
                Icon(
                    imageVector = Icons.Default.Settings,
                    contentDescription = "Settings"
                )
            },
            label = { Text("Settings") },
            selected = currentDestination.isRouteInHierarchy<SettingsRoute>(),
            onClick = {
                navController.navigate(SettingsRoute) {
                    popUpTo(navController.graph.findStartDestination().id) {
                        saveState = true
                    }
                    launchSingleTop = true
                    restoreState = true
                }
            }
        )
    }
}

/**
 * Helper extension to check if the destination route is in the hierarchy.
 * This is needed for type-safe navigation with Kotlin Serialization.
 */
private inline fun <reified T : Any> NavDestination?.isRouteInHierarchy(): Boolean {
    return this?.hasRoute<T>() == true
}
