package com.shamelagpt.android.presentation.history

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.platform.app.InstrumentationRegistry
import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.R
import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.presentation.common.TestTags
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import kotlinx.coroutines.flow.MutableStateFlow
import org.junit.Rule
import org.junit.Test

class HistoryScreenTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun authenticatedStateShowsConversationsAndNavigatesOnTap() {
        val viewModel = mockk<HistoryViewModel>(relaxed = true, relaxUnitFun = true)
        val conversations = listOf(
            Conversation(
                id = "conv-1",
                title = "First conversation",
                createdAt = 1700000000000,
                updatedAt = 1700000000000
            ),
            Conversation(
                id = "conv-2",
                title = "Second conversation",
                createdAt = 1700001000000,
                updatedAt = 1700001000000
            )
        )
        every { viewModel.uiState } returns MutableStateFlow(
            HistoryUiState(conversations = conversations, isLoading = false)
        )
        every { viewModel.loadConversations() } just Runs
        every { viewModel.deleteConversation(any()) } just Runs

        var selectedConversationId: String? = null

        composeRule.setContent {
            HistoryScreen(
                isAuthenticated = true,
                onNavigateToChat = { selectedConversationId = it },
                onNavigateToAuth = {},
                viewModel = viewModel
            )
        }

        composeRule.onNodeWithTag(TestTags.History.List).assertIsDisplayed()
        composeRule.onNodeWithTag(TestTags.History.conversationCard("conv-1")).assertIsDisplayed()
        composeRule.onNodeWithTag(TestTags.History.conversationCard("conv-1")).performClick()

        assertThat(selectedConversationId).isEqualTo("conv-1")
    }

    @Test
    fun guestStateShowsSignInCtaAndNavigatesToAuth() {
        val viewModel = mockk<HistoryViewModel>(relaxed = true, relaxUnitFun = true)
        every { viewModel.uiState } returns MutableStateFlow(HistoryUiState())

        var authNavigationTriggered = false

        composeRule.setContent {
            HistoryScreen(
                isAuthenticated = false,
                onNavigateToChat = {},
                onNavigateToAuth = { authNavigationTriggered = true },
                viewModel = viewModel
            )
        }

        val signInLabel = InstrumentationRegistry.getInstrumentation()
            .targetContext
            .getString(R.string.settings_sign_in_button)
        composeRule.onNodeWithText(signInLabel).assertIsDisplayed()
        composeRule.onNodeWithText(signInLabel).performClick()

        assertThat(authNavigationTriggered).isTrue()
    }
}
