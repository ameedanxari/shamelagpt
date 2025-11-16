# Stage 03 Backend Integration Architecture

**Scope**: Client-side integration testing against existing backend contracts
**Date**: 2026-02-17

## Context
Backend APIs are pre-existing and not being redesigned. Architecture emphasis is on contract-accurate client behavior validation.

## API Contract Strategy
- Source of truth: `docs/api/openapi_latest.json`.
- Client tests verify request/response and error semantics against OpenAPI.
- Contract mismatches are surfaced as defects, not hidden by test fixture drift.

## Error Mapping Architecture
- Normalize handling for 400/401/403/404/429/500 + timeout/offline.
- Enforce parity in iOS and Android domain/state mapping behavior.
- Preserve canonical server values and localize only UI display strings.

## Integration Test Boundaries
- Deterministic CI tests run against controlled mocks/stubs only.
- No required live-network dependency in CI pipelines.
- Optional live checks remain manual follow-up validation.

## Observability and Diagnostics
- Integration failures log endpoint/context, scenario ID, expected mapping, observed mapping.
- Logs distinguish transport failure, schema mismatch, and mapping mismatch.

## Stage 04 Inputs
- API contract validation feature requirements.
- Error-mapping parity check requirements.
- Shared fixture/scenario management requirements.
