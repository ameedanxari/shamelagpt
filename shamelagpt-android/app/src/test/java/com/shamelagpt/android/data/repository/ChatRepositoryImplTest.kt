package com.shamelagpt.android.data.repository

import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.core.network.NetworkError
import com.shamelagpt.android.data.remote.datasource.ChatRemoteDataSource
import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.HealthResponse
import com.shamelagpt.android.mock.MockConversationRepository
import com.shamelagpt.android.mock.MockScenarioId
import com.shamelagpt.android.mock.TestData
import com.shamelagpt.android.util.MainCoroutineRule
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test

/**
 * Unit tests for ChatRepositoryImpl.
 * Tests the integration between API calls and local storage.
 */
@ExperimentalCoroutinesApi
class ChatRepositoryImplTest {

    @get:Rule
    val mainCoroutineRule = MainCoroutineRule()

    private lateinit var chatRepository: ChatRepositoryImpl
    private lateinit var mockRemoteDataSource: ChatRemoteDataSource
    private lateinit var mockConversationRepository: MockConversationRepository

    @Before
    fun setup() {
        mockRemoteDataSource = mockk()
        mockConversationRepository = MockConversationRepository()
        chatRepository = ChatRepositoryImpl(
            chatRemoteDataSource = mockRemoteDataSource,
            conversationRepository = mockConversationRepository
        )
    }

    @After
    fun tearDown() {
        mockConversationRepository.reset()
    }

    // MARK: - Send Message Tests

    @Test
    fun testSendMessageSuccess() = runTest {
        // Given
        val question = "What is prayer?"
        val conversationId = "conv-123"
        val threadId = null
        val response = TestData.sampleChatResponse

        // Create conversation first
        mockConversationRepository.addConversation(
            TestData.createConversation(id = conversationId)
        )

        coEvery {
            mockRemoteDataSource.sendMessage(question, threadId)
        } returns Result.success(response)

        // When
        val result = chatRepository.sendMessage(question, conversationId, threadId)

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(response)

        // Verify messages were saved (user + AI)
        val messages = mockConversationRepository.getConversationById(conversationId)?.messages
        assertThat(messages).isNotNull()
        assertThat(messages?.size).isEqualTo(2) // User message + AI response
    }

    @Test
    fun testSendMessageCreatesUserMessage() = runTest {
        // Given
        val question = "Test question"
        val conversationId = "conv-123"
        val response = TestData.sampleChatResponse

        // Create conversation first
        mockConversationRepository.addConversation(
            TestData.createConversation(id = conversationId)
        )

        coEvery {
            mockRemoteDataSource.sendMessage(any(), any())
        } returns Result.success(response)

        // When
        chatRepository.sendMessage(question, conversationId, null, saveUserMessage = true)

        // Then
        val messages = mockConversationRepository.getConversationById(conversationId)?.messages
        val userMessage = messages?.firstOrNull { it.isUserMessage }

        assertThat(userMessage).isNotNull()
        assertThat(userMessage?.content).isEqualTo(question)
        assertThat(userMessage?.isUserMessage).isTrue()
        assertThat(userMessage?.sources).isNull()
    }

    @Test
    fun testSendMessageCreatesAssistantMessage() = runTest {
        // Given
        val question = "Test question"
        val conversationId = "conv-123"
        val response = ChatResponse(
            answer = "This is the answer.\n\nSources:\n\n* **book_name:** Test Book, **source_url:** https://test.com",
            threadId = "thread-123"
        )

        // Create conversation first
        mockConversationRepository.addConversation(
            TestData.createConversation(id = conversationId)
        )

        coEvery {
            mockRemoteDataSource.sendMessage(any(), any())
        } returns Result.success(response)

        // When
        chatRepository.sendMessage(question, conversationId, null)

        // Then
        val messages = mockConversationRepository.getConversationById(conversationId)?.messages
        val aiMessage = messages?.firstOrNull { !it.isUserMessage }

        assertThat(aiMessage).isNotNull()
        assertThat(aiMessage?.isUserMessage).isFalse()
        assertThat(aiMessage?.content).contains("This is the answer")
        assertThat(aiMessage?.sources).isNotNull()
    }

    @Test
    fun testSendMessageParsesResponse() = runTest {
        // Given
        val question = "Test"
        val conversationId = "conv-123"
        val answerWithSources = """
            Clean content here.

            Sources:

            * **book_name:** Book One, **source_url:** https://shamela.ws/book/1/1
            * **book_name:** Book Two, **source_url:** https://shamela.ws/book/2/2
        """.trimIndent()

        val response = ChatResponse(answer = answerWithSources, threadId = "thread-123")

        // Create conversation first
        mockConversationRepository.addConversation(
            TestData.createConversation(id = conversationId)
        )

        coEvery {
            mockRemoteDataSource.sendMessage(any(), any())
        } returns Result.success(response)

        // When
        chatRepository.sendMessage(question, conversationId, null)

        // Then
        val messages = mockConversationRepository.getConversationById(conversationId)?.messages
        val aiMessage = messages?.firstOrNull { !it.isUserMessage }

        assertThat(aiMessage?.content).isEqualTo("Clean content here.")
        assertThat(aiMessage?.sources).hasSize(2)
        assertThat(aiMessage?.sources?.get(0)?.bookName).isEqualTo("Book One")
    }

    @Test
    fun testSendMessageExtractsSources() = runTest {
        // Given
        val question = "Test"
        val conversationId = "conv-123"
        val answerWithSources = """
            Prayer is one of the five pillars of Islam.

            Sources:

            * **book_name:** صحيح البخاري, **source_url:** https://shamela.ws/book/1234/56
            * **book_name:** صحيح مسلم, **source_url:** https://shamela.ws/book/5678/90
        """.trimIndent()
        val response = TestData.createChatResponse(
            answer = answerWithSources,
            threadId = "thread-123"
        )

        // Create conversation first
        mockConversationRepository.addConversation(
            TestData.createConversation(id = conversationId)
        )

        coEvery {
            mockRemoteDataSource.sendMessage(any(), any())
        } returns Result.success(response)

        // When
        chatRepository.sendMessage(question, conversationId, null)

        // Then
        val messages = mockConversationRepository.getConversationById(conversationId)?.messages
        val aiMessage = messages?.firstOrNull { !it.isUserMessage }

        assertThat(aiMessage?.sources).isNotNull()
        assertThat(aiMessage?.sources?.size).isGreaterThan(0)
    }

    @Test
    fun testSendMessageUpdatesThreadId() = runTest {
        // Given
        val question = "Test"
        val conversationId = "conv-123"
        val expectedThreadId = "thread-xyz-789"
        val response = TestData.createChatResponse(threadId = expectedThreadId)

        // Create conversation first
        mockConversationRepository.addConversation(
            TestData.createConversation(id = conversationId)
        )

        coEvery {
            mockRemoteDataSource.sendMessage(any(), any())
        } returns Result.success(response)

        // When
        chatRepository.sendMessage(question, conversationId, null)

        // Then
        val conversation = mockConversationRepository.getConversationById(conversationId)
        assertThat(conversation?.threadId).isEqualTo(expectedThreadId)
    }

    @Test
    fun testSendMessageWithSaveUserMessageFalse() = runTest {
        // Given
        val question = "Fact-check question"
        val conversationId = "conv-123"
        val response = TestData.sampleChatResponse

        // Create conversation first
        mockConversationRepository.addConversation(
            TestData.createConversation(id = conversationId)
        )

        coEvery {
            mockRemoteDataSource.sendMessage(any(), any())
        } returns Result.success(response)

        // When
        chatRepository.sendMessage(question, conversationId, null, saveUserMessage = false)

        // Then
        val messages = mockConversationRepository.getConversationById(conversationId)?.messages
        val userMessages = messages?.filter { it.isUserMessage }

        // Should NOT have created a user message
        assertThat(userMessages).isEmpty()

        // Should still have AI message
        val aiMessages = messages?.filter { !it.isUserMessage }
        assertThat(aiMessages).hasSize(1)
    }

    @Test
    fun testSendMessageWithNetworkError() = runTest {
        // Given
        val question = "Test"
        val conversationId = "conv-123"
        val error = Exception("Network error")

        // Create conversation first
        mockConversationRepository.addConversation(
            TestData.createConversation(id = conversationId)
        )

        coEvery {
            mockRemoteDataSource.sendMessage(any(), any())
        } returns Result.failure(error)

        // When
        val result = chatRepository.sendMessage(question, conversationId, null)

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isEqualTo(error)

        // User message should still be saved even though API failed
        val messages = mockConversationRepository.getConversationById(conversationId)?.messages
        assertThat(messages).hasSize(1) // Only user message
        assertThat(messages?.first()?.isUserMessage).isTrue()
    }

    @Test
    fun testSendMessageWithApiError() = runTest {
        // Given
        val question = "Test"
        val conversationId = "conv-123"
        val apiError = RuntimeException("API returned 500")

        coEvery {
            mockRemoteDataSource.sendMessage(any(), any())
        } returns Result.failure(apiError)

        // When
        val result = chatRepository.sendMessage(question, conversationId, null)

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()?.message).contains("API returned 500")
    }

    @Test
    fun testSendMessageWithFullErrorMatrix() = runTest {
        // Given
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
            val expectedError = when (scenario) {
                MockScenarioId.HTTP_400 -> NetworkError.HttpError(400)
                MockScenarioId.HTTP_401 -> NetworkError.HttpError(401)
                MockScenarioId.HTTP_403 -> NetworkError.HttpError(403)
                MockScenarioId.HTTP_404 -> NetworkError.HttpError(404)
                MockScenarioId.HTTP_429 -> NetworkError.HttpError(429)
                MockScenarioId.HTTP_500 -> NetworkError.HttpError(500)
                MockScenarioId.TIMEOUT -> NetworkError.Timeout
                MockScenarioId.OFFLINE -> NetworkError.NoConnection
                MockScenarioId.SUCCESS -> error("Success scenario is not part of failure matrix")
            }
            val conversationId = "conv-${scenario.wireId}"
            mockConversationRepository.addConversation(TestData.createConversation(id = conversationId))

            coEvery {
                mockRemoteDataSource.sendMessage(any(), any())
            } returns Result.failure(expectedError)

            // When
            val result = chatRepository.sendMessage("Test", conversationId, null)

            // Then
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

            // User message should still be saved on failures.
            val messages = mockConversationRepository.getConversationById(conversationId)?.messages
            assertThat(messages).hasSize(1)
            assertThat(messages?.first()?.isUserMessage).isTrue()
        }
    }

    // MARK: - Check Health Tests

    @Test
    fun testCheckHealthSuccess() = runTest {
        // Given
        val healthResponse = HealthResponse(status = "healthy", service = "ShamelaGPT")

        coEvery {
            mockRemoteDataSource.checkHealth()
        } returns Result.success(healthResponse)

        // When
        val result = chatRepository.checkHealth()

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(healthResponse)
    }

    @Test
    fun testCheckHealthFailure() = runTest {
        // Given
        val error = Exception("Health check failed")

        coEvery {
            mockRemoteDataSource.checkHealth()
        } returns Result.failure(error)

        // When
        val result = chatRepository.checkHealth()

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isEqualTo(error)
    }
}
