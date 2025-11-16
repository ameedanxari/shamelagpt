# Stage 03 Architecture (Platform-Agnostic)

**Project**: ShamelaGPT Test Stabilization and Coverage Improvement
**Date**: 2026-02-17
**Inputs**: `specifications/requirements.md`, `specifications/charter.md`

## Architecture Goals
- Deterministic and repeatable test execution across iOS and Android.
- Strict layering across UI, ViewModel/domain, and integration tests.
- Stable cross-platform contracts for selectors, mocks, diagnostics, and coverage artifacts.
- Resumable execution via batch checkpoints and state updates.

## Architecture Pattern
Pattern: multi-layer test architecture over existing MVVM applications.

Layers:
1. UI/Instrumentation Layer
- Validates critical user flows with canonical selectors/tags.
- Executes localized and RTL smoke checks (`en`, `ar`, `ur`).

2. ViewModel/Domain Unit Layer
- Uses deterministic repository/service mocks.
- Validates state transitions, branching, and error handling paths.

3. Client Integration Layer
- Uses controlled mock/stub contracts for API behavior validation.
- Focuses on schema/error mapping and edge-case behavior.

4. Execution Orchestration Layer
- Defines batch sequencing, checkpoints, and artifact persistence.

## Canonical Contracts
### Selector Contract
- Tested UI elements expose stable, versioned identifiers/tags.
- Selector registry is treated as contract.
- Text-based selectors are fallback only.

### Mock Contract
- Required scenarios: success, 400, 401, 403, 404, 429, 500, timeout/offline.
- Scenario setup is explicit per test.
- Shared scenario helpers are centralized and reused.

### Diagnostics Contract
- Failures log: test name, locale, selector/tag, scenario ID, observed UI/state.
- Output must distinguish selector mismatch, mock mismatch, and render/timing issues.

## Coverage Architecture
- Generate unit coverage artifacts on both platforms via deterministic commands.
- Generate targeted integration/UI evidence where toolchain allows.
- Use stable artifact paths for trendability.

## Execution Architecture
- Execute suites in bounded batches by class/flow.
- Persist checkpoint metadata after each batch.
- Keep explicit device/profile and locale matrix for reproducibility.

## Cross-Platform Parity Model
- Shared behavior contracts are mandatory.
- Platform-native test tooling can differ.
- Any parity deviation requires explicit rationale and remediation tracking.

## Risk Controls
- Flakiness: deterministic setup, selector contracts, batch reruns.
- Mock drift: centralized matrix plus contract mapping tests.
- Runtime noise: bounded batches and checkpointed progression.
- Context drift: strict updates to `NEXT_ACTION.md`, `PROJECT_STATE.md`, and `EXECUTION_PROGRESS.md`.

## Quality Gates
- Gate A: canonical selector and mock contracts defined and used.
- Gate B: localized smoke flow stability in `en/ar/ur`.
- Gate C: coverage artifacts generated and command-traceable.
- Gate D: no product behavior regressions from test stabilization changes.

## Stage 04 Inputs
- Selector governance feature specification.
- Mock scenario and injection feature specification.
- Diagnostics and failure triage feature specification.
- Coverage and batch orchestration feature specification.
