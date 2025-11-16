package com.shamelagpt.android.core.util

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.RecognitionService
import android.speech.SpeechRecognizer
import androidx.core.content.ContextCompat
import android.Manifest
import android.content.pm.PackageManager
import java.util.Locale

private const val TAG = "VoiceInputManager"
private const val VOICE_UNAVAILABLE_MESSAGE = "Voice input is not available on this device."

enum class VoiceInputCapability {
    DIRECT,
    INTENT_FALLBACK,
    UNAVAILABLE
}

/**
 * Manager class for handling voice input using Android SpeechRecognizer API.
 *
 * @property context Application context
 */
class VoiceInputManager(private val context: Context) {

    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var lastRmsLogAtMs: Long = 0L

    /**
     * Starts listening for voice input.
     *
     * @param locale Locale for speech recognition (defaults to system locale)
     * @param onResult Callback invoked with the recognized text
     * @param onPartialResult Callback invoked with partial recognition results
     * @param onError Callback invoked when an error occurs
     */
    fun startListening(
        locale: Locale = Locale.getDefault(),
        onResult: (String) -> Unit,
        onPartialResult: (String) -> Unit = {},
        onError: (String) -> Unit
    ) {
        val requestedLanguageTag = locale.toLanguageTag()
        Logger.i(
            TAG,
            "voice startListening requested locale=$requestedLanguageTag diagnostics=${buildRuntimeDiagnostics(locale)}"
        )
        if (isListening) {
            Logger.w(TAG, "voice startListening ignored: already listening")
            return
        }

        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            Logger.w(
                TAG,
                "speech recognition unavailable on device; diagnostics=${buildRuntimeDiagnostics(locale)}"
            )
            onError(VOICE_UNAVAILABLE_MESSAGE)
            return
        }

        try {
            Logger.d(TAG, "creating speech recognizer")
            // Create speech recognizer
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)

            // Set up recognition listener
            speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    isListening = true
                    Logger.d(TAG, "voice recognizer ready bundleKeys=${params?.keySet()?.joinToString(",") ?: "none"}")
                }

                override fun onBeginningOfSpeech() {
                    Logger.d(TAG, "voice beginning of speech")
                }

                override fun onRmsChanged(rmsdB: Float) {
                    val now = System.currentTimeMillis()
                    if (now - lastRmsLogAtMs >= 1200L) {
                        lastRmsLogAtMs = now
                        Logger.d(TAG, "voice rms changed rmsdB=$rmsdB")
                    }
                }

                override fun onBufferReceived(buffer: ByteArray?) {
                    if (buffer != null && buffer.isNotEmpty()) {
                        Logger.d(TAG, "voice buffer received bytes=${buffer.size}")
                    }
                }

                override fun onEndOfSpeech() {
                    isListening = false
                    Logger.d(TAG, "voice end of speech detected")
                }

                override fun onError(error: Int) {
                    isListening = false
                    val errorCodeName = getErrorCodeName(error)
                    val errorMessage = when (error) {
                        SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                        SpeechRecognizer.ERROR_CLIENT -> "Client side error"
                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                        SpeechRecognizer.ERROR_NETWORK -> "Network error"
                        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                        SpeechRecognizer.ERROR_NO_MATCH -> "No speech match found"
                        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
                        SpeechRecognizer.ERROR_SERVER -> "Server error"
                        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
                        else -> "Unknown error occurred"
                    }
                    Logger.w(
                        TAG,
                        "voice recognition errorCode=$error($errorCodeName) message=$errorMessage diagnostics=${buildRuntimeDiagnostics(locale)}"
                    )
                    onError(errorMessage)
                }

                override fun onResults(results: Bundle?) {
                    isListening = false
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val confidenceScores = results?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)
                    Logger.i(
                        TAG,
                        "voice final results matches=${matches?.size ?: 0} topLen=${matches?.firstOrNull()?.length ?: 0} confidenceTop=${confidenceScores?.firstOrNull() ?: -1f}"
                    )
                    if (!matches.isNullOrEmpty()) {
                        Logger.i(TAG, "voice recognition produced final result")
                        onResult(matches[0])
                    } else {
                        Logger.w(TAG, "voice recognition completed with empty result")
                        onError("No results found")
                    }
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    if (!matches.isNullOrEmpty()) {
                        Logger.d(
                            TAG,
                            "voice recognition partial result available matches=${matches.size} topLen=${matches[0].length}"
                        )
                        onPartialResult(matches[0])
                    }
                }

                override fun onEvent(eventType: Int, params: Bundle?) {
                    Logger.d(
                        TAG,
                        "voice recognizer event eventType=$eventType bundleKeys=${params?.keySet()?.joinToString(",") ?: "none"}"
                    )
                }
            })

            // Create recognition intent
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale.toString())
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            }
            Logger.d(
                TAG,
                "voice start intent extras languageModel=${intent.getStringExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL)} language=${intent.getStringExtra(RecognizerIntent.EXTRA_LANGUAGE)} partial=${intent.getBooleanExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)} maxResults=${intent.getIntExtra(RecognizerIntent.EXTRA_MAX_RESULTS, -1)}"
            )

            // Start listening
            speechRecognizer?.startListening(intent)
            Logger.i(TAG, "voice recognizer listening started")

        } catch (e: Exception) {
            isListening = false
            Logger.e(TAG, "failed to start voice recognition", e)
            onError("Failed to start voice recognition: ${e.message}")
        }
    }

    /**
     * Stops listening for voice input.
     */
    fun stopListening() {
        try {
            speechRecognizer?.stopListening()
            isListening = false
            Logger.i(TAG, "voice listening stopped recognizerExists=${speechRecognizer != null}")
        } catch (e: Exception) {
            Logger.w(TAG, "voice stopListening failed: ${e::class.simpleName}")
        }
    }

    /**
     * Releases resources used by the speech recognizer.
     * Should be called when the manager is no longer needed.
     */
    fun destroy() {
        try {
            speechRecognizer?.destroy()
            speechRecognizer = null
            isListening = false
            Logger.d(TAG, "voice recognizer destroyed")
        } catch (e: Exception) {
            Logger.w(TAG, "voice destroy failed: ${e::class.simpleName}")
        }
    }

    fun getCapability(): VoiceInputCapability {
        val directAvailable = SpeechRecognizer.isRecognitionAvailable(context)
        val serviceCount = queryRecognitionServicePackages().size
        val intentHandlerCount = queryRecognitionIntentHandlers().size
        if (directAvailable) {
            Logger.d(
                TAG,
                "voice capability resolved: DIRECT recognitionAvailable=$directAvailable recognitionServices=$serviceCount intentHandlers=$intentHandlerCount"
            )
            return VoiceInputCapability.DIRECT
        }

        val intent = buildRecognitionIntent()
        val handlers = context.packageManager.queryIntentActivities(intent, 0)
        val capability = if (handlers.isNotEmpty()) {
            VoiceInputCapability.INTENT_FALLBACK
        } else {
            VoiceInputCapability.UNAVAILABLE
        }
        Logger.i(
            TAG,
            "voice capability resolved: $capability recognitionAvailable=$directAvailable recognitionServices=$serviceCount intentHandlers=$intentHandlerCount handlers=${handlers.joinToString(",") { it.activityInfo.packageName }}"
        )
        return capability
    }

    fun getUnavailableMessage(): String = VOICE_UNAVAILABLE_MESSAGE

    fun createFallbackIntent(locale: Locale = Locale.getDefault()): Intent {
        val intent = buildRecognitionIntent(locale)
        Logger.d(
            TAG,
            "voice fallback intent created locale=${locale.toLanguageTag()} language=${intent.getStringExtra(RecognizerIntent.EXTRA_LANGUAGE)}"
        )
        return intent
    }

    fun createSetupIntent(): Intent? {
        val candidates = listOf(
            Intent(Settings.ACTION_VOICE_INPUT_SETTINGS),
            Intent(Settings.ACTION_INPUT_METHOD_SETTINGS),
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
            }
        )

        val intent = candidates.firstOrNull(::canResolveIntent)
        Logger.i(
            TAG,
            "voice setup intent available=${intent != null} chosenAction=${intent?.action ?: "none"}"
        )
        return intent
    }

    fun extractBestResult(data: Intent?): String? {
        val matches = data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
        val best = matches?.firstOrNull()?.trim()?.takeIf { it.isNotBlank() }
        Logger.d(
            TAG,
            "voice fallback result parsed matches=${matches?.size ?: 0} topLen=${best?.length ?: 0}"
        )
        return best
    }

    /**
     * Returns whether the manager is currently listening.
     */
    fun isListening(): Boolean = isListening

    private fun buildRecognitionIntent(locale: Locale = Locale.getDefault()): Intent {
        return Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale.toLanguageTag())
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        }
    }

    private fun buildRuntimeDiagnostics(locale: Locale): String {
        val recognitionAvailable = SpeechRecognizer.isRecognitionAvailable(context)
        val micPermissionState = if (
            ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        ) {
            "granted"
        } else {
            "denied"
        }
        val servicePackages = queryRecognitionServicePackages()
        val intentHandlers = queryRecognitionIntentHandlers()
        return "sdk=${Build.VERSION.SDK_INT}" +
            ",brand=${Build.BRAND}" +
            ",manufacturer=${Build.MANUFACTURER}" +
            ",model=${Build.MODEL}" +
            ",defaultLocale=${Locale.getDefault().toLanguageTag()}" +
            ",requestedLocale=${locale.toLanguageTag()}" +
            ",micPermission=$micPermissionState" +
            ",recognitionAvailable=$recognitionAvailable" +
            ",recognitionServices=${servicePackages.size}" +
            ",recognitionServicePackages=${servicePackages.joinToString("|")}" +
            ",intentHandlers=${intentHandlers.size}" +
            ",intentHandlerPackages=${intentHandlers.joinToString("|")}"
    }

    private fun queryRecognitionServicePackages(): List<String> {
        val serviceIntent = Intent(RecognitionService.SERVICE_INTERFACE)
        return context.packageManager
            .queryIntentServices(serviceIntent, 0)
            .mapNotNull { it.serviceInfo?.packageName }
            .distinct()
    }

    private fun queryRecognitionIntentHandlers(): List<String> {
        return context.packageManager
            .queryIntentActivities(buildRecognitionIntent(), 0)
            .mapNotNull { it.activityInfo?.packageName }
            .distinct()
    }

    private fun getErrorCodeName(error: Int): String {
        return when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "ERROR_AUDIO"
            SpeechRecognizer.ERROR_CLIENT -> "ERROR_CLIENT"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "ERROR_INSUFFICIENT_PERMISSIONS"
            SpeechRecognizer.ERROR_NETWORK -> "ERROR_NETWORK"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "ERROR_NETWORK_TIMEOUT"
            SpeechRecognizer.ERROR_NO_MATCH -> "ERROR_NO_MATCH"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "ERROR_RECOGNIZER_BUSY"
            SpeechRecognizer.ERROR_SERVER -> "ERROR_SERVER"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "ERROR_SPEECH_TIMEOUT"
            12 -> "ERROR_LANGUAGE_NOT_SUPPORTED"
            13 -> "ERROR_LANGUAGE_UNAVAILABLE"
            else -> "ERROR_UNKNOWN"
        }
    }

    private fun canResolveIntent(intent: Intent): Boolean {
        return intent.resolveActivity(context.packageManager) != null
    }
}
