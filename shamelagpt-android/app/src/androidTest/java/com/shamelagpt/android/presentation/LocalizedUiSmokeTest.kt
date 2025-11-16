package com.shamelagpt.android.presentation

import android.content.res.Configuration
import androidx.activity.ComponentActivity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.unit.LayoutDirection
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.presentation.common.TestTags
import com.shamelagpt.android.presentation.chat.ChatEvent
import com.shamelagpt.android.presentation.chat.ChatScreen
import com.shamelagpt.android.presentation.chat.ChatUiState
import com.shamelagpt.android.presentation.history.HistoryScreen
import com.shamelagpt.android.presentation.history.HistoryUiState
import com.shamelagpt.android.presentation.history.HistoryViewModel
import com.shamelagpt.android.presentation.theme.ShamelaGPTTheme
import com.shamelagpt.android.presentation.welcome.WelcomeScreen
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.util.Locale

/**
 * Lightweight locale smoke tests (en/ar/ur) for key flows (welcome, history, chat error)
 * to mirror the screenshot harness without producing images.
 */
@RunWith(Parameterized::class)
class LocalizedUiSmokeTest(private val localeTag: String) {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "locale={0}")
        fun data() = listOf("en", "ar", "ur")
    }

    @Before
    fun setLocale() {
        val target = InstrumentationRegistry.getInstrumentation().targetContext
        val locale = Locale(localeTag)
        Locale.setDefault(locale)
        val config = Configuration(target.resources.configuration)
        config.setLocale(locale)
    }

    @Test
    fun welcome_displays_primary_ctas_for_locale() {
        composeRule.setContent {
            val isRtl = localeTag.lowercase() in listOf("ar", "ur", "fa")
            ShamelaGPTTheme {
                androidx.compose.runtime.CompositionLocalProvider(
                    LocalLayoutDirection provides if (isRtl) LayoutDirection.Rtl else LayoutDirection.Ltr
                ) {
                    WelcomeScreen(
                        onGetStarted = {},
                        onSkipToChat = {}
                    )
                }
            }
        }

        composeRule.onNodeWithTag(TestTags.Welcome.Screen).assertExists()
        composeRule.onNodeWithTag(TestTags.Welcome.Logo).assertExists()
        composeRule.onNodeWithTag(TestTags.Welcome.GetStartedButton).assertExists()
        composeRule.onNodeWithTag(TestTags.Welcome.SkipButton).assertExists()
    }

    @Test
    fun history_shows_conversation_cards_for_locale() {
        val mockViewModel = mockk<HistoryViewModel>(relaxed = true, relaxUnitFun = true)
        val conversations = listOf(
            Conversation(id = "conv-1", title = "Tax research", createdAt = 1700000000000, updatedAt = 1700000000000),
            Conversation(id = "conv-2", title = "Travel ideas", createdAt = 1700001000000, updatedAt = 1700001000000)
        )
        val state = MutableStateFlow(HistoryUiState(conversations = conversations, isLoading = false))
        every { mockViewModel.uiState } returns state
        every { mockViewModel.loadConversations() } just Runs
        every { mockViewModel.deleteConversation(any()) } just Runs

        composeRule.setContent {
            val isRtl = localeTag.lowercase() in listOf("ar", "ur", "fa")
            ShamelaGPTTheme {
                androidx.compose.runtime.CompositionLocalProvider(
                    LocalLayoutDirection provides if (isRtl) LayoutDirection.Rtl else LayoutDirection.Ltr
                ) {
                    HistoryScreen(
                        isAuthenticated = true,
                        onNavigateToChat = {},
                        onNavigateToAuth = {},
                        viewModel = mockViewModel
                    )
                }
            }
        }

        composeRule.onNodeWithTag(TestTags.History.List).assertIsDisplayed()
        composeRule.onNodeWithTag(TestTags.History.conversationCard("conv-1")).assertIsDisplayed()
        composeRule.onNodeWithTag(TestTags.History.conversationCard("conv-2")).assertIsDisplayed()
    }

    @Test
    fun chat_shows_error_snackbar_for_locale() {
        val mockViewModel = mockk<com.shamelagpt.android.presentation.chat.ChatViewModel>(relaxed = true, relaxUnitFun = true)
        val uiState = MutableStateFlow(ChatUiState())
        val events = MutableSharedFlow<ChatEvent>(extraBufferCapacity = 1)
        every { mockViewModel.uiState } returns uiState
        every { mockViewModel.events } returns events
        every { mockViewModel.loadConversation(any()) } just Runs

        composeRule.setContent {
            val isRtl = localeTag.lowercase() in listOf("ar", "ur", "fa")
            ShamelaGPTTheme {
                androidx.compose.runtime.CompositionLocalProvider(
                    LocalLayoutDirection provides if (isRtl) LayoutDirection.Rtl else LayoutDirection.Ltr
                ) {
                    ChatScreen(
                        viewModel = mockViewModel
                    )
                }
            }
        }

        // Emit an error and assert canonical error selector appears
        events.tryEmit(ChatEvent.ShowError("Offline mode"))
        composeRule.waitUntil(timeoutMillis = 3_000) {
            composeRule.onAllNodesWithTag(TestTags.Chat.ErrorBanner).fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithTag(TestTags.Chat.ErrorBanner).assertIsDisplayed()
    }
}
