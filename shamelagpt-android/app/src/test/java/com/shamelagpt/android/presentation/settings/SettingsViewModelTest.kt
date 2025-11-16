package com.shamelagpt.android.presentation.settings

import com.shamelagpt.android.core.util.LanguageManager
import com.shamelagpt.android.domain.model.ResponsePreferences
import com.shamelagpt.android.domain.model.UserPreferences
import com.shamelagpt.android.domain.repository.AuthRepository
import com.shamelagpt.android.domain.repository.PreferencesRepository
import io.mockk.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class SettingsViewModelTest {

    private lateinit var viewModel: SettingsViewModel
    private val languageManager = mockk<LanguageManager>(relaxed = true)
    private val authRepository = mockk<AuthRepository>(relaxed = true)
    private val preferencesRepository = mockk<PreferencesRepository>(relaxed = true)
    private val testDispatcher = UnconfinedTestDispatcher()

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        every { languageManager.getLanguage() } returns "en"
        every { authRepository.isLoggedIn() } returns true
        
        // Mock fetchPreferences to avoid crash in init
        coEvery { preferencesRepository.fetchPreferences() } returns Result.success(UserPreferences())
        
        viewModel = SettingsViewModel(languageManager, authRepository, preferencesRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initially loads preferences if authenticated`() = runTest {
        // Given
        val prefs = UserPreferences(languagePreference = "ar", customSystemPrompt = "Prompt", responsePreferences = ResponsePreferences())
        coEvery { preferencesRepository.fetchPreferences() } returns Result.success(prefs)
        
        // Re-init viewModel to trigger loading with new mock
        viewModel = SettingsViewModel(languageManager, authRepository, preferencesRepository)

        // Then
        testDispatcher.scheduler.advanceUntilIdle()
        
        assertEquals("ar", viewModel.selectedLanguage.value)
        assertEquals("Prompt", viewModel.customPrompt.value)
    }

    @Test
    fun `updateLanguage updates manager and state`() {
        // When
        viewModel.updateLanguage("ar")

        // Then
        verify { languageManager.setLanguage("ar") }
        assertEquals("ar", viewModel.selectedLanguage.value)
    }

    @Test
    fun `savePreferences calls repository`() = runTest {
        // Given
        viewModel.updateCustomPrompt("New Prompt")
        
        // When
        viewModel.savePreferences()
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { preferencesRepository.updatePreferences(any()) }
    }
}
