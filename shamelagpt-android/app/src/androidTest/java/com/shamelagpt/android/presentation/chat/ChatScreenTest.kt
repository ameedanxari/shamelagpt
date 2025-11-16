package com.shamelagpt.android.presentation.chat

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.presentation.common.TestTags
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.verify
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import org.junit.Rule
import org.junit.Test

class ChatScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun sendMessage_callsViewModel() {
        // Given
        val mockViewModel = mockk<ChatViewModel>(relaxed = true, relaxUnitFun = true)
        val uiState = ChatUiState()
        val stateFlow = MutableStateFlow(uiState)
        val eventsFlow = MutableSharedFlow<ChatEvent>()
        
        every { mockViewModel.uiState } returns stateFlow
        every { mockViewModel.events } returns eventsFlow
        every { mockViewModel.loadConversation(any()) } just Runs
        every { mockViewModel.updateInputText(any()) } just Runs
        every { mockViewModel.sendMessage() } just Runs
        every { mockViewModel.sendMessage(any()) } just Runs

        composeTestRule.setContent {
            ChatScreen(
                viewModel = mockViewModel
            )
        }

        // When: Type message
        val testMessage = "Hello World"
        composeTestRule.onNodeWithTag(TestTags.Chat.MessageInputField).performTextInput(testMessage)
        
        // Then: verify updateInputText is called
        verify { mockViewModel.updateInputText(testMessage) }
        
        // Simulate ViewModel updating state to enable send button
        stateFlow.value = uiState.copy(inputText = testMessage)
        
        // When: Click send
        composeTestRule.onNodeWithTag(TestTags.Chat.SendButton).performClick()
        
        // Then: verify sendMessage called
        verify { mockViewModel.sendMessage(testMessage) }
    }

    @Test
    fun emptyState_isShown_whenNoMessages() {
        val mockViewModel = mockk<ChatViewModel>(relaxed = true, relaxUnitFun = true)
        val stateFlow = MutableStateFlow(ChatUiState(messages = emptyList(), isLoading = false))
        every { mockViewModel.uiState } returns stateFlow
        every { mockViewModel.events } returns MutableSharedFlow()
        every { mockViewModel.loadConversation(any()) } just Runs

        composeTestRule.setContent {
            ChatScreen(viewModel = mockViewModel)
        }

        composeTestRule.onNodeWithTag(TestTags.Chat.EmptyState).assertIsDisplayed()
        composeTestRule.onNodeWithTag(TestTags.Chat.MessagesList).assertDoesNotExist()
    }

    @Test
    fun streamingState_showsTypingAndThinkingIndicators() {
        val mockViewModel = mockk<ChatViewModel>(relaxed = true, relaxUnitFun = true)
        val stateFlow = MutableStateFlow(
            ChatUiState(
                messages = emptyList(),
                isLoading = true,
                thinkingMessages = listOf("Thinking...")
            )
        )

        every { mockViewModel.uiState } returns stateFlow
        every { mockViewModel.events } returns MutableSharedFlow()
        every { mockViewModel.loadConversation(any()) } just Runs

        composeTestRule.setContent {
            ChatScreen(viewModel = mockViewModel)
        }

        composeTestRule.onNodeWithTag(TestTags.Chat.ThinkingBubble, useUnmergedTree = true)
            .assertIsDisplayed()
        composeTestRule.onNodeWithTag(TestTags.Chat.TypingIndicator, useUnmergedTree = true)
            .assertExists()
    }

    @Test
    fun streamingMessage_isRendered() {
        val mockViewModel = mockk<ChatViewModel>(relaxed = true, relaxUnitFun = true)
        val streamingMessage = Message(
            id = "stream-1",
            content = "Streaming response chunk",
            isUserMessage = false,
            timestamp = 0L
        )
        val stateFlow = MutableStateFlow(
            ChatUiState(
                messages = listOf(
                    Message(
                        id = "user-1",
                        content = "Hello",
                        isUserMessage = true,
                        timestamp = 0L
                    )
                ),
                streamingMessage = streamingMessage,
                isLoading = true
            )
        )

        every { mockViewModel.uiState } returns stateFlow
        every { mockViewModel.events } returns MutableSharedFlow()
        every { mockViewModel.loadConversation(any()) } just Runs

        composeTestRule.setContent {
            ChatScreen(viewModel = mockViewModel)
        }

        composeTestRule.onAllNodesWithTag(TestTags.Chat.MessageBubble, useUnmergedTree = true)
            .assertCountEquals(2)
    }

    @Test
    fun errorEvent_showsCanonicalErrorBannerSelector() {
        val mockViewModel = mockk<ChatViewModel>(relaxed = true, relaxUnitFun = true)
        val stateFlow = MutableStateFlow(ChatUiState())
        val eventsFlow = MutableSharedFlow<ChatEvent>(extraBufferCapacity = 1)

        every { mockViewModel.uiState } returns stateFlow
        every { mockViewModel.events } returns eventsFlow
        every { mockViewModel.loadConversation(any()) } just Runs

        composeTestRule.setContent {
            ChatScreen(viewModel = mockViewModel)
        }

        eventsFlow.tryEmit(ChatEvent.ShowError("Offline mode"))

        composeTestRule.waitUntil(timeoutMillis = 3_000) {
            composeTestRule.onAllNodesWithTag(TestTags.Chat.ErrorBanner).fetchSemanticsNodes().isNotEmpty()
        }
        composeTestRule.onNodeWithTag(TestTags.Chat.ErrorBanner).assertIsDisplayed()
    }
}
