# Stage 05 Mobile Testing Strategy

**Platforms**: iOS and Android
**Date**: 2026-02-17
**Inputs**: `specifications/mobile-features.md`, `specifications/mobile-architecture.md`, `specifications/testing.md`

## Mobile Testing Goals
- Stabilize critical flow tests across iOS and Android.
- Ensure locale and RTL reliability for `en/ar/ur`.
- Standardize deterministic mocks and selector-based assertions.
- Keep long mobile suites manageable through batch slicing.

## iOS Strategy
- Unit:
  - XCTest for ViewModel/domain and API mapping behavior.
  - Explicit coverage of success + required error/network matrix.
- UI:
  - XCUITest with canonical accessibility identifiers.
  - Locale wrapper execution for `en/ar/ur`, RTL checks in Arabic-sensitive flows.
- Diagnostics:
  - Use shared assertion helpers that include selector/scenario/locale context.

## Android Strategy
- Unit:
  - JUnit + MockK for ViewModel/domain/repository behavior and mapping parity.
  - Explicit matrix coverage: HTTP + timeout/offline.
- UI/Instrumentation:
  - Compose test tags as primary selectors.
  - Targeted instrumentation slices for critical flows and locale smoke.
- Diagnostics:
  - Use shared helper output for selector/scenario/render-state context.

## Mobile Batch Plan
- Batch M1: selector contract and critical UI element presence.
- Batch M2: mock matrix and error mapping unit/integration coverage.
- Batch M3: localized critical flow smoke (`en/ar/ur`).
- Batch M4: diagnostics contract verification.
- Batch M5: coverage artifact generation and gate evaluation.

## Mobile Artifacts
- Android:
  - `shamelagpt-android/app/build/reports/androidTests/connected/debug/index.html`
  - `shamelagpt-android/app/build/reports/jacoco/jacocoTestReport/index.html`
- iOS:
  - `.xcresult` paths from `xcodebuild test`
  - coverage report from `xcrun xccov view --report --json <xcresult>`

## Mobile Risks and Controls
- Emulator/simulator instability:
  - enforce device readiness checks and targeted reruns.
- Selector drift:
  - enforce canonical registry usage in test code reviews.
- Mock drift:
  - enforce centralized scenario matrix utilities.

## Stage 06 Inputs
- Taskized mobile implementation plan with file-level execution slices and checkpoint policy.
