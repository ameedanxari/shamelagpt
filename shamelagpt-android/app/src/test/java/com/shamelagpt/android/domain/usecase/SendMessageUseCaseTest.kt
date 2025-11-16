package com.shamelagpt.android.domain.usecase

import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.core.network.NetworkError
import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.mock.MockChatRepository
import com.shamelagpt.android.mock.MockConversationRepository
import com.shamelagpt.android.mock.MockScenarioId
import com.shamelagpt.android.mock.MockScenarioMatrix
import com.shamelagpt.android.mock.TestData
import com.shamelagpt.android.util.MainCoroutineRule
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import java.util.Locale
import java.util.UUID

/**
 * Unit tests for SendMessageUseCase.
 */
@ExperimentalCoroutinesApi
class SendMessageUseCaseTest {

    @get:Rule
    val mainCoroutineRule = MainCoroutineRule()

    private lateinit var chatRepository: MockChatRepository
    private lateinit var conversationRepository: MockConversationRepository
    private lateinit var useCase: SendMessageUseCase

    @Before
    fun setup() {
        chatRepository = MockChatRepository()
        conversationRepository = MockConversationRepository()
        useCase = SendMessageUseCase(chatRepository, conversationRepository)
    }

    @After
    fun tearDown() {
        chatRepository.reset()
        conversationRepository.reset()
    }

    @Test
    fun testInvokeWithValidMessage() = runTest {
        // Given
        val question = "What is the ruling on prayer?"
        val conversationId = UUID.randomUUID().toString()
        val threadId = "thread_123"

        // When
        val result = useCase.invoke(question, conversationId, threadId)

        // Then
        assertThat(result.isSuccess).isTrue()
        val (response, returnedConversationId) = result.getOrThrow()
        assertThat(response).isEqualTo(TestData.sampleChatResponse)
        assertThat(returnedConversationId).isEqualTo(conversationId)
        assertThat(chatRepository.sendMessageCallCount).isEqualTo(1)
        assertThat(chatRepository.lastQuestion).isEqualTo(question)
        assertThat(chatRepository.lastThreadId).isEqualTo(threadId)
    }

    @Test
    fun testInvokePassesLanguagePreferenceFromLocaleWhenNotProvided() = runTest {
        // Given
        val originalLocale = Locale.getDefault()
        Locale.setDefault(Locale("ar"))

        val question = "Language check"
        val conversationId = UUID.randomUUID().toString()

        // When
        useCase.invoke(question, conversationId, threadId = null)

        // Then
        assertThat(chatRepository.lastLanguagePreference).isEqualTo("ar")

        // Reset locale to avoid affecting other tests
        Locale.setDefault(originalLocale)
    }

    @Test
    fun testInvokeCreatesNewConversationWhenIdIsNull() = runTest {
        // Given
        val question = "What is the ruling on prayer?"
        val threadId = null

        // When
        val result = useCase.invoke(question, conversationId = null, threadId)

        // Then
        assertThat(result.isSuccess).isTrue()
        val (_, conversationId) = result.getOrThrow()
        assertThat(conversationId).isNotEmpty()
        assertThat(conversationRepository.getConversationCount()).isEqualTo(1)
    }

    @Test
    fun testInvokeUsesExistingConversationWhenIdProvided() = runTest {
        // Given
        val existingConversation = TestData.sampleConversation
        conversationRepository.addConversation(existingConversation)
        val question = "Follow-up question"

        // When
        val result = useCase.invoke(question, existingConversation.id, existingConversation.threadId)

        // Then
        assertThat(result.isSuccess).isTrue()
        val (_, conversationId) = result.getOrThrow()
        assertThat(conversationId).isEqualTo(existingConversation.id)
        // Should not create a new conversation
        assertThat(conversationRepository.getConversationCount()).isEqualTo(1)
    }

    @Test
    fun testInvokeReturnsConversationId() = runTest {
        // Given
        val question = "Test question"
        val conversationId = UUID.randomUUID().toString()

        // When
        val result = useCase.invoke(question, conversationId, null)

        // Then
        assertThat(result.isSuccess).isTrue()
        val (_, returnedId) = result.getOrThrow()
        assertThat(returnedId).isEqualTo(conversationId)
    }

    @Test
    fun testInvokeGeneratesConversationTitle() = runTest {
        // Given
        val question = "What is the ruling on prayer?"

        // When
        val result = useCase.invoke(question, conversationId = null, threadId = null)

        // Then
        assertThat(result.isSuccess).isTrue()
        val (_, conversationId) = result.getOrThrow()
        val conversation = conversationRepository.getConversationById(conversationId)
        assertThat(conversation).isNotNull()
        assertThat(conversation?.title).isEqualTo(question)
    }

    @Test
    fun testInvokeTruncatesTitleOver50Chars() = runTest {
        // Given
        val longQuestion = "This is a very long question that exceeds fifty characters and should be truncated properly"

        // When
        val result = useCase.invoke(longQuestion, conversationId = null, threadId = null)

        // Then
        assertThat(result.isSuccess).isTrue()
        val (_, conversationId) = result.getOrThrow()
        val conversation = conversationRepository.getConversationById(conversationId)
        assertThat(conversation).isNotNull()
        assertThat(conversation?.title?.length).isAtMost(53) // 50 chars + "..."
        assertThat(conversation?.title).endsWith("...")
    }

    @Test
    fun testInvokePassesThreadIdToRepository() = runTest {
        // Given
        val question = "Test question"
        val conversationId = UUID.randomUUID().toString()
        val threadId = "thread_abc123"

        // When
        useCase.invoke(question, conversationId, threadId)

        // Then
        assertThat(chatRepository.lastThreadId).isEqualTo(threadId)
    }

    @Test
    fun testInvokeWithSaveUserMessageTrue() = runTest {
        // Given
        val question = "Test question"
        val conversationId = UUID.randomUUID().toString()

        // When
        useCase.invoke(question, conversationId, null, saveUserMessage = true)

        // Then
        assertThat(chatRepository.lastSaveUserMessage).isTrue()
    }

    @Test
    fun testInvokeWithSaveUserMessageFalse() = runTest {
        // Given
        val question = "Test question"
        val conversationId = UUID.randomUUID().toString()

        // When
        useCase.invoke(question, conversationId, null, saveUserMessage = false)

        // Then
        assertThat(chatRepository.lastSaveUserMessage).isFalse()
    }

    @Test
    fun testInvokeWithEmptyQuestion() = runTest {
        // Given
        val emptyQuestion = ""
        val conversationId = UUID.randomUUID().toString()

        // When
        val result = useCase.invoke(emptyQuestion, conversationId, null)

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(IllegalArgumentException::class.java)
        assertThat(result.exceptionOrNull()?.message).isEqualTo("Question cannot be empty")
    }

    @Test
    fun testInvokeWithBlankQuestion() = runTest {
        // Given
        val blankQuestion = "   \n\t   "
        val conversationId = UUID.randomUUID().toString()

        // When
        val result = useCase.invoke(blankQuestion, conversationId, null)

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(IllegalArgumentException::class.java)
    }

    @Test
    fun testInvokeWithRepositoryError() = runTest {
        // Given
        val question = "Test question"
        val conversationId = UUID.randomUUID().toString()
        val error = RuntimeException("API Error")
        chatRepository.sendMessageResult = Result.failure(error)

        // When
        val result = useCase.invoke(question, conversationId, null)

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isEqualTo(error)
    }

    @Test
    fun testInvokeWithNetworkError() = runTest {
        // Given
        val question = "Test question"
        val conversationId = UUID.randomUUID().toString()
        val networkError = Exception("No internet connection")
        chatRepository.sendMessageResult = Result.failure(networkError)

        // When
        val result = useCase.invoke(question, conversationId, null)

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()?.message).contains("No internet connection")
    }

    @Test
    fun testInvokeWithFullErrorMatrix() = runTest {
        // Given
        val question = "Test question"
        val conversationId = UUID.randomUUID().toString()
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

        // When/Then
        scenarios.forEach { scenario ->
            MockScenarioMatrix.apply(scenario, chatRepository)
            val expectedError = chatRepository.sendMessageResult.exceptionOrNull()!!

            val result = useCase.invoke(question, conversationId, null)

            assertThat(result.isFailure).isTrue()
            val actualError = result.exceptionOrNull()
            when (expectedError) {
                is NetworkError.HttpError -> {
                    assertThat(actualError).isInstanceOf(NetworkError.HttpError::class.java)
                    assertThat((actualError as NetworkError.HttpError).code).isEqualTo(expectedError.code)
                }
                NetworkError.Timeout -> assertThat(actualError).isEqualTo(NetworkError.Timeout)
                NetworkError.NoConnection -> assertThat(actualError).isEqualTo(NetworkError.NoConnection)
                else -> assertThat(actualError).isEqualTo(expectedError)
            }
        }
    }

    @Test
    fun testGenerateTitleFromShortMessage() = runTest {
        // Given
        val shortQuestion = "Short question"

        // When
        val result = useCase.invoke(shortQuestion, conversationId = null, threadId = null)

        // Then
        val (_, conversationId) = result.getOrThrow()
        val conversation = conversationRepository.getConversationById(conversationId)
        assertThat(conversation?.title).isEqualTo("Short question")
    }

    @Test
    fun testGenerateTitleFromLongMessage() = runTest {
        // Given
        val longQuestion = "A".repeat(100)

        // When
        val result = useCase.invoke(longQuestion, conversationId = null, threadId = null)

        // Then
        val (_, conversationId) = result.getOrThrow()
        val conversation = conversationRepository.getConversationById(conversationId)
        assertThat(conversation?.title?.length).isEqualTo(53) // 50 + "..."
    }

    @Test
    fun testGenerateTitleTrimsWhitespace() = runTest {
        // Given
        val questionWithWhitespace = "   Question with whitespace   "

        // When
        val result = useCase.invoke(questionWithWhitespace, conversationId = null, threadId = null)

        // Then
        val (_, conversationId) = result.getOrThrow()
        val conversation = conversationRepository.getConversationById(conversationId)
        assertThat(conversation?.title).isEqualTo("Question with whitespace")
    }

    @Test
    fun testGenerateTitleAddsEllipsis() = runTest {
        // Given
        val longQuestion = "This is exactly fifty characters for title test!x"

        // When
        val result = useCase.invoke(longQuestion, conversationId = null, threadId = null)

        // Then
        val (_, conversationId) = result.getOrThrow()
        val conversation = conversationRepository.getConversationById(conversationId)
        // If truncated, should have ellipsis
        if (conversation?.title?.length!! > 50) {
            assertThat(conversation.title).endsWith("...")
        }
    }
}
