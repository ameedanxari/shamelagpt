package com.shamelagpt.android.presentation.welcome

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.presentation.common.TestTags
import org.junit.Rule
import org.junit.Test

class WelcomeScreenTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun welcomeElementsAreDisplayed() {
        composeRule.setContent {
            WelcomeScreen(
                onGetStarted = {},
                onSkipToChat = {}
            )
        }

        composeRule.onNodeWithTag(TestTags.Welcome.Screen).assertIsDisplayed()
        composeRule.onNodeWithTag(TestTags.Welcome.Logo).assertIsDisplayed()
        composeRule.onNodeWithTag(TestTags.Welcome.GetStartedButton).assertIsDisplayed()
        composeRule.onNodeWithTag(TestTags.Welcome.SkipButton).assertIsDisplayed()
    }

    @Test
    fun clickingGetStartedInvokesCallback() {
        var getStartedClicked = false

        composeRule.setContent {
            WelcomeScreen(
                onGetStarted = { getStartedClicked = true },
                onSkipToChat = {}
            )
        }

        composeRule.onNodeWithTag(TestTags.Welcome.GetStartedButton).performClick()

        assertThat(getStartedClicked).isTrue()
    }

    @Test
    fun clickingSkipInvokesCallback() {
        var skipClicked = false

        composeRule.setContent {
            WelcomeScreen(
                onGetStarted = {},
                onSkipToChat = { skipClicked = true }
            )
        }

        composeRule.onNodeWithTag(TestTags.Welcome.SkipButton).performClick()

        assertThat(skipClicked).isTrue()
    }
}
