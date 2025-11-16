# Implementation Tasks - Test Stabilization Program

**Source Stages**: 01-06
**Date**: 2026-02-17
**Execution Mode**: Build Loop (post-Stage-06)

## Task Index
- Total tasks: 16
- Critical path: T01 -> T02 -> T03 -> T04 -> T05 -> T06 -> T07 -> T08 -> T09 -> T10 -> T11 -> T12 -> T14 -> T15 -> T16

## Foundation

- [x] **T01 (P0)** Establish canonical selector registry contract for critical flows on iOS + Android.
  - Dependencies: none
  - Outputs: selector registry docs/files + mapped usage in tests
  - Acceptance: critical UI tests reference canonical IDs/tags

- [x] **T02 (P0)** Implement shared mock scenario matrix (`success`, `400/401/403/404/429/500`, `timeout`, `offline`).
  - Dependencies: T01
  - Outputs: reusable scenario helpers/builders per platform
  - Acceptance: every API-driven test can choose explicit scenario ID

- [x] **T03 (P0)** Implement standardized diagnostics helper contract in test layers.
  - Dependencies: T01, T02
  - Outputs: diagnostics helpers and assertion wrappers
  - Acceptance: failing tests emit required metadata (test, locale, selector, scenario, state)

## Business Logic and Integration

- [x] **T04 (P0)** Expand iOS unit/integration logic tests for full error/network matrix.
  - Dependencies: T02
  - Outputs: iOS test updates for ViewModel/repository/API mapping
  - Acceptance: all required scenario classes asserted in iOS logic tests

- [x] **T05 (P0)** Expand Android unit/integration logic tests for full error/network matrix.
  - Dependencies: T02
  - Outputs: Android test updates for ViewModel/repository/API mapping
  - Acceptance: all required scenario classes asserted in Android logic tests

- [x] **T06 (P1)** Add API contract mapping assertions aligned to `docs/api/openapi_latest.json`.
  - Dependencies: T04, T05
  - Outputs: contract validation tests and mismatch diagnostics
  - Acceptance: contract mismatches surface as explicit failures

## UI and Localization

- [x] **T07 (P0)** Refactor iOS critical UI tests to canonical selectors and deterministic setup.
  - Dependencies: T01, T03
  - Outputs: updated iOS UI tests for auth/chat/history/settings
  - Acceptance: selector-first assertions in critical flows

- [x] **T08 (P0)** Refactor Android critical UI tests to canonical tags/selectors and deterministic setup.
  - Dependencies: T01, T03
  - Outputs: updated Android UI tests for auth/chat/history/settings
  - Acceptance: selector-first assertions in critical flows

- [x] **T09 (P0)** Execute iOS localized smoke baseline for `en`, `ar`, `ur` including RTL-sensitive checks.
  - Dependencies: T07
  - Outputs: iOS localized batch logs and artifacts
  - Acceptance: baseline localized smoke passes or blockers documented

- [x] **T10 (P0)** Execute Android localized smoke baseline for `en`, `ar`, `ur` including RTL-sensitive checks.
  - Dependencies: T08
  - Outputs: Android localized batch logs and artifacts
  - Acceptance: baseline localized smoke passes or blockers documented

## Coverage and Batch Orchestration

- [x] **T11 (P0)** Standardize checkpoint schema and batch-run workflow.
  - Dependencies: T03, T07, T08
  - Outputs: checkpoint template and execution rules
  - Acceptance: each batch records command, status, artifacts, and next action

- [x] **T12 (P0)** Generate baseline coverage artifacts from standardized commands.
  - Dependencies: T04, T05, T09, T10, T11
  - Outputs: coverage reports in stable paths
  - Acceptance: artifact links recorded in execution logs

- [x] **T13 (P1)** Run supplemental tablet/landscape slices where feasible.
  - Dependencies: T10, T11
  - Outputs: supplemental validation logs and fallback decisions
  - Acceptance: outcomes documented with blockers/rerun policy

## CI and Quality Gates

- [x] **T14 (P1)** Align CI command map for deterministic slices and coverage publishing.
  - Dependencies: T11, T12
  - Outputs: CI command map and artifact path references
  - Acceptance: command set is locally validated and CI-ready

- [x] **T15 (P1)** Execute quality gate checklist (`G1..G6` + mobile gate set).
  - Dependencies: T12, T14
  - Outputs: pass/fail quality gate record with evidence links
  - Acceptance: all required release gates pass or have explicit remediation

## Documentation and Handoff

- [x] **T16 (P1)** Finalize execution summary, residual risks, and next backlog.
  - Dependencies: T13, T15
  - Outputs: handoff summary and reproducible resume state
  - Acceptance: next agent can continue without hidden context

## Command Quick Reference
- Android unit: `cd shamelagpt-android && ./gradlew :app:testDebugUnitTest`
- Android instrumentation slice: `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=<CLASS_LIST>`
- Android coverage: `./gradlew :app:jacocoTestReport`
- iOS unit: `xcodebuild test -project shamelagpt-ios/ShamelaGPT.xcodeproj -scheme ShamelaGPTTests -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'`
- iOS UI slice: `xcodebuild test -project shamelagpt-ios/ShamelaGPT.xcodeproj -scheme ShamelaGPTUITests -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:<UITestTarget>`
