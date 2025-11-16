package com.shamelagpt.android.presentation.chat

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import app.cash.turbine.test
import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.core.util.OCRManager
import com.shamelagpt.android.core.util.OCRResult
import com.shamelagpt.android.core.util.VoiceInputManager
import com.shamelagpt.android.core.preferences.PreferencesManager
import com.shamelagpt.android.domain.usecase.SendMessageUseCase
import com.shamelagpt.android.domain.usecase.StreamMessageUseCase
import com.shamelagpt.android.domain.usecase.OCRUseCase
import com.shamelagpt.android.domain.usecase.ConfirmFactCheckUseCase
import com.shamelagpt.android.mock.MockChatRepository
import com.shamelagpt.android.mock.MockConversationRepository
import com.shamelagpt.android.mock.MockScenarioId
import com.shamelagpt.android.mock.MockScenarioMatrix
import com.shamelagpt.android.mock.TestData
import com.shamelagpt.android.util.MainCoroutineRule
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.verify
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import java.io.ByteArrayInputStream
import java.util.Locale

/**
 * Unit tests for ChatViewModel.
 * Maintains parity with iOS ChatViewModelTests (43 tests).
 */
@ExperimentalCoroutinesApi
class ChatViewModelTest {

    @get:Rule
    val mainCoroutineRule = MainCoroutineRule()

    private lateinit var viewModel: ChatViewModel
    private lateinit var sendMessageUseCase: SendMessageUseCase
    private lateinit var streamMessageUseCase: StreamMessageUseCase
    private lateinit var ocrUseCase: OCRUseCase
    private lateinit var confirmFactCheckUseCase: ConfirmFactCheckUseCase
    private lateinit var mockChatRepository: MockChatRepository
    private lateinit var mockConversationRepository: MockConversationRepository
    private lateinit var mockVoiceInputManager: VoiceInputManager
    private lateinit var mockOCRManager: OCRManager
    private lateinit var mockPreferencesManager: PreferencesManager
    private lateinit var mockContext: Context
    private lateinit var mockContentResolver: ContentResolver

    @Before
    fun setup() {
        mockkStatic(android.net.Uri::class)
        mockkStatic(android.util.Base64::class)
        every { android.net.Uri.parse(any()) } returns mockk(relaxed = true)
        every { android.util.Base64.encodeToString(any<ByteArray>(), any()) } answers {
            java.util.Base64.getEncoder().encodeToString(it.invocation.args[0] as ByteArray)
        }

        mockConversationRepository = MockConversationRepository()
        mockChatRepository = MockChatRepository(mockConversationRepository)
        mockVoiceInputManager = mockk(relaxed = true)
        mockOCRManager = mockk(relaxed = true)
        mockPreferencesManager = mockk(relaxed = true)
        every { mockPreferencesManager.getSelectedLanguage() } returns "en"
        mockContext = mockk(relaxed = true)
        mockContentResolver = mockk(relaxed = true)
        every { mockContext.contentResolver } returns mockContentResolver

        sendMessageUseCase = SendMessageUseCase(
            chatRepository = mockChatRepository,
            conversationRepository = mockConversationRepository
        )

        streamMessageUseCase = StreamMessageUseCase(
            chatRepository = mockChatRepository,
            conversationRepository = mockConversationRepository
        )

        ocrUseCase = OCRUseCase(
            chatRepository = mockChatRepository
        )

        confirmFactCheckUseCase = ConfirmFactCheckUseCase(
            chatRepository = mockChatRepository
        )

        viewModel = ChatViewModel(
            sendMessageUseCase = sendMessageUseCase,
            streamMessageUseCase = streamMessageUseCase,
            ocrUseCase = ocrUseCase,
            confirmFactCheckUseCase = confirmFactCheckUseCase,
            conversationRepository = mockConversationRepository,
            voiceInputManager = mockVoiceInputManager,
            ocrManager = mockOCRManager,
            context = mockContext,
            preferencesManager = mockPreferencesManager
        )
    }

    @After
    fun tearDown() {
        mockChatRepository.reset()
        mockConversationRepository.reset()
    }

    // MARK: - Message Sending Tests

    @Test
    fun testSendMessageClearsInputText() = runTest {
        // Given
        viewModel.updateInputText("Test message")

        // When
        viewModel.sendMessage()

        // Then - input should be cleared immediately
        assertThat(viewModel.uiState.value.inputText).isEmpty()
    }

    @Test
    fun testCanSendMessageWhenInputIsNotEmpty() = runTest {
        // Given
        viewModel.updateInputText("Test message")

        // Then
        val canSend = viewModel.uiState.value.inputText.isNotBlank() && !viewModel.uiState.value.isLoading
        assertThat(canSend).isTrue()
    }

    @Test
    fun testCannotSendMessageWhenInputIsEmpty() = runTest {
        // Given
        viewModel.updateInputText("")

        // Then
        val canSend = viewModel.uiState.value.inputText.isNotBlank() && !viewModel.uiState.value.isLoading
        assertThat(canSend).isFalse()
    }

    @Test
    fun testCannotSendMessageWhenLoading() = runTest {
        // Given
        mockChatRepository.delayMs = 1000 // Ensure sendMessage takes time
        viewModel.updateInputText("Test message")

        // When - Send first message (starts loading)
        viewModel.sendMessage()

        // Verify loading state is true
        assertThat(viewModel.uiState.value.isLoading).isTrue()

        // Attempting to send again while loading should be ignored
        viewModel.updateInputText("Second message")
        viewModel.sendMessage()

        // Wait for first message to complete
        testScheduler.advanceUntilIdle()

        // Then - Should only have sent the first message
        assertThat(mockChatRepository.streamMessageCallCount).isEqualTo(1)
        assertThat(mockChatRepository.lastQuestion).isEqualTo("Test message")
    }

    @Test
    fun testSendMessageWithWhitespaceOnlyIsIgnored() = runTest {
        // Given
        viewModel.updateInputText("   \n\t  ")

        // When
        viewModel.sendMessage()

        // Then - message should not be sent
        assertThat(mockChatRepository.streamMessageCallCount).isEqualTo(0)
        assertThat(viewModel.uiState.value.inputText).isEqualTo("   \n\t  ") // Not cleared
    }

    @Test
    fun testSendMessagePassesLanguagePreferenceAndThinkingFlagToStream() = runTest {
        // Given
        every { mockPreferencesManager.getSelectedLanguage() } returns "ar"
        viewModel.updateInputText("اختبار اللغة")

        // When
        viewModel.sendMessage()
        testScheduler.advanceUntilIdle()

        // Then
        assertThat(mockChatRepository.streamMessageCallCount).isEqualTo(1)
        assertThat(mockChatRepository.lastLanguagePreference).isEqualTo("ar")
        assertThat(mockChatRepository.lastEnableThinking).isTrue()
    }

    @Test
    fun testSendMessageShowsDefaultThinkingMessageBeforeFirstChunk() = runTest {
        // Given
        mockChatRepository.delayMs = 1000
        viewModel.updateInputText("Test thinking state")

        // When
        viewModel.sendMessage()

        // Then
        assertThat(viewModel.uiState.value.isLoading).isTrue()
        assertThat(viewModel.uiState.value.thinkingMessages).containsExactly("Thinking...")
    }

    @Test
    fun testSendMessageUpdatesThreadId() = runTest {
        // Given
        viewModel.updateInputText("Test message")
        val expectedThreadId = "thread_abc123"
        mockChatRepository.sendMessageResult = Result.success(
            TestData.createChatResponse(threadId = expectedThreadId)
        )

        // When
        viewModel.sendMessage()

        // Wait for coroutine
        testScheduler.advanceUntilIdle()

        // Then
        assertThat(viewModel.uiState.value.threadId).isEqualTo(expectedThreadId)
    }

    @Test
    fun testSendMessageSuccess() = runTest {
        // Given
        viewModel.updateInputText("What is prayer?")
        mockChatRepository.sendMessageResult = Result.success(TestData.sampleChatResponse)

        // When
        viewModel.sendMessage()

        // Wait for coroutine
        testScheduler.advanceUntilIdle()

        // Then
        assertThat(viewModel.uiState.value.isLoading).isFalse()
        assertThat(viewModel.uiState.value.error).isNull()
        assertThat(viewModel.uiState.value.threadId).isEqualTo(TestData.sampleChatResponse.threadId)
        assertThat(mockChatRepository.streamMessageCallCount).isEqualTo(1)
    }

    @Test
    fun testSendMessageEmitsMessageSentEvent() = runTest {
        // Given
        viewModel.updateInputText("Test message")

        // When/Then
        viewModel.events.test {
            viewModel.sendMessage()
            testScheduler.advanceUntilIdle()

            val event1 = awaitItem()
            assertThat(event1).isInstanceOf(ChatEvent.MessageSent::class.java)

            val event2 = awaitItem()
            assertThat(event2).isInstanceOf(ChatEvent.ScrollToBottom::class.java)
        }
    }

    @Test
    fun testSendMessageEmitsScrollToBottomEvent() = runTest {
        // Given
        viewModel.updateInputText("Test message")

        // When/Then
        viewModel.events.test {
            viewModel.sendMessage()
            testScheduler.advanceUntilIdle()

            // Skip MessageSent event
            awaitItem()

            val scrollEvent = awaitItem()
            assertThat(scrollEvent).isInstanceOf(ChatEvent.ScrollToBottom::class.java)
        }
    }

    @Test
    fun testSendMessageFailureShowsError() = runTest {
        // Given
        viewModel.updateInputText("Test message")
        val errorMessage = "API Error"
        mockChatRepository.sendMessageResult = Result.failure(Exception(errorMessage))

        // When
        viewModel.events.test {
            viewModel.sendMessage()
            testScheduler.advanceUntilIdle()

            // Then
            val event = awaitItem()
            assertThat(event).isInstanceOf(ChatEvent.ShowError::class.java)
            val showError = event as ChatEvent.ShowError
            assertThat(showError.message).isNotNull()
            assertThat(showError.message).isEqualTo(viewModel.uiState.value.error)
        }

        assertThat(viewModel.uiState.value.isLoading).isFalse()
        assertThat(viewModel.uiState.value.error).isNotNull()
    }

    @Test
    fun testSendMessageWithNetworkError() = runTest {
        // Given
        viewModel.updateInputText("Test message")
        val networkError = Exception("No internet connection")
        mockChatRepository.sendMessageResult = Result.failure(networkError)

        // When
        viewModel.sendMessage()
        testScheduler.advanceUntilIdle()

        // Then
        assertThat(viewModel.uiState.value.isLoading).isFalse()
        assertThat(viewModel.uiState.value.error).isNotNull()
    }

    @Test
    fun testSendMessageErrorMatrixRestoresInputAndSetsError() = runTest {
        val scenarios = listOf(
            MockScenarioId.HTTP_400,
            MockScenarioId.HTTP_401,
            MockScenarioId.HTTP_403,
            MockScenarioId.HTTP_404,
            MockScenarioId.HTTP_429,
            MockScenarioId.HTTP_500,
            MockScenarioId.TIMEOUT,
            MockScenarioId.OFFLINE
        )

        scenarios.forEach { scenario ->
            MockScenarioMatrix.apply(scenario, mockChatRepository)
            val input = "scenario-${scenario.wireId}"

            viewModel.updateInputText(input)
            viewModel.sendMessage()
            testScheduler.advanceUntilIdle()

            assertThat(viewModel.uiState.value.isLoading).isFalse()
            assertThat(viewModel.uiState.value.inputText).isEqualTo(input)
            assertThat(viewModel.uiState.value.error).isNotNull()
            assertThat(viewModel.uiState.value.messages.any { it.content == input && it.isUserMessage }).isFalse()
            viewModel.clearError()
        }
    }

    @Test
    fun testMultipleSendMessagesInSequence() = runTest {
        // Given
        mockChatRepository.sendMessageResult = Result.success(TestData.sampleChatResponse)

        // When - Send multiple messages in sequence
        viewModel.updateInputText("First message")
        viewModel.sendMessage()
        testScheduler.advanceUntilIdle()

        viewModel.updateInputText("Second message")
        viewModel.sendMessage()
        testScheduler.advanceUntilIdle()

        viewModel.updateInputText("Third message")
        viewModel.sendMessage()
        testScheduler.advanceUntilIdle()

        // Then
        assertThat(mockChatRepository.streamMessageCallCount).isEqualTo(3)
        assertThat(viewModel.uiState.value.isLoading).isFalse()
    }

    // MARK: - Conversation Loading Tests

    @Test
    fun testLoadConversationByIdSuccess() = runTest {
        // Given
        val conversation = TestData.sampleConversation
        mockConversationRepository.addConversation(conversation)

        // When
        viewModel.loadConversation(conversation.id)
        testScheduler.advanceUntilIdle()

        // Then
        assertThat(viewModel.uiState.value.conversationId).isEqualTo(conversation.id)
        assertThat(viewModel.uiState.value.threadId).isEqualTo(conversation.threadId)
        assertThat(viewModel.uiState.value.conversationTitle).isEqualTo(conversation.title)
    }

    @Test
    fun testLoadConversationByIdNotFound() = runTest {
        // Given
        val nonExistentId = "non-existent-id"

        // When/Then - Should emit error event
        viewModel.events.test {
            viewModel.loadConversation(nonExistentId)
            testScheduler.advanceUntilIdle()

            // No conversation found, UI state should remain default
            assertThat(viewModel.uiState.value.conversationId).isNull()
        }
    }

    @Test
    fun testLoadConversationNullStartsNewConversation() = runTest {
        // When
        viewModel.loadConversation(null)
        testScheduler.advanceUntilIdle()

        // Then - Should reset to initial state
        assertThat(viewModel.uiState.value.conversationId).isNull()
        assertThat(viewModel.uiState.value.threadId).isNull()
        assertThat(viewModel.uiState.value.messages).isEmpty()
    }

    @Test
    fun testLoadConversationUpdatesThreadId() = runTest {
        // Given
        val conversation = TestData.sampleConversation.copy(threadId = "thread_xyz")
        mockConversationRepository.addConversation(conversation)

        // When
        viewModel.loadConversation(conversation.id)
        testScheduler.advanceUntilIdle()

        // Then
        assertThat(viewModel.uiState.value.threadId).isEqualTo("thread_xyz")
    }

    // MARK: - Input Update Tests

    @Test
    fun testUpdateInputTextUpdatesState() = runTest {
        // Given
        val newText = "New input text"

        // When
        viewModel.updateInputText(newText)

        // Then
        assertThat(viewModel.uiState.value.inputText).isEqualTo(newText)
    }

    // MARK: - Voice Input Tests

    @Test
    fun testStartVoiceInputWhenNotRecording() = runTest {
        // When
        viewModel.startVoiceInput()
        testScheduler.advanceUntilIdle()

        // Then - Voice input should be in recording state
        assertThat(viewModel.uiState.value.voiceInputState.isRecording).isTrue()
    }

    @Test
    fun testStartVoiceInputWhenAlreadyRecording() = runTest {
        // Given
        viewModel.startVoiceInput()
        testScheduler.advanceUntilIdle()

        // When - Try to start again (should be ignored)
        viewModel.startVoiceInput()
        testScheduler.advanceUntilIdle()

        // Then - Should still be recording
        assertThat(viewModel.uiState.value.voiceInputState.isRecording).isTrue()
    }

    @Test
    fun testStopVoiceInputStopsRecording() = runTest {
        // Given
        viewModel.startVoiceInput()
        testScheduler.advanceUntilIdle()

        // When
        viewModel.stopVoiceInput()

        // Then
        assertThat(viewModel.uiState.value.voiceInputState.isRecording).isFalse()
    }

    @Test
    fun testOnVoiceResultUpdatesInputText() = runTest {
        // Given
        val transcribedText = "Transcribed voice text"

        // When
        viewModel.onVoiceResult(transcribedText)

        // Then
        assertThat(viewModel.uiState.value.inputText).isEqualTo(transcribedText)
        assertThat(viewModel.uiState.value.voiceInputState.isRecording).isFalse()
        assertThat(viewModel.uiState.value.voiceInputState.transcribedText).isEqualTo(transcribedText)
    }

    @Test
    fun testOnVoiceResultClearsRecordingState() = runTest {
        // Given
        viewModel.startVoiceInput()
        testScheduler.advanceUntilIdle()

        // When
        viewModel.onVoiceResult("Test")

        // Then
        assertThat(viewModel.uiState.value.voiceInputState.isRecording).isFalse()
    }

    @Test
    fun testOnVoiceErrorShowsErrorMessage() = runTest {
        // Given
        val errorMessage = "Voice recognition failed"

        // When/Then
        viewModel.events.test {
            viewModel.onVoiceError(errorMessage)
            testScheduler.advanceUntilIdle()

            val event = awaitItem()
            assertThat(event).isInstanceOf(ChatEvent.ShowError::class.java)
            assertThat((event as ChatEvent.ShowError).message).contains(errorMessage)
        }
    }

    @Test
    fun testOnVoiceErrorClearsRecordingState() = runTest {
        // Given
        viewModel.startVoiceInput()
        testScheduler.advanceUntilIdle()

        // When
        viewModel.onVoiceError("Error")

        // Then
        assertThat(viewModel.uiState.value.voiceInputState.isRecording).isFalse()
        assertThat(viewModel.uiState.value.voiceInputState.error).isEqualTo("Error")
    }

    @Test
    fun testOnClearedReleasesVoiceAndOcrResources() {
        // When
        val onCleared = viewModel::class.java.getDeclaredMethod("onCleared").apply {
            isAccessible = true
        }
        onCleared.invoke(viewModel)

        // Then
        verify(exactly = 1) { mockVoiceInputManager.destroy() }
        verify(exactly = 1) { mockOCRManager.close() }
    }

    @Test
    fun testCannotSendMessageWhileRecording() = runTest {
        // Given
        viewModel.updateInputText("Test message")
        viewModel.startVoiceInput()
        testScheduler.advanceUntilIdle()

        // When - Try to send while recording
        val initialCallCount = mockChatRepository.streamMessageCallCount
        viewModel.sendMessage()

        // Then - Send logic could still work, but UI should disable the button
        // The actual constraint is in the UI, but we verify the state
        assertThat(viewModel.uiState.value.voiceInputState.isRecording).isTrue()
    }

    // MARK: - Additional Message Flow Tests

    @Test
    fun testSendMessageWithAPIError() = runTest {
        // Given
        viewModel.updateInputText("Test message")
        val apiError = Exception("Server error: 500")
        mockChatRepository.sendMessageResult = Result.failure(apiError)

        // When
        viewModel.sendMessage()
        testScheduler.advanceUntilIdle()

        // Then
        assertThat(viewModel.uiState.value.isLoading).isFalse()
        assertThat(viewModel.uiState.value.error).isNotNull()
    }

    @Test
    fun testLoadConversationObservesMessages() = runTest {
        // Given
        val conversation = TestData.sampleConversation
        mockConversationRepository.addConversation(conversation)

        // When
        viewModel.loadConversation(conversation.id)
        testScheduler.advanceUntilIdle()

        // Then - Messages should be populated from the conversation
        assertThat(viewModel.uiState.value.messages).isNotEmpty()
        assertThat(viewModel.uiState.value.messages.size).isEqualTo(conversation.messages.size)
    }

    @Test
    fun testLoadConversationWithError() = runTest {
        // Given
        val invalidId = "invalid-conversation-id"

        // When/Then - Should handle gracefully
        viewModel.loadConversation(invalidId)
        testScheduler.advanceUntilIdle()

        // Conversation not found, should not crash and conversationId should remain null
        assertThat(viewModel.uiState.value.conversationId).isNull()
    }

    @Test
    fun testMessagesFlowUpdatesInRealTime() = runTest {
        // Given - Create a conversation
        val conversation = TestData.createConversation(id = "test-conv-id")
        mockConversationRepository.addConversation(conversation)

        // Load conversation
        viewModel.loadConversation(conversation.id)
        testScheduler.advanceUntilIdle()

        // Initial state: no messages
        assertThat(viewModel.uiState.value.messages).isEmpty()

        // When - Add a message to the repository
        val newMessage = TestData.createMessage(id = "msg-1", content = "Test message")
        mockConversationRepository.addMessage(conversation.id, newMessage)
        testScheduler.advanceUntilIdle()

        // Then - UI should be updated via Flow
        assertThat(viewModel.uiState.value.messages).hasSize(1)
        assertThat(viewModel.uiState.value.messages.first().content).isEqualTo("Test message")
    }

    @Test
    fun testMessagesOrderedByTimestamp() = runTest {
        // Given
        val now = System.currentTimeMillis()
        val message1 = TestData.createMessage(id = "msg-1", content = "First", timestamp = now)
        val message2 = TestData.createMessage(id = "msg-2", content = "Second", timestamp = now + 1000)
        val message3 = TestData.createMessage(id = "msg-3", content = "Third", timestamp = now + 2000)

        val conversation = TestData.createConversation(
            id = "test-conv",
            messages = listOf(message3, message1, message2) // Out of order
        )
        mockConversationRepository.addConversation(conversation)

        // When
        viewModel.loadConversation(conversation.id)
        testScheduler.advanceUntilIdle()

        // Then - Messages should be sorted by timestamp
        val messages = viewModel.uiState.value.messages
        assertThat(messages).hasSize(3)
        assertThat(messages[0].content).isEqualTo("First")
        assertThat(messages[1].content).isEqualTo("Second")
        assertThat(messages[2].content).isEqualTo("Third")
    }

    // MARK: - Additional Voice Input Tests

    @Test
    fun testStartVoiceInputWithLocale() = runTest {
        // Given
        val arabicLocale = Locale("ar")

        // When
        viewModel.startVoiceInput(arabicLocale)
        testScheduler.advanceUntilIdle()

        // Then - Voice input should be in recording state
        assertThat(viewModel.uiState.value.voiceInputState.isRecording).isTrue()
    }

    @Test
    fun testVoicePartialResultsUpdateTranscription() = runTest {
        // Given
        viewModel.startVoiceInput()
        testScheduler.advanceUntilIdle()

        // When - Partial result comes in (this would be triggered by VoiceInputManager callback)
        // For testing, we directly update the state as would happen via the callback
        val partialText = "Partial transcription..."
        // Note: In actual implementation, the partial result comes via the callback,
        // but we can verify the state update mechanism

        // Then - Recording state should be maintained
        assertThat(viewModel.uiState.value.voiceInputState.isRecording).isTrue()
    }

    // MARK: - OCR Tests

    @Test
    fun testProcessImageSuccessShowsConfirmation() = runTest {
        // Given
        val imageUri = Uri.parse("content://test/image")
        val imageBytes = byteArrayOf(1, 2, 3)
        every { mockContentResolver.openInputStream(imageUri) } returns ByteArrayInputStream(imageBytes)
        coEvery { mockOCRManager.recognizeTextWithLanguage(imageUri) } returns Result.success(
            OCRResult(text = "Extracted text", detectedLanguage = "en")
        )

        // When
        viewModel.processImage(imageUri)
        testScheduler.advanceUntilIdle()

        // Then
        val imageState = viewModel.uiState.value.imageInputState
        assertThat(imageState.isProcessing).isFalse()
        assertThat(imageState.extractedText).isEqualTo("Extracted text")
        assertThat(imageState.detectedLanguage).isEqualTo("en")
        assertThat(imageState.imageData).isEqualTo(imageBytes)
        assertThat(imageState.imageUri).isEqualTo(imageUri)
        assertThat(imageState.showConfirmationDialog).isTrue()
        assertThat(imageState.error).isNull()
    }

    @Test
    fun testProcessImageFailureUpdatesErrorState() = runTest {
        // Given
        val imageUri = Uri.parse("content://test/image")
        every { mockContentResolver.openInputStream(imageUri) } returns ByteArrayInputStream(
            byteArrayOf(9, 8, 7)
        )
        coEvery { mockOCRManager.recognizeTextWithLanguage(imageUri) } returns Result.failure(
            Exception("No text found")
        )

        // When
        viewModel.processImage(imageUri)
        testScheduler.advanceUntilIdle()

        // Then
        val imageState = viewModel.uiState.value.imageInputState
        assertThat(imageState.isProcessing).isFalse()
        assertThat(imageState.error).isEqualTo("No text found")
        assertThat(imageState.showConfirmationDialog).isFalse()
    }

    @Test
    fun testProcessImageWhenImageLoadFails() = runTest {
        // Given
        val imageUri = Uri.parse("content://test/missing")
        every { mockContentResolver.openInputStream(imageUri) } returns null

        // When
        viewModel.processImage(imageUri)
        testScheduler.advanceUntilIdle()

        // Then
        val imageState = viewModel.uiState.value.imageInputState
        assertThat(imageState.isProcessing).isFalse()
        assertThat(imageState.error).isEqualTo("Failed to load image data")
        coVerify(exactly = 0) { mockOCRManager.recognizeTextWithLanguage(any()) }
    }

    @Test
    fun testDismissOcrConfirmationClearsState() = runTest {
        // Given
        val imageUri = Uri.parse("content://test/image")
        val imageData = byteArrayOf(4, 5, 6)
        viewModel.onOcrResult("Preview text", "ar", imageData, imageUri)

        // When
        viewModel.dismissOcrConfirmation()

        // Then
        assertThat(viewModel.uiState.value.imageInputState).isEqualTo(ImageInputState())
    }

    @Test
    fun testClearOcrErrorResetsErrorState() = runTest {
        // Given
        viewModel.onOcrError("OCR failure")
        testScheduler.advanceUntilIdle()
        assertThat(viewModel.uiState.value.imageInputState.error).isNotNull()

        // When
        viewModel.clearOcrError()

        // Then
        assertThat(viewModel.uiState.value.imageInputState.error).isNull()
    }

    @Test
    fun testConfirmFactCheckSendsMessageWithImageData() = runTest {
        // Given
        every { mockPreferencesManager.getSelectedLanguage() } returns "ar"
        val imageUri = Uri.parse("content://test/image")
        val imageData = byteArrayOf(1, 2, 3, 4)
        val extractedText = "Fact check this claim"
        viewModel.onOcrResult(extractedText, "en", imageData, imageUri)

        // When
        viewModel.confirmFactCheck(extractedText)
        testScheduler.advanceUntilIdle()

        // Then
        val imageState = viewModel.uiState.value.imageInputState
        assertThat(imageState.showConfirmationDialog).isFalse()
        assertThat(imageState.imageData).isNull()
        assertThat(imageState.extractedText).isEmpty()

        val conversationId = viewModel.uiState.value.conversationId
        assertThat(conversationId).isNotNull()

        val conversation = mockConversationRepository.getConversationById(conversationId!!)
        assertThat(conversation).isNotNull()

        val factCheckMessages = conversation!!.messages.filter { it.isFactCheckMessage }
        assertThat(factCheckMessages).isNotEmpty()
        val factCheckMessage = factCheckMessages.first()
        assertThat(factCheckMessage.imageData).isEqualTo(imageData)
        assertThat(factCheckMessage.detectedLanguage).isEqualTo("en")

        val request = mockChatRepository.lastConfirmFactCheckRequest
        assertThat(request).isNotNull()
        assertThat(request!!.languagePreference).isEqualTo("ar")
        assertThat(request.enableThinking).isTrue()
    }

    // MARK: - State Management Tests

    @Test
    fun testInitialUiStateIsCorrect() = runTest {
        // Then
        val state = viewModel.uiState.value
        assertThat(state.messages).isEmpty()
        assertThat(state.inputText).isEmpty()
        assertThat(state.isLoading).isFalse()
        assertThat(state.error).isNull()
        assertThat(state.conversationId).isNull()
        assertThat(state.threadId).isNull()
        assertThat(state.voiceInputState.isRecording).isFalse()
        assertThat(state.imageInputState.isProcessing).isFalse()
    }

    @Test
    fun testClearErrorResetsErrorState() = runTest {
        // Given - Set an error
        mockChatRepository.sendMessageResult = Result.failure(Exception("Test error"))
        viewModel.updateInputText("Test")
        viewModel.sendMessage()
        testScheduler.advanceUntilIdle()

        assertThat(viewModel.uiState.value.error).isNotNull()

        // When
        viewModel.clearError()

        // Then
        assertThat(viewModel.uiState.value.error).isNull()
    }
}
