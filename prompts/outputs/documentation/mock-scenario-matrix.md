# Mock Scenario Matrix

**Date**: 2026-02-17
**Stage/Task**: Execution `T02` shared scenario matrix

## Required Scenarios
- `success`
- `api_400`
- `api_401`
- `api_403`
- `api_404`
- `api_429`
- `api_500`
- `timeout`
- `offline`

## Source of Truth
- iOS unit/integration matrix:
  - `shamelagpt-ios/shamelagptTests/Mocks/MockScenarioMatrix.swift`
- iOS UI-test matrix bridge:
  - `shamelagpt-ios/shamelagptUITests/Helpers/NetworkMockHelper.swift`
  - `shamelagpt-ios/shamelagpt/shamelagptApp.swift`
- Android unit/integration matrix:
  - `shamelagpt-android/app/src/test/java/com/shamelagpt/android/mock/MockScenarioMatrix.kt`

## Canonical Wire IDs
- `success`
- `http_400`
- `http_401`
- `http_403`
- `http_404`
- `http_429`
- `http_500`
- `timeout`
- `offline`

## Rules
- Each test declares scenario explicitly.
- Scenario naming/meaning must remain parity-aligned across iOS and Android.
- Scenario fixtures must reflect `docs/api/openapi_latest.json` semantics.

## Coverage Consumers
- iOS matrix mapping unit test:
  - `shamelagpt-ios/shamelagptTests/MockScenarioMatrixTests.swift`
- iOS logic-layer matrix assertions (`T04`):
  - `shamelagpt-ios/shamelagptTests/ChatViewModelTests.swift`
  - `shamelagpt-ios/shamelagptTests/Integration/NetworkErrorRecoveryTests.swift`
- Android matrix mapping unit test:
  - `shamelagpt-android/app/src/test/java/com/shamelagpt/android/mock/MockScenarioMatrixTest.kt`
- Android logic-layer matrix assertions (`T05`):
  - `shamelagpt-android/app/src/test/java/com/shamelagpt/android/domain/usecase/SendMessageUseCaseTest.kt`
  - `shamelagpt-android/app/src/test/java/com/shamelagpt/android/presentation/chat/ChatViewModelTest.kt`
  - `shamelagpt-android/app/src/test/java/com/shamelagpt/android/integration/NetworkErrorRecoveryTest.kt`
