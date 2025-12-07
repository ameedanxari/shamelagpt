package com.shamelagpt.android.presentation

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.shamelagpt.android.presentation.navigation.WelcomeRoute
import com.shamelagpt.android.presentation.theme.ShamelaGPTTheme
import com.shamelagpt.android.presentation.welcome.WelcomeScreen
import kotlinx.coroutines.delay

/**
 * Main activity for ShamelaGPT Android app.
 *
 * Features:
 * - Splash screen using Android 12+ Splash Screen API
 * - First-launch detection (shows Welcome screen)
 * - Language preference loading
 * - Navigation setup
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install splash screen before super.onCreate()
        val splashScreen = installSplashScreen()

        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Keep splash screen visible while checking first launch
        var keepSplashScreen = true
        splashScreen.setKeepOnScreenCondition { keepSplashScreen }

        setContent {
            ShamelaGPTTheme {
                // Determine if user is logged in
                val sessionManager: com.shamelagpt.android.core.preferences.SessionManager by org.koin.android.ext.android.inject()
                val isLoggedIn = sessionManager.isLoggedIn()
                
                // Track start destination if coming from Welcome screen
                val startDestination = remember { mutableStateOf<Any?>(null) }
                
                // State to control welcome screen visibility
                // Show welcome if NOT logged in and no manual start destination set yet
                val showWelcome = remember { mutableStateOf(!isLoggedIn) }

                // Hide splash after short delay
                LaunchedEffect(Unit) {
                    delay(500)
                    keepSplashScreen = false
                }

                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    if (!showWelcome.value) {
                        // Show main app (either auth or chat depending on login state or override)
                        // If startDestination is set (from Welcome), use it.
                        ShamelaGPTApp(startDestination = startDestination.value)
                    } else {
                        // Not logged in - show welcome screen
                        WelcomeScreen(
                            onGetStarted = {
                                // Set explicit start destination to Auth
                                startDestination.value = com.shamelagpt.android.presentation.navigation.AuthRoute
                                showWelcome.value = false
                            },
                            onSkipToChat = {
                                // Set explicit start destination to Chat (Guest mode implied by direct nav)
                                startDestination.value = com.shamelagpt.android.presentation.navigation.ChatRoute()
                                showWelcome.value = false
                            }
                        )
                    }
                }
            }
        }
    }
}
