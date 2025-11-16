package com.shamelagpt.android.testing

/**
 * Standardized diagnostics payload for test failures.
 */
data class TestDiagnosticEvent(
    val testName: String,
    val platform: String,
    val locale: String,
    val selectorOrTag: String,
    val scenarioId: String,
    val observedState: String,
    val failureClass: String
)

object TestDiagnostics {
    fun emit(event: TestDiagnosticEvent) {
        val json = """{"test_name":"${event.testName}","platform":"${event.platform}","locale":"${event.locale}","selector_or_tag":"${event.selectorOrTag}","scenario_id":"${event.scenarioId}","observed_state":"${event.observedState}","failure_class":"${event.failureClass}"}"""
        println("TEST_DIAGNOSTIC: $json")
    }

    fun assertWithDiagnostics(
        condition: Boolean,
        event: TestDiagnosticEvent,
        assertionMessage: String
    ) {
        if (condition) {
            return
        }
        emit(event)
        throw AssertionError(assertionMessage)
    }
}
