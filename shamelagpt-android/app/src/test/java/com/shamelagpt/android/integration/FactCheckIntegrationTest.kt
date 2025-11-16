package com.shamelagpt.android.integration

import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.domain.usecase.SendMessageUseCase
import com.shamelagpt.android.mock.MockChatRepository
import com.shamelagpt.android.mock.MockConversationRepository
import com.shamelagpt.android.mock.TestData
import com.shamelagpt.android.util.MainCoroutineRule
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test

/**
 * Integration tests for fact-check flow.
 * Tests OCR → Confirmation → API → Persistence flow.
 * Maintains parity with iOS FactCheckIntegrationTests (4 tests).
 */
@ExperimentalCoroutinesApi
class FactCheckIntegrationTest {

    @get:Rule
    val mainCoroutineRule = MainCoroutineRule()

    private lateinit var mockChatRepository: MockChatRepository
    private lateinit var mockConversationRepository: MockConversationRepository
    private lateinit var sendMessageUseCase: SendMessageUseCase

    @Before
    fun setup() {
        mockConversationRepository = MockConversationRepository()
        mockChatRepository = MockChatRepository(mockConversationRepository)
        sendMessageUseCase = SendMessageUseCase(
            chatRepository = mockChatRepository,
            conversationRepository = mockConversationRepository
        )
    }

    @After
    fun tearDown() {
        mockChatRepository.reset()
        mockConversationRepository.reset()
    }

    @Test
    fun testCompleteFactCheckFlow() = runTest {
        // Given - User uploads image, OCR extracts text, confirms, and sends
        val extractedText = "الصلاة عماد الدين"
        val factCheckPrompt = "Please fact-check this statement: $extractedText"

        mockChatRepository.sendMessageResult = Result.success(
            TestData.createChatResponse(
                answer = "This is an authentic saying. It means prayer is the pillar of religion.",
                threadId = "fact-check-thread"
            )
        )

        // When - Send fact-check message
        val result = sendMessageUseCase(
            question = factCheckPrompt,
            conversationId = null,
            threadId = null,
            saveUserMessage = true
        )
        testScheduler.advanceUntilIdle()

        // Then - Complete flow should succeed
        assertThat(result.isSuccess).isTrue()

        val (response, conversationId) = result.getOrThrow()
        assertThat(response.answer).contains("authentic")

        // Verify conversation was created
        val conversation = mockConversationRepository.getConversationById(conversationId)
        assertThat(conversation).isNotNull()
        assertThat(conversation!!.messages).hasSize(2) // User + Assistant
    }

    @Test
    fun testFactCheckMessageWithImageData() = runTest {
        // Given - Fact-check message with image data attached
        val extractedText = "Verily actions are by intentions"
        val imageData = byteArrayOf(1, 2, 3, 4, 5) // Mock image data

        // Manually create user message with image data (simulating ViewModel behavior)
        val conversation = mockConversationRepository.createConversation("Fact Check")
        val userMessage = TestData.createMessage(
            content = extractedText,
            isUserMessage = true,
            imageData = imageData,
            isFactCheckMessage = true
        )
        mockConversationRepository.saveMessage(userMessage, conversation.id)

        // Send API request without saving user message again
        mockChatRepository.sendMessageResult = Result.success(
            TestData.createChatResponse(answer = "This is an authentic hadith from Sahih Bukhari.")
        )

        val result = sendMessageUseCase(
            question = "Please fact-check this statement: $extractedText",
            conversationId = conversation.id,
            threadId = null,
            saveUserMessage = false // Already saved with metadata
        )

        // Then - Image data should be persisted
        assertThat(result.isSuccess).isTrue()

        val updatedConversation = mockConversationRepository.getConversationById(conversation.id)
        val factCheckMessage = updatedConversation!!.messages.first { it.isFactCheckMessage }

        assertThat(factCheckMessage.imageData).isNotNull()
        assertThat(factCheckMessage.imageData).isEqualTo(imageData)
    }

    @Test
    fun testFactCheckMessageWithLanguage() = runTest {
        // Given - Fact-check with detected language
        val extractedText = "الله أكبر"
        val detectedLanguage = "ar"

        val conversation = mockConversationRepository.createConversation("Arabic Fact Check")
        val userMessage = TestData.createMessage(
            content = extractedText,
            isUserMessage = true,
            detectedLanguage = detectedLanguage,
            isFactCheckMessage = true
        )
        mockConversationRepository.saveMessage(userMessage, conversation.id)

        mockChatRepository.sendMessageResult = Result.success(
            TestData.createChatResponse(answer = "This is the Takbir, meaning 'Allah is the Greatest'.")
        )

        // When
        val result = sendMessageUseCase(
            question = "Please fact-check this statement: $extractedText",
            conversationId = conversation.id,
            threadId = null,
            saveUserMessage = false
        )

        // Then - Language should be persisted
        assertThat(result.isSuccess).isTrue()

        val updatedConversation = mockConversationRepository.getConversationById(conversation.id)
        val factCheckMessage = updatedConversation!!.messages.first { it.isFactCheckMessage }

        assertThat(factCheckMessage.detectedLanguage).isEqualTo("ar")
    }

    @Test
    fun testFactCheckAPICallFormatted() = runTest {
        // Given - User confirms extracted text for fact-checking
        val extractedText = "Prayer is better than sleep"
        val expectedPrompt = "Please fact-check this statement: $extractedText"

        mockChatRepository.sendMessageResult = Result.success(
            TestData.sampleChatResponse
        )

        // When - Send fact-check via use case
        val result = sendMessageUseCase(
            question = expectedPrompt,
            conversationId = null,
            threadId = null
        )

        // Then - API should be called with correctly formatted prompt
        assertThat(result.isSuccess).isTrue()
        assertThat(mockChatRepository.lastQuestion).isEqualTo(expectedPrompt)
        assertThat(mockChatRepository.lastQuestion).contains("fact-check")
    }
}
