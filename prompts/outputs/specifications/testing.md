# Stage 05 Testing Strategy (Platform-Agnostic)

**Project**: ShamelaGPT Test Stabilization and Coverage Improvement
**Date**: 2026-02-17
**Inputs**: `specifications/features.md`, `specifications/architecture.md`, `specifications/backend-architecture.md`

## Testing Objectives
- Ensure deterministic, repeatable test behavior across platform layers.
- Validate selector/mocking/diagnostics contracts.
- Validate error mapping parity against API semantics.
- Produce traceable coverage and batch checkpoints.

## Test Layers
1. Unit Tests
- Scope: ViewModel/domain logic, error mapping helpers, scenario matrix utilities.
- Requirements: full required error matrix and edge inputs (empty/long/special/RTL).

2. Integration Tests (client-side)
- Scope: repository/network behavior under controlled mock contracts.
- Requirements: OpenAPI-aligned response semantics and parity behavior.

3. UI/Instrumentation Tests
- Scope: critical user flows for auth/chat/history/settings.
- Requirements: canonical selectors, deterministic scenario setup, diagnostics on failure.

## Required Error/Network Matrix
- HTTP: 400, 401, 403, 404, 429, 500
- Network/system: timeout, offline/no-connection
- Success: nominal positive path

All matrix branches must be present in unit/integration strategy for both platforms.

## Localization and Accessibility Validation
- Locales: `en`, `ar`, `ur`.
- Arabic runs must include RTL-sensitive assertions.
- Accessibility IDs/tags are mandatory for tested interactive UI.

## Batch Strategy
- Execute bounded batches by class/flow.
- Persist checkpoint after each batch with:
  - `timestamp`, `task_id`, `batch_id`, `platform`, `command`, `status`, `artifacts`, `next_action`, `blockers`.
- Resume from last failed/blocked batch without re-running unrelated slices.

## Command Matrix (Baseline)
- Android unit:
  - `cd shamelagpt-android && ./gradlew :app:testDebugUnitTest`
- Android instrumentation (targeted):
  - `cd shamelagpt-android && ./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=<TestClass>`
- Android coverage:
  - `cd shamelagpt-android && ./gradlew :app:jacocoTestReport`
- iOS unit:
  - `cd shamelagpt-ios && xcodebuild test -project ShamelaGPT.xcodeproj -scheme ShamelaGPTTests -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'`
- iOS UI (targeted):
  - `cd shamelagpt-ios && xcodebuild test -project ShamelaGPT.xcodeproj -scheme ShamelaGPTUITests -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:<UITestCase>`
- iOS coverage:
  - `cd shamelagpt-ios && xcodebuild test -project ShamelaGPT.xcodeproj -scheme ShamelaGPTTests -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -enableCodeCoverage YES`

## Quality Gates
- G1 Selector Contract Gate
  - PASS when critical tests use canonical selectors/tags.
- G2 Mock Matrix Gate
  - PASS when required scenario matrix is covered and deterministic.
- G3 Diagnostics Gate
  - PASS when failures include required diagnostics payload fields.
- G4 Localization Gate
  - PASS when required locales and RTL-sensitive checks pass in critical slices.
- G5 Coverage Gate
  - PASS when baseline coverage artifacts are generated and linked.
- G6 Regression Safety Gate
  - PASS when no behavior regressions are introduced by stabilization changes.

## Exit Criteria for Stage 05
- Test matrix and command strategy are documented.
- Quality gates are explicit and measurable.
- Stage 06 implementation can execute directly from taskized outputs.

## Stage 06 Inputs
- Implementation task lists for selector, mocks, diagnostics, localization, coverage, and CI gating workstreams.
