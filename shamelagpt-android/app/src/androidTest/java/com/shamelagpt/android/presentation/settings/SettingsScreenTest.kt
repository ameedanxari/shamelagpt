package com.shamelagpt.android.presentation.settings

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.hasTestTag
import com.shamelagpt.android.presentation.common.TestTags
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import kotlinx.coroutines.flow.MutableStateFlow
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import com.shamelagpt.android.domain.model.ResponsePreferences

class SettingsScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    private fun scrollToTag(tag: String) {
        composeTestRule.onNodeWithTag(TestTags.Settings.List)
            .performScrollToNode(hasTestTag(tag))
    }

    @Test
    fun settingsElements_areDisplayed_whenAuthenticated() {
        // Given
        val mockViewModel = mockk<SettingsViewModel>(relaxed = true)
        // Mock StateFlows
        every { mockViewModel.selectedLanguage } returns MutableStateFlow("en")
        every { mockViewModel.isAuthenticated } returns MutableStateFlow(true)
        every { mockViewModel.customPrompt } returns MutableStateFlow("")
        every { mockViewModel.responsePreferences } returns MutableStateFlow(ResponsePreferences())

        composeTestRule.setContent {
            SettingsScreen(
                isAuthenticated = true,
                onNavigateToLanguage = {},
                onNavigateToAbout = {},
                onNavigateToAuth = {},
                onLogout = {},
                viewModel = mockViewModel
            )
        }

        // Verify General items
        scrollToTag(TestTags.Settings.LanguageItem)
        composeTestRule.onNodeWithTag(TestTags.Settings.LanguageItem, useUnmergedTree = true).assertIsDisplayed()
        
        // Verify Preferences items (Auth only)
        scrollToTag(TestTags.Settings.CustomPromptItem)
        composeTestRule.onNodeWithTag(TestTags.Settings.CustomPromptItem, useUnmergedTree = true).assertIsDisplayed()
        scrollToTag(TestTags.Settings.CustomPromptTextField)
        composeTestRule.onNodeWithTag(TestTags.Settings.CustomPromptTextField, useUnmergedTree = true).assertIsDisplayed()
        scrollToTag(TestTags.Settings.LengthItem)
        composeTestRule.onNodeWithTag(TestTags.Settings.LengthItem, useUnmergedTree = true).assertIsDisplayed()
        scrollToTag(TestTags.Settings.StyleItem)
        composeTestRule.onNodeWithTag(TestTags.Settings.StyleItem, useUnmergedTree = true).assertIsDisplayed()
        scrollToTag(TestTags.Settings.FocusItem)
        composeTestRule.onNodeWithTag(TestTags.Settings.FocusItem, useUnmergedTree = true).assertIsDisplayed()
        scrollToTag(TestTags.Settings.SavePreferencesButton)
        composeTestRule.onNodeWithTag(TestTags.Settings.SavePreferencesButton, useUnmergedTree = true).assertIsDisplayed()
        
        // Verify Footer items
        scrollToTag(TestTags.Settings.SupportItem)
        composeTestRule.onNodeWithTag(TestTags.Settings.SupportItem, useUnmergedTree = true).assertIsDisplayed()
        scrollToTag(TestTags.Settings.AboutItem)
        composeTestRule.onNodeWithTag(TestTags.Settings.AboutItem, useUnmergedTree = true).assertIsDisplayed()
        scrollToTag(TestTags.Settings.LogoutItem)
        composeTestRule.onNodeWithTag(TestTags.Settings.LogoutItem, useUnmergedTree = true).assertIsDisplayed()
    }
    
    @Test
    fun guestMode_hidesPreferencesAndShowsSignIn() {
        val mockViewModel = mockk<SettingsViewModel>(relaxed = true)
        every { mockViewModel.selectedLanguage } returns MutableStateFlow("en")
        every { mockViewModel.isAuthenticated } returns MutableStateFlow(false) // Not authenticated
        every { mockViewModel.customPrompt } returns MutableStateFlow("")
        every { mockViewModel.responsePreferences } returns MutableStateFlow(ResponsePreferences())
        
        composeTestRule.setContent {
            SettingsScreen(
                isAuthenticated = false,
                onNavigateToLanguage = {},
                onNavigateToAbout = {},
                onNavigateToAuth = {},
                onLogout = {},
                viewModel = mockViewModel
            )
        }
        
        // Custom Prompt should NOT be displayed
        composeTestRule.onNodeWithTag(TestTags.Settings.CustomPromptItem, useUnmergedTree = true).assertDoesNotExist()
        
        // Sign In button should be displayed
        composeTestRule.onNodeWithTag(TestTags.Settings.SignInButton, useUnmergedTree = true).assertIsDisplayed()
    }

    @Test
    fun clickLanguage_callsNavigate() {
        val mockViewModel = mockk<SettingsViewModel>(relaxed = true)
        every { mockViewModel.selectedLanguage } returns MutableStateFlow("en")
        every { mockViewModel.isAuthenticated } returns MutableStateFlow(true)
        every { mockViewModel.customPrompt } returns MutableStateFlow("")
        every { mockViewModel.responsePreferences } returns MutableStateFlow(ResponsePreferences())

        var navigateCalled = false
        composeTestRule.setContent {
            SettingsScreen(
                isAuthenticated = true,
                onNavigateToLanguage = { navigateCalled = true },
                onNavigateToAbout = {},
                onNavigateToAuth = {},
                onLogout = {},
                viewModel = mockViewModel
            )
        }

        composeTestRule.onNodeWithTag(TestTags.Settings.LanguageItem, useUnmergedTree = true).performClick()
        assertTrue("Language navigation callback should be invoked", navigateCalled)
    }
}
