# Diagnostics Contract

**Date**: 2026-02-17

## Required Failure Fields
- `test_name`
- `platform`
- `locale`
- `selector_or_tag`
- `scenario_id`
- `observed_state`
- `failure_class` (`selector_mismatch`, `mock_mismatch`, `render_timing`, `contract_mismatch`)

## Emission Rules
- Emit diagnostics on every failed assertion in critical flows.
- Include current locale and scenario ID even when default values are used.
- Keep payload stable across iOS/Android for parity triage.

## Source Of Truth
- iOS payload + emitter: `shamelagpt-ios/shamelagptUITests/Helpers/TestDiagnostics.swift`
- iOS assertion wrapper: `shamelagpt-ios/shamelagptUITests/Helpers/LocalizedUITestCase.swift` (`assertElementExistsWithDiagnostics`)
- Android payload + emitter + wrapper: `shamelagpt-android/app/src/test/java/com/shamelagpt/android/testing/TestDiagnostics.kt` (`assertWithDiagnostics`)
- Android usage in failure-path integration tests: `shamelagpt-android/app/src/test/java/com/shamelagpt/android/integration/NetworkErrorRecoveryTest.kt`
