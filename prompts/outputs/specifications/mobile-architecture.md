# Stage 03 Mobile Architecture

**Platforms**: iOS + Android
**Date**: 2026-02-17
**Inputs**: `specifications/mobile-charter.md`, `specifications/architecture.md`

## Mobile Test Architecture Overview
- iOS: XCTest/XCUITest with protocol/URLProtocol-based deterministic mock control.
- Android: JUnit + Compose tests with DI-injected MockK-backed dependencies.
- Both platforms enforce MVVM boundaries: UI <-> ViewModel <-> Service/Repository.

## iOS Architecture Decisions
- Use accessibility identifiers as canonical selectors.
- Keep launch/test overrides isolated to test targets.
- Mock network through protocol doubles and `MockURLProtocol`.
- Run localized wrappers for `en/ar/ur`, including RTL validation.

## Android Architecture Decisions
- Use Compose `testTag`/semantics as canonical selectors.
- Inject mocks through test DI modules at ViewModel/service boundaries.
- Keep instrumentation tests focused on critical contract assertions.
- Include localized smoke runs for `en/ar/ur` and RTL-sensitive checks.

## Shared Mobile Components
- Selector registry for auth/chat/history/settings identifiers.
- Mock scenario matrix for success + required error classes.
- Diagnostics helpers that emit consistent metadata.
- Batch execution workflow with resumable checkpoints.

## Device and Locale Matrix
- Primary: phone baseline for deterministic repeated runs.
- Secondary: tablet/landscape slices for layout-specific validation.
- Locales: `en`, `ar`, `ur` with explicit RTL checks for Arabic.

## Mobile Coverage Strategy
- Unit coverage is required for ViewModels/domain logic.
- Targeted instrumentation evidence for critical paths.
- Reports written to stable locations for CI and handoff consumption.

## Constraints
- No direct UI-network coupling.
- No selector changes without synchronized test updates.
- No product behavior changes under the test-stabilization scope.

## Stage 04 Inputs
- Selector standardization workflow.
- Mock scenario lifecycle and DI workflow.
- Localization/RTL validation workflow.
- Coverage/reporting workflow.
