package com.shamelagpt.android.core.util

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import java.util.Locale

/**
 * Manager class for handling voice input using Android SpeechRecognizer API.
 *
 * @property context Application context
 */
class VoiceInputManager(private val context: Context) {

    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false

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
        if (isListening) {
            return
        }

        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            onError("Speech recognition not available on this device")
            return
        }

        try {
            // Create speech recognizer
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)

            // Set up recognition listener
            speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    isListening = true
                }

                override fun onBeginningOfSpeech() {
                    // User started speaking
                }

                override fun onRmsChanged(rmsdB: Float) {
                    // Volume level changed - could be used for visual feedback
                }

                override fun onBufferReceived(buffer: ByteArray?) {
                    // Audio buffer received
                }

                override fun onEndOfSpeech() {
                    isListening = false
                }

                override fun onError(error: Int) {
                    isListening = false
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
                    onError(errorMessage)
                }

                override fun onResults(results: Bundle?) {
                    isListening = false
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    if (!matches.isNullOrEmpty()) {
                        onResult(matches[0])
                    } else {
                        onError("No results found")
                    }
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    if (!matches.isNullOrEmpty()) {
                        onPartialResult(matches[0])
                    }
                }

                override fun onEvent(eventType: Int, params: Bundle?) {
                    // Reserved for future events
                }
            })

            // Create recognition intent
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale.toString())
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            }

            // Start listening
            speechRecognizer?.startListening(intent)

        } catch (e: Exception) {
            isListening = false
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
        } catch (e: Exception) {
            // Ignore errors when stopping
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
        } catch (e: Exception) {
            // Ignore errors when destroying
        }
    }

    /**
     * Returns whether the manager is currently listening.
     */
    fun isListening(): Boolean = isListening
}
