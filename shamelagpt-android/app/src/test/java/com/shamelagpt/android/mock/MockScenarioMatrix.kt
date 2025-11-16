package com.shamelagpt.android.mock

import com.shamelagpt.android.core.network.NetworkError

/**
 * Shared scenario matrix for Android unit/integration tests.
 */
enum class MockScenarioId(val wireId: String) {
    SUCCESS("success"),
    HTTP_400("http_400"),
    HTTP_401("http_401"),
    HTTP_403("http_403"),
    HTTP_404("http_404"),
    HTTP_429("http_429"),
    HTTP_500("http_500"),
    TIMEOUT("timeout"),
    OFFLINE("offline")
}

object MockScenarioMatrix {
    fun apply(scenario: MockScenarioId, repository: MockChatRepository) {
        repository.sendMessageResult = when (scenario) {
            MockScenarioId.SUCCESS -> Result.success(TestData.sampleChatResponse)
            MockScenarioId.HTTP_400 -> Result.failure(NetworkError.HttpError(400))
            MockScenarioId.HTTP_401 -> Result.failure(NetworkError.HttpError(401))
            MockScenarioId.HTTP_403 -> Result.failure(NetworkError.HttpError(403))
            MockScenarioId.HTTP_404 -> Result.failure(NetworkError.HttpError(404))
            MockScenarioId.HTTP_429 -> Result.failure(NetworkError.HttpError(429))
            MockScenarioId.HTTP_500 -> Result.failure(NetworkError.HttpError(500))
            MockScenarioId.TIMEOUT -> Result.failure(NetworkError.Timeout)
            MockScenarioId.OFFLINE -> Result.failure(NetworkError.NoConnection)
        }
    }
}
