# Stage 07 Mobile Deployment Strategy

**Platforms**: iOS and Android
**Date**: 2026-02-17
**Inputs**: `specifications/mobile-testing.md`, `task-lists/mobile-implementation.md`

## Mobile Deployment Scope
Deployment here means reliable mobile test/release validation workflows and artifact publication for iOS and Android.

## iOS Deployment Workflow
1. Unit/logic test slices via `xcodebuild` on pinned simulator runtime.
2. Targeted UI slices for critical flows and localized smoke (`en/ar/ur`).
3. Coverage-enabled run for required suites.
4. Publish `.xcresult` and `xccov` summary in CI artifacts.

## Android Deployment Workflow
1. Unit suite and targeted class slices via Gradle.
2. Instrumentation slices for critical flow and localization smoke.
3. JaCoCo report generation and publication.
4. Publish connected test reports and coverage artifacts.

## Mobile Release Gates
- MG-1 selector contract pass.
- MG-2 mock scenario matrix pass.
- MG-3 diagnostics payload compliance.
- MG-4 localization/RTL baseline pass.
- MG-5 coverage artifact publication pass.

## Environment Controls
- Pin simulator/emulator profiles for consistency.
- Run readiness checks before instrumentation.
- Record environment blockers explicitly (e.g., emulator offline).

## Artifact Locations
- Android connected tests:
  - `shamelagpt-android/app/build/reports/androidTests/connected/debug/index.html`
- Android coverage:
  - `shamelagpt-android/app/build/reports/jacoco/jacocoTestReport/index.html`
- iOS results:
  - `DerivedData/.../Logs/Test/*.xcresult`

## Recovery Strategy
- Retry only failed mobile batch slice.
- Do not rerun full suite unless contract-level change requires it.
- Keep last known-good artifact links in handoff docs.

## Stage 08 Inputs
- Mobile-facing operator docs for batch commands, checkpoints, and failure triage.
