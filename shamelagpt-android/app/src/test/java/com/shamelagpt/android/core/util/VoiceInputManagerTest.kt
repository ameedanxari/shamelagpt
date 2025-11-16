package com.shamelagpt.android.core.util

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import com.google.common.truth.Truth.assertThat
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.unmockkAll
import java.util.Locale
import org.junit.After
import org.junit.Before
import org.junit.Test

class VoiceInputManagerTest {

    private lateinit var context: Context
    private lateinit var packageManager: PackageManager
    private lateinit var voiceInputManager: VoiceInputManager

    @Before
    fun setUp() {
        context = mockk(relaxed = true)
        packageManager = mockk(relaxed = true)
        every { context.packageManager } returns packageManager
        mockkStatic(SpeechRecognizer::class)

        voiceInputManager = VoiceInputManager(context)
    }

    @After
    fun tearDown() {
        unmockkAll()
    }

    @Test
    fun getCapabilityReturnsDirectWhenSpeechRecognizerAvailable() {
        every { SpeechRecognizer.isRecognitionAvailable(context) } returns true

        val capability = voiceInputManager.getCapability()

        assertThat(capability).isEqualTo(VoiceInputCapability.DIRECT)
    }

    @Test
    fun getCapabilityReturnsIntentFallbackWhenRecognizerUnavailableAndHandlerExists() {
        every { SpeechRecognizer.isRecognitionAvailable(context) } returns false
        every { packageManager.queryIntentActivities(any<Intent>(), any<Int>()) } returns
            listOf(mockk<ResolveInfo>(relaxed = true))

        val capability = voiceInputManager.getCapability()

        assertThat(capability).isEqualTo(VoiceInputCapability.INTENT_FALLBACK)
    }

    @Test
    fun getCapabilityReturnsUnavailableWhenNoRecognizerOrFallbackHandler() {
        every { SpeechRecognizer.isRecognitionAvailable(context) } returns false
        every { packageManager.queryIntentActivities(any<Intent>(), any<Int>()) } returns
            emptyList<ResolveInfo>()

        val capability = voiceInputManager.getCapability()

        assertThat(capability).isEqualTo(VoiceInputCapability.UNAVAILABLE)
    }

    @Test
    fun createFallbackIntentContainsExpectedSpeechRecognizerExtras() {
        val locale = Locale("ar", "SA")

        val intent = voiceInputManager.createFallbackIntent(locale)

        assertThat(intent).isNotNull()
    }

    @Test
    fun extractBestResultReturnsTrimmedFirstResult() {
        val intent = mockk<Intent> {
            every { getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS) } returns
                arrayListOf("   first result   ", "second")
        }

        val result = voiceInputManager.extractBestResult(intent)

        assertThat(result).isEqualTo("first result")
    }

    @Test
    fun extractBestResultReturnsNullForBlankOrMissingResults() {
        val blankIntent = mockk<Intent> {
            every { getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS) } returns arrayListOf("   ")
        }
        val emptyIntent = mockk<Intent> {
            every { getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS) } returns null
        }

        assertThat(voiceInputManager.extractBestResult(blankIntent)).isNull()
        assertThat(voiceInputManager.extractBestResult(emptyIntent)).isNull()
    }

    @Test
    fun getUnavailableMessageReturnsCanonicalMessage() {
        assertThat(voiceInputManager.getUnavailableMessage())
            .isEqualTo("Voice input is not available on this device.")
    }
}
