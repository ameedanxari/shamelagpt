package com.shamelagpt.android.mock

import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.core.network.NetworkError
import org.junit.Test

class MockScenarioMatrixTest {

    @Test
    fun `success scenario returns success result`() {
        val repository = MockChatRepository()

        MockScenarioMatrix.apply(MockScenarioId.SUCCESS, repository)

        assertThat(repository.sendMessageResult.isSuccess).isTrue()
    }

    @Test
    fun `error scenarios map to expected network errors`() {
        val repository = MockChatRepository()

        val scenarios = listOf(
            MockScenarioId.HTTP_400 to NetworkError.HttpError(400),
            MockScenarioId.HTTP_401 to NetworkError.HttpError(401),
            MockScenarioId.HTTP_403 to NetworkError.HttpError(403),
            MockScenarioId.HTTP_404 to NetworkError.HttpError(404),
            MockScenarioId.HTTP_429 to NetworkError.HttpError(429),
            MockScenarioId.HTTP_500 to NetworkError.HttpError(500),
            MockScenarioId.TIMEOUT to NetworkError.Timeout,
            MockScenarioId.OFFLINE to NetworkError.NoConnection
        )

        scenarios.forEach { (scenario, expectedError) ->
            MockScenarioMatrix.apply(scenario, repository)
            val error = repository.sendMessageResult.exceptionOrNull()
            assertThat(error).isEqualTo(expectedError)
        }
    }
}
