# Stage 02 Mobile Charter

**Platforms**: iOS and Android
**Date**: 2026-02-17

## Mobile Objectives
- Stabilize mobile tests for auth, chat, history, and settings critical paths.
- Preserve behavior parity between iOS and Android validation logic.
- Verify localized and RTL-sensitive behavior for `en`, `ar`, `ur`.
- Keep execution practical with batch-first strategy.

## Platform Strategy
- iOS:
  - XCTest/XCUITest with deterministic launch arguments and canonical accessibility identifiers.
- Android:
  - JUnit + Compose tests with canonical test tags and deterministic mock wiring.
- Shared:
  - Equivalent scenario semantics and assertion intent across both platforms.

## Mobile Success Metrics
- Critical UI slices are deterministic and repeatable.
- Localized smoke slices pass for `en/ar/ur`.
- Failures include diagnostics sufficient to distinguish selector/mocking/rendering root causes.
- Coverage artifacts are produced by standard commands and archived consistently.

## Mobile Risks
- Device lifecycle instability in emulator/simulator test runs.
- Cross-platform selector naming drift.
- Inconsistent mock setup across suites.

## Mobile Mitigations
- Enforce readiness checks and checkpointed batch execution.
- Maintain shared selector registry conventions.
- Centralize mock scenario definitions and setup helpers.

## Stage 03 Mobile Architecture Inputs
- Selector/tag governance model.
- Mock scenario lifecycle and injection boundaries.
- Mobile diagnostics contract for test failures.
- Device/profile matrix for reliable repeated runs.
