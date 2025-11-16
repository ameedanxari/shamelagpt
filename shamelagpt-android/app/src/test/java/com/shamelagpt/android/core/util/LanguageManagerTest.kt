package com.shamelagpt.android.core.util

import android.content.Context
import android.content.res.Configuration
import android.content.res.Resources
import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.core.preferences.PreferencesManager
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.slot
import java.util.Locale
import org.junit.After
import org.junit.Before
import org.junit.Test

class LanguageManagerTest {

    private lateinit var mockContext: Context
    private lateinit var mockResources: Resources
    private lateinit var mockPreferences: PreferencesManager
    private lateinit var configuration: Configuration
    private lateinit var languageManager: LanguageManager
    private lateinit var originalLocale: Locale

    @Before
    fun setUp() {
        originalLocale = Locale.getDefault()
        mockContext = mockk(relaxed = true)
        mockResources = mockk(relaxed = true)
        mockPreferences = mockk(relaxed = true)
        configuration = Configuration()

        every { mockContext.resources } returns mockResources
        every { mockResources.configuration } returns configuration
        every { mockContext.createConfigurationContext(any()) } returns mockContext

        languageManager = LanguageManager(mockContext, mockPreferences)
    }

    @After
    fun tearDown() {
        Locale.setDefault(originalLocale)
    }

    @Test
    fun setLanguageUpdatesPreferencesAndLocale() {
        // Given
        val capturedLanguage = slot<String>()
        every { mockPreferences.setSelectedLanguage(capture(capturedLanguage)) } just Runs

        // When
        languageManager.setLanguage(LanguageManager.LANGUAGE_ARABIC)

        // Then
        assertThat(capturedLanguage.captured).isEqualTo("ar")
        assertThat(Locale.getDefault().language).isEqualTo("ar")
    }

    @Test
    fun getLanguageDelegatesToPreferences() {
        // Given
        every { mockPreferences.getSelectedLanguage() } returns "en"

        // When
        val language = languageManager.getLanguage()

        // Then
        assertThat(language).isEqualTo("en")
    }

    @Test
    fun applySavedLanguageUsesStoredLocale() {
        // Given
        every { mockPreferences.getSelectedLanguage() } returns "ar"

        // When
        languageManager.applySavedLanguage()

        // Then
        assertThat(Locale.getDefault().language).isEqualTo("ar")
    }
}
