package com.shamelagpt.android.presentation.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.stringResource
import androidx.navigation.NavDestination
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavHostController
import androidx.navigation.compose.currentBackStackEntryAsState
import com.shamelagpt.android.R

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

    val navBarColors = NavigationBarItemDefaults.colors(
        selectedIconColor = MaterialTheme.colorScheme.primary,
        selectedTextColor = MaterialTheme.colorScheme.primary,
        indicatorColor = MaterialTheme.colorScheme.primaryContainer,
        unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
        unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant
    )

    // Keep tab ordering semantic (Chat, History, Settings) regardless of RTL/LTR.
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        NavigationBar(modifier = modifier) {
        // Chat Tab
        NavigationBarItem(
            icon = {
                Icon(
                    imageVector = Icons.Default.Chat,
                    contentDescription = stringResource(R.string.chat)
                )
            },
            label = { Text(stringResource(R.string.chat)) },
            selected = currentDestination.isRouteInHierarchy<ChatRoute>(),
            colors = navBarColors,
            onClick = {
                navController.navigate(ChatRoute()) {
                    // Pop up to the start destination of the graph to
                    // avoid building up a large stack of destinations
                    popUpTo<ChatRoute> {
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
                    contentDescription = stringResource(R.string.history)
                )
            },
            label = { Text(stringResource(R.string.history)) },
            selected = currentDestination.isRouteInHierarchy<HistoryRoute>(),
            colors = navBarColors,
            onClick = {
                navController.navigate(HistoryRoute) {
                    popUpTo<ChatRoute> {
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
                    contentDescription = stringResource(R.string.settings)
                )
            },
            label = { Text(stringResource(R.string.settings)) },
            selected = currentDestination.isRouteInHierarchy<SettingsRoute>(),
            colors = navBarColors,
            onClick = {
                navController.navigate(SettingsRoute) {
                    popUpTo<ChatRoute> {
                        saveState = true
                    }
                    launchSingleTop = true
                    restoreState = true
                }
            }
        )
        }
    }
}

/**
 * Helper extension to check if the destination route is in the hierarchy.
 * This is needed for type-safe navigation with Kotlin Serialization.
 */
private inline fun <reified T : Any> NavDestination?.isRouteInHierarchy(): Boolean {
    return this?.hasRoute<T>() == true
}
