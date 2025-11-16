# Stage 04 Mobile Feature Specification

**Platforms**: iOS and Android
**Date**: 2026-02-17
**Inputs**: `specifications/mobile-architecture.md`, `specifications/features.md`

## Mobile Feature Areas
1. Mobile Selector Contracts
2. Mobile Mock Injection Contracts
3. Localized/RTL Validation Flows
4. Mobile Diagnostics Helpers
5. Mobile Coverage Execution Slices

## 1. Mobile Selector Contracts
- iOS uses canonical accessibility identifiers for tested UI elements.
- Android uses canonical Compose test tags/semantics IDs.
- Critical tests must avoid brittle localized text-matching as primary selector.

Acceptance:
- Auth/chat/history/settings critical tests depend on canonical IDs.
- Selector constants are centralized and referenced from tests.

## 2. Mobile Mock Injection Contracts
- iOS test runtime selects scenario via deterministic launch/test configuration.
- Android test runtime injects deterministic scenario dependencies through test DI.
- Scenario IDs and meaning are parity-aligned across platforms.

Acceptance:
- Shared scenario matrix covers required success/error/network states.
- Per-test scenario setup is explicit and observable.

## 3. Localized/RTL Validation Flows
- Required locales: `en`, `ar`, `ur`.
- Arabic runs include RTL-sensitive assertions for layout/interaction behavior.
- Locale-aware wrappers execute the same core assertions with deterministic setup.

Acceptance:
- Core flow smoke slices pass in required locales.
- RTL checks are present for Arabic-sensitive flows.

## 4. Mobile Diagnostics Helpers
- Assertion helpers emit normalized failure context.
- Metadata includes locale, scenario, selector/tag, and rendered state summary.
- Helpers are used in critical-path UI tests.

Acceptance:
- Failures in critical suites include diagnostics payload fields.
- Triage can identify mismatch class without code instrumentation changes.

## 5. Mobile Coverage Execution Slices
- Unit coverage is mandatory for ViewModel/domain paths.
- Targeted UI/instrumentation slices capture evidence for critical paths.
- Artifacts are written to stable platform-specific report paths.

Acceptance:
- Baseline coverage artifacts generated and linked from progress/handoff docs.
- Batch runs are checkpointed for resumability.

## Stage 05 Inputs
- Concrete command matrix for iOS and Android testing.
- Batch checkpoints and quality gate rules for mobile suites.
