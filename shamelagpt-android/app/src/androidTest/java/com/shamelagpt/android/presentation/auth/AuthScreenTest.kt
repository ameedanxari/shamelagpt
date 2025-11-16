package com.shamelagpt.android.presentation.auth

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import com.shamelagpt.android.presentation.common.TestTags
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import kotlinx.coroutines.flow.MutableStateFlow
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class AuthScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun signInWithValidCredentials_callsAuthenticate() {
        // Given
        val mockViewModel = mockk<AuthViewModel>(relaxed = true)
        val stateFlow = MutableStateFlow(AuthUiState()) // Initial empty state
        every { mockViewModel.uiState } returns stateFlow

        composeTestRule.setContent {
            AuthScreen(
                onAuthenticated = {},
                onContinueAsGuest = {},
                viewModel = mockViewModel
            )
        }

        // When: User types email
        composeTestRule.onNodeWithTag(TestTags.Auth.EmailField).performTextInput("test@example.com")
        verify { mockViewModel.updateEmail("test@example.com") }

        // When: User types password
        composeTestRule.onNodeWithTag(TestTags.Auth.PasswordField).performTextInput("password123")
        verify { mockViewModel.updatePassword("password123") }

        // Simulate ViewModel updating state (since it's mocked)
        stateFlow.value = AuthUiState(
            email = "test@example.com",
            password = "password123",
            isLoginMode = true
        )

        // When: User clicks Sign In
        composeTestRule.onNodeWithTag(TestTags.Auth.SignInButton).performClick()

        // Then: Authenticate is called
        verify { mockViewModel.authenticate(any()) }
    }

    @Test
    fun guestMode_callsOnContinueAsGuest() {
        val mockViewModel = mockk<AuthViewModel>(relaxed = true)
        val stateFlow = MutableStateFlow(AuthUiState())
        every { mockViewModel.uiState } returns stateFlow

        var onContinueAsGuestCalled = false

        composeTestRule.setContent {
            AuthScreen(
                onAuthenticated = {},
                onContinueAsGuest = { onContinueAsGuestCalled = true },
                viewModel = mockViewModel
            )
        }

        // When: User clicks Continue as Guest
        composeTestRule.onNodeWithTag(TestTags.Auth.ContinueAsGuestButton).performClick()

        // Then
        assertTrue("Continue as guest callback should be invoked", onContinueAsGuestCalled)
    }

    @Test
    fun toggleMode_callsToggleMode() {
        val mockViewModel = mockk<AuthViewModel>(relaxed = true)
        val stateFlow = MutableStateFlow(AuthUiState(isLoginMode = true))
        every { mockViewModel.uiState } returns stateFlow

        composeTestRule.setContent {
            AuthScreen(
                onAuthenticated = {},
                onContinueAsGuest = {},
                viewModel = mockViewModel
            )
        }

        // When: User clicks Toggle Mode
        composeTestRule.onNodeWithTag(TestTags.Auth.ToggleModeButton).performClick()

        // Then
        verify { mockViewModel.toggleMode() }
        
        // And Button text changes (need to simulate state change)
        stateFlow.value = AuthUiState(isLoginMode = false)
        composeTestRule.onNodeWithTag(TestTags.Auth.SignUpButton).assertIsDisplayed()
    }
}
