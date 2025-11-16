# API Contract Mapping

**Date**: 2026-02-17  
**Stage/Task**: Execution `T06` API contract mapping assertions

## Contract Source
- OpenAPI baseline: `docs/api/openapi_latest.json`

## Validation Tests
- Android:
  - `shamelagpt-android/app/src/test/java/com/shamelagpt/android/contract/OpenApiContractMappingTest.kt`
- iOS:
  - `shamelagpt-ios/shamelagptTests/OpenAPIContractMappingTests.swift`

## Assertions Enforced
- `ChatRequest` required field compatibility (must include `question`).
- Request wire-key mapping parity with OpenAPI schemas (`ChatRequest` + `GuestChatRequest`):
  - `question`
  - `thread_id`
  - `language_preference`
  - `custom_system_prompt`
  - `enable_thinking`
  - `session_id`
- Response decode compatibility for `/api/chat` payload shape:
  - `answer`
  - `thread_id`

## Mismatch Diagnostics
- Tests fail with explicit key-level diagnostics when model keys are missing or unmapped to the OpenAPI contract.
- Android contract helper emits missing-object diagnostics with available OpenAPI keys for triage.
