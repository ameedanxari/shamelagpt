package com.shamelagpt.android.presentation

import android.os.Bundle
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
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
import com.shamelagpt.android.core.util.ShareLink
import com.shamelagpt.android.core.util.DonationLinkHandler
import com.shamelagpt.android.core.util.FactCheckSharePayloadStore
import com.shamelagpt.android.core.util.EmailIntentHelper
import com.shamelagpt.android.domain.repository.ConversationRepository
import com.shamelagpt.android.presentation.navigation.AuthRoute
import com.shamelagpt.android.presentation.navigation.ChatRoute
import com.shamelagpt.android.presentation.theme.ShamelaGPTTheme
import com.shamelagpt.android.presentation.welcome.WelcomeScreen
import org.koin.android.ext.android.inject
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
    private val conversationRepository: ConversationRepository by inject()
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
        val incomingDestination = mutableStateOf<Any?>(null)
        val incomingReady = mutableStateOf(false)
        lifecycleScope.launch {
            startupViewModel.uiState.first { !it.isBootstrapping }
            incomingDestination.value = resolveIncomingDestination(intent)
            incomingReady.value = true
            keepSplashScreen = false
        }

        setContent {
            ShamelaGPTTheme {
                val startupUiState by startupViewModel.uiState.collectAsState()
                
                val startDestination = incomingDestination
                val showWelcome = remember { mutableStateOf(false) }
                val showFeedbackDialog = remember { mutableStateOf(false) }
                val context = LocalContext.current
                val incomingResolved by incomingReady

                DisposableEffect(Unit) {
                    onShake = { showFeedbackDialog.value = true }
                    onDispose { onShake = null }
                }

                LaunchedEffect(
                    startupUiState.isBootstrapping,
                    startupUiState.isAuthenticated,
                    incomingResolved,
                    startDestination.value
                ) {
                    if (!startupUiState.isBootstrapping && incomingResolved) {
                        showWelcome.value =
                            startDestination.value == null && !startupUiState.isAuthenticated
                    }
                }

                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    if (startupUiState.isBootstrapping || !incomingResolved) {
                        Box(modifier = Modifier.fillMaxSize())
                    } else if (!showWelcome.value) {
                        // Show main app (either auth or chat depending on login state or override)
                        // If startDestination is set (from Welcome), use it.
                        val finalStartDestination = startDestination.value ?: if (startupUiState.isAuthenticated) {
                            ChatRoute()
                        } else {
                            AuthRoute()
                        }
                        ShamelaGPTApp(startDestination = finalStartDestination)
                    } else {
                        // Not logged in - show welcome screen
                        WelcomeScreen(
                            onGetStarted = {
                                // Set explicit start destination to Auth
                                startDestination.value = AuthRoute()
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

    private suspend fun resolveIncomingDestination(intent: Intent?): Any? {
        FactCheckSharePayloadStore.storeFromIntent(this, intent)
        val parsed = StartDestinationIntentParser.parse(intent)
        val data = intent?.data ?: return parsed
        if (!StartDestinationIntentParser.isSharedPath(data)) {
            return parsed
        }

        val conversationId = ShareLink.conversationIdFrom(
            path = data.path.orEmpty(),
            chatIdQuery = data.getQueryParameter("chatid"),
            idQuery = data.getQueryParameter("id")
        ) ?: return ChatRoute()

        return when (val action = SharedConversationRouter.resolve(conversationId, conversationRepository)) {
            is SharedLinkAction.OpenInApp -> ChatRoute(conversationId)
            is SharedLinkAction.OpenInBrowser -> {
                openPublicShare(action.url)
                null
            }
        }
    }

    private fun openPublicShare(url: String) {
        val uri = Uri.parse(url)
        try {
            val viewIntent = Intent(Intent.ACTION_VIEW, uri).apply {
                addCategory(Intent.CATEGORY_BROWSABLE)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    putExtra(
                        Intent.EXTRA_EXCLUDE_COMPONENTS,
                        arrayOf(ComponentName(this@MainActivity, MainActivity::class.java))
                    )
                }
            }
            startActivity(viewIntent)
        } catch (_: Exception) {
            DonationLinkHandler.openUrl(this, url)
        }
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

    // Handle new intents from deep links or intent forwarding
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        lifecycleScope.launch {
            val destination = resolveIncomingDestination(intent)
            if (destination != null) {
                setIntent(intent)
                recreate()
            }
        }
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
