package com.shamelagpt.android.presentation

import android.os.Bundle
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.content.Context
import androidx.appcompat.app.AppCompatActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.lifecycleScope
import com.shamelagpt.android.R
import com.shamelagpt.android.core.util.FactCheckSharePayloadStore
import com.shamelagpt.android.presentation.navigation.AuthRoute
import com.shamelagpt.android.presentation.navigation.ChatRoute
import com.shamelagpt.android.presentation.theme.ShamelaGPTTheme
import com.shamelagpt.android.presentation.welcome.WelcomeScreen
import com.shamelagpt.android.core.util.EmailIntentHelper
import org.koin.androidx.viewmodel.ext.android.viewModel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

/**
 * Main activity for ShamelaGPT Android app.
 *
 * Features:
 * - Splash screen using Android 12+ Splash Screen API
 * - First-launch detection (shows Welcome screen)
 * - Language preference loading
 * - Navigation setup
 */
class MainActivity : AppCompatActivity(), SensorEventListener {
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var lastShakeTime = 0L
    private var onShake: (() -> Unit)? = null
    private val startupViewModel: com.shamelagpt.android.presentation.startup.AppStartupViewModel by viewModel()
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install splash screen before super.onCreate()
        val splashScreen = installSplashScreen()

        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        var keepSplashScreen = true
        splashScreen.setKeepOnScreenCondition { keepSplashScreen }

        startupViewModel.bootstrap()
        lifecycleScope.launch {
            startupViewModel.uiState.first { !it.isBootstrapping }
            keepSplashScreen = false
        }

        // Parse intent for possible deep link or shared payload and provide as initial start destination
        val initialStartDestination: Any? = parseIntentForStartDestination(intent)

        setContent {
            ShamelaGPTTheme {
                val startupUiState by startupViewModel.uiState.collectAsState()
                
                // Track start destination if coming from Welcome screen
                val startDestination = remember { mutableStateOf<Any?>(initialStartDestination) }
                
                // State to control welcome screen visibility
                val showWelcome = remember { mutableStateOf(false) }
                val showFeedbackDialog = remember { mutableStateOf(false) }
                val context = LocalContext.current

                DisposableEffect(Unit) {
                    onShake = { showFeedbackDialog.value = true }
                    onDispose { onShake = null }
                }

                LaunchedEffect(startupUiState.isBootstrapping, startupUiState.isAuthenticated) {
                    if (!startupUiState.isBootstrapping) {
                        showWelcome.value = !startupUiState.isAuthenticated
                    }
                }

                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    if (startupUiState.isBootstrapping) {
                        // Hidden behind native splash while bootstrapping.
                        Box(modifier = Modifier.fillMaxSize())
                    } else if (!showWelcome.value) {
                        // Show main app (either auth or chat depending on login state or override)
                        // If startDestination is set (from Welcome), use it.
                        val finalStartDestination = startDestination.value ?: if (startupUiState.isAuthenticated) {
                            ChatRoute()
                        } else {
                            AuthRoute
                        }
                        ShamelaGPTApp(startDestination = finalStartDestination)
                    } else {
                        // Not logged in - show welcome screen
                        WelcomeScreen(
                            onGetStarted = {
                                // Set explicit start destination to Auth
                                startDestination.value = AuthRoute
                                showWelcome.value = false
                            },
                            onSkipToChat = {
                                // Set explicit start destination to Chat (Guest mode implied by direct nav)
                                startDestination.value = ChatRoute()
                                showWelcome.value = false
                            }
                        )
                    }
                }

                if (showFeedbackDialog.value) {
                    AlertDialog(
                        onDismissRequest = { showFeedbackDialog.value = false },
                        title = { Text(text = context.getString(R.string.feedback_prompt_title)) },
                        text = { Text(text = context.getString(R.string.feedback_prompt_message)) },
                        confirmButton = {
                            TextButton(onClick = {
                                showFeedbackDialog.value = false
                                EmailIntentHelper.openFeedbackEmail(context)
                            }) {
                                Text(text = context.getString(R.string.send_feedback))
                            }
                        },
                        dismissButton = {
                            TextButton(onClick = { showFeedbackDialog.value = false }) {
                                Text(text = context.getString(R.string.common_cancel))
                            }
                        }
                    )
                }
            }
        }
    }

    private fun parseIntentForStartDestination(intent: Intent?): Any? {
        FactCheckSharePayloadStore.storeFromIntent(intent)
        return StartDestinationIntentParser.parse(intent)
    }

    override fun onResume() {
        super.onResume()
        accelerometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
    }

    override fun onPause() {
        sensorManager.unregisterListener(this)
        super.onPause()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        // Replace current intent and recreate to allow Compose to pick up new startDestination
        intent?.let { setIntent(it); recreate() }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type != Sensor.TYPE_ACCELEROMETER) return
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]

        val gForce = Math.sqrt((x * x + y * y + z * z).toDouble()) / SensorManager.GRAVITY_EARTH
        val now = System.currentTimeMillis()
        if (gForce > 2.7 && now - lastShakeTime > 1200) {
            lastShakeTime = now
            onShake?.invoke()
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // No-op
    }
}
