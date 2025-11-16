package com.shamelagpt.android.integration

import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.domain.usecase.SendMessageUseCase
import com.shamelagpt.android.mock.MockChatRepository
import com.shamelagpt.android.mock.MockConversationRepository
import com.shamelagpt.android.mock.MockScenarioId
import com.shamelagpt.android.mock.MockScenarioMatrix
import com.shamelagpt.android.mock.TestData
import com.shamelagpt.android.testing.TestDiagnosticEvent
import com.shamelagpt.android.testing.TestDiagnostics
import com.shamelagpt.android.util.MainCoroutineRule
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test

/**
 * Integration tests for network error recovery.
 * Tests error handling and retry mechanisms.
 * Maintains parity with iOS NetworkErrorRecoveryTests (5 tests including 2 bonus).
 */
@ExperimentalCoroutinesApi
class NetworkErrorRecoveryTest {

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
    fun testRecoveryAfterNetworkError() = runTest {
        // Given - First attempt fails with network error
        val question = "What is Islam?"
        mockChatRepository.sendMessageResult = Result.failure(
            Exception("Network error: No internet connection")
        )

        // When - First attempt
        val firstResult = sendMessageUseCase(
            question = question,
            conversationId = null,
            threadId = null
        )

        // Then - Should fail
        TestDiagnostics.assertWithDiagnostics(
            condition = firstResult.isFailure,
            event = TestDiagnosticEvent(
                testName = "testRecoveryAfterNetworkError",
                platform = "android_unit_test",
                locale = "en",
                selectorOrTag = "SendMessageUseCase.invoke",
                scenarioId = "offline",
                observedState = "expected_failure_missing",
                failureClass = "contract_mismatch"
            ),
            assertionMessage = "Expected first attempt to fail for offline scenario"
        )
        assertThat(firstResult.exceptionOrNull()?.message).contains("Network error")

        // Given - Network is restored
        mockChatRepository.sendMessageResult = Result.success(TestData.sampleChatResponse)

        // When - Retry
        val retryResult = sendMessageUseCase(
            question = question,
            conversationId = null,
            threadId = null
        )

        // Then - Should succeed
        assertThat(retryResult.isSuccess).isTrue()
        assertThat(mockChatRepository.sendMessageCallCount).isEqualTo(2)
    }

    @Test
    fun testOfflineModeMessageQueuing() = runTest {
        // Given - User tries to send message while offline
        val question = "What is prayer?"
        mockChatRepository.sendMessageResult = Result.failure(
            Exception("No internet connection")
        )

        val conversation = mockConversationRepository.createConversation("Test")

        // When - Attempt to send while offline
        val result = sendMessageUseCase(
            question = question,
            conversationId = conversation.id,
            threadId = null
        )
        testScheduler.advanceUntilIdle()

        // Then - Message should fail but user message is still saved
        assertThat(result.isFailure).isTrue()

        // Verify user message was saved despite network failure
        val updatedConversation = mockConversationRepository.getConversationById(conversation.id)
        val userMessages = updatedConversation!!.messages.filter { it.isUserMessage }
        assertThat(userMessages).hasSize(1)
        assertThat(userMessages.first().content).isEqualTo(question)
    }

    @Test
    fun testReconnectionResendsPendingMessages() = runTest {
        // Given - Message sent while offline
        val question = "Explain Ramadan"
        mockChatRepository.sendMessageResult = Result.failure(
            Exception("Network timeout")
        )

        // Attempt 1: Fail
        val failedResult = sendMessageUseCase(
            question = question,
            conversationId = null,
            threadId = null
        )

        assertThat(failedResult.isFailure).isTrue()

        // Given - Network restored
        mockChatRepository.sendMessageResult = Result.success(
            TestData.createChatResponse(answer = "Ramadan is the month of fasting...")
        )

        // When - Retry the same message
        val successResult = sendMessageUseCase(
            question = question,
            conversationId = null,
            threadId = null
        )

        // Then - Should succeed on retry
        assertThat(successResult.isSuccess).isTrue()
        val (response, _) = successResult.getOrThrow()
        assertThat(response.answer).contains("Ramadan")
    }

    @Test
    fun testMultipleNetworkFailuresWithRecovery() = runTest {
        // Given - Simulate intermittent network issues
        val question = "What is Hajj?"

        // Attempt 1: Network error
        mockChatRepository.sendMessageResult = Result.failure(Exception("Network error"))
        val attempt1 = sendMessageUseCase(question, null, null)
        assertThat(attempt1.isFailure).isTrue()

        // Attempt 2: Timeout error
        mockChatRepository.sendMessageResult = Result.failure(Exception("Request timeout"))
        val attempt2 = sendMessageUseCase(question, null, null)
        assertThat(attempt2.isFailure).isTrue()

        // Attempt 3: Server error
        mockChatRepository.sendMessageResult = Result.failure(Exception("Server error: 500"))
        val attempt3 = sendMessageUseCase(question, null, null)
        assertThat(attempt3.isFailure).isTrue()

        // Attempt 4: Finally succeeds
        mockChatRepository.sendMessageResult = Result.success(
            TestData.createChatResponse(answer = "Hajj is the pilgrimage to Mecca...")
        )
        val attempt4 = sendMessageUseCase(question, null, null)

        // Then - Should succeed after multiple failures
        assertThat(attempt4.isSuccess).isTrue()
        assertThat(mockChatRepository.sendMessageCallCount).isEqualTo(4)
    }

    @Test
    fun testAPITimeoutRecovery() = runTest {
        // Given - API timeout on first attempt
        val question = "Explain Zakat"
        mockChatRepository.sendMessageResult = Result.failure(
            Exception("API timeout: Request took too long")
        )

        // When - First attempt times out
        val timeoutResult = sendMessageUseCase(
            question = question,
            conversationId = null,
            threadId = null
        )

        // Then - Should fail with timeout
        TestDiagnostics.assertWithDiagnostics(
            condition = timeoutResult.isFailure,
            event = TestDiagnosticEvent(
                testName = "testAPITimeoutRecovery",
                platform = "android_unit_test",
                locale = "en",
                selectorOrTag = "SendMessageUseCase.invoke",
                scenarioId = "timeout",
                observedState = "expected_timeout_failure_missing",
                failureClass = "contract_mismatch"
            ),
            assertionMessage = "Expected timeout attempt to fail for timeout scenario"
        )
        assertThat(timeoutResult.exceptionOrNull()?.message).contains("timeout")

        // Given - Retry with normal response time
        mockChatRepository.sendMessageResult = Result.success(
            TestData.createChatResponse(answer = "Zakat is the obligatory charity...")
        )

        // When - Retry
        val retryResult = sendMessageUseCase(
            question = question,
            conversationId = null,
            threadId = null
        )

        // Then - Should succeed
        assertThat(retryResult.isSuccess).isTrue()
        assertThat(retryResult.getOrThrow().first.answer).contains("Zakat")
    }

    @Test
    fun testSendMessageUseCaseErrorMatrixReturnsFailureAndPersistsUserMessage() = runTest {
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
            val conversation = mockConversationRepository.createConversation("Matrix ${scenario.wireId}")
            MockScenarioMatrix.apply(scenario, mockChatRepository)

            val result = sendMessageUseCase(
                question = "Failure scenario ${scenario.wireId}",
                conversationId = conversation.id,
                threadId = null
            )
            testScheduler.advanceUntilIdle()

            TestDiagnostics.assertWithDiagnostics(
                condition = result.isFailure,
                event = TestDiagnosticEvent(
                    testName = "testSendMessageUseCaseErrorMatrixReturnsFailureAndPersistsUserMessage",
                    platform = "android_unit_test",
                    locale = "en",
                    selectorOrTag = "SendMessageUseCase.invoke",
                    scenarioId = scenario.wireId,
                    observedState = "expected_failure_missing",
                    failureClass = "contract_mismatch"
                ),
                assertionMessage = "Expected failure for scenario ${scenario.wireId}"
            )

            val updated = mockConversationRepository.getConversationById(conversation.id)
            val userMessages = updated!!.messages.filter { it.isUserMessage }
            assertThat(userMessages).hasSize(1)
            assertThat(userMessages.first().content).isEqualTo("Failure scenario ${scenario.wireId}")
        }
    }
}
