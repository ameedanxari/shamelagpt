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
                // Check if user has seen welcome screen
                val prefs = getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
                val hasSeenWelcome = remember {
                    mutableStateOf(prefs.getBoolean("has_seen_welcome", false))
                }

                // Hide splash after short delay
                LaunchedEffect(Unit) {
                    delay(500)
                    keepSplashScreen = false
                }

                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    if (hasSeenWelcome.value) {
                        // Returning user - show main app
                        ShamelaGPTApp()
                    } else {
                        // First-time user - show welcome screen
                        WelcomeScreen(
                            onGetStarted = {
                                // Mark welcome as seen
                                prefs.edit()
                                    .putBoolean("has_seen_welcome", true)
                                    .apply()
                                hasSeenWelcome.value = true
                            },
                            onSkipToChat = {
                                // Mark welcome as seen
                                prefs.edit()
                                    .putBoolean("has_seen_welcome", true)
                                    .apply()
                                hasSeenWelcome.value = true
                            }
                        )
                    }
                }
            }
        }
    }
}
