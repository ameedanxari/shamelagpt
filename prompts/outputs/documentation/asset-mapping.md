# Stage 01 - Asset Mapping

## Core Inputs
- `MY_PROJECT.md`: primary project brief and constraints.
- `AGENTS.md`: repository-level agent execution rules.
- `.claude/parity.md`: platform parity requirements.
- `.claude/implementation.md`: reuse/placement decision rules.
- `.claude/testing.md`: testing and CI command expectations.
- `.claude/localization.md`: localization and RTL rules.
- `.claude/quick_rules.md`: fast command and search patterns.

## Product and Architecture References
- `docs/PROJECT_STATUS.md`: current implementation status.
- `docs/USE_CASES.md`: feature/use-case inventory.
- `docs/THEMING.md`: visual system constraints.
- `docs/QUICK_REFERENCE.md`: development quick reference.
- `docs/api/openapi_latest.json`: API contract baseline.

## Platform Entrypoints
- Android chat ViewModel:
  - `shamelagpt-android/app/src/main/java/.../presentation/chat/ChatViewModel.kt`
- iOS chat ViewModel:
  - `shamelagpt-ios/shamelagpt/Presentation/Scenes/Chat/ChatViewModel.swift`

## Existing Test Strategy Inputs
- `docs/iOS_TEST_PLAN.md`
- `docs/ANDROID_TEST_PLAN.md`

## Expected Stage 01 Outputs
- `prompts/outputs/specifications/requirements.md`
- `prompts/outputs/documentation/asset-mapping.md`
- Updated `prompts/outputs/PROJECT_STATE.md`
- Updated `NEXT_ACTION.md`
