package com.shamelagpt.android.testing

import com.google.common.truth.Truth.assertThat
import java.io.ByteArrayOutputStream
import java.io.PrintStream
import org.junit.Test

class TestDiagnosticsTest {

    @Test
    fun `emit prints required diagnostic fields`() {
        val event = TestDiagnosticEvent(
            testName = "exampleTest",
            platform = "android_unit_test",
            locale = "en",
            selectorOrTag = "sendButton",
            scenarioId = "offline",
            observedState = "not_found",
            failureClass = "selector_mismatch"
        )

        val originalOut = System.out
        val out = ByteArrayOutputStream()
        try {
            System.setOut(PrintStream(out))
            TestDiagnostics.emit(event)
        } finally {
            System.setOut(originalOut)
        }

        val line = out.toString(Charsets.UTF_8.name())
        assertThat(line).contains("TEST_DIAGNOSTIC:")
        assertThat(line).contains("\"test_name\":\"exampleTest\"")
        assertThat(line).contains("\"platform\":\"android_unit_test\"")
        assertThat(line).contains("\"locale\":\"en\"")
        assertThat(line).contains("\"selector_or_tag\":\"sendButton\"")
        assertThat(line).contains("\"scenario_id\":\"offline\"")
        assertThat(line).contains("\"observed_state\":\"not_found\"")
        assertThat(line).contains("\"failure_class\":\"selector_mismatch\"")
    }

    @Test
    fun `assertWithDiagnostics throws assertion error when condition fails`() {
        val event = TestDiagnosticEvent(
            testName = "failingTest",
            platform = "android_unit_test",
            locale = "en",
            selectorOrTag = "retryButton",
            scenarioId = "offline",
            observedState = "not_found",
            failureClass = "selector_mismatch"
        )

        var thrown: Throwable? = null
        try {
            TestDiagnostics.assertWithDiagnostics(
                condition = false,
                event = event,
                assertionMessage = "Expected retry button"
            )
        } catch (error: Throwable) {
            thrown = error
        }

        assertThat(thrown).isInstanceOf(AssertionError::class.java)
        assertThat(thrown?.message).contains("Expected retry button")
    }
}
