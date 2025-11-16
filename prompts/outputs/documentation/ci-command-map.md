# CI Command Map

**Date**: 2026-02-17
**Scope**: Deterministic test stabilization program
**Validation Basis**: Commands below were exercised during `T09`-`T13` execution.

## Android
- Unit baseline:
  - `cd shamelagpt-android && ./gradlew :app:testDebugUnitTest`
- Targeted instrumentation:
  - `cd shamelagpt-android && ./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=<FullyQualifiedTestClass>`
- Localized smoke slice (validated):
  - `cd shamelagpt-android && ./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.shamelagpt.android.presentation.LocalizedUiSmokeTest`
- Coverage:
  - `cd shamelagpt-android && ./gradlew :app:jacocoTestReport`

## iOS
- Unit baseline:
  - `cd shamelagpt-ios && xcodebuild test -project ShamelaGPT.xcodeproj -scheme ShamelaGPTTests -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'`
- Targeted UI:
  - `cd shamelagpt-ios && xcodebuild test -project ShamelaGPT.xcodeproj -scheme ShamelaGPTUITests -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:<UITestCase>`
- Localized UI smoke slice (validated):
  - `cd shamelagpt-ios && xcodebuild test -project ShamelaGPT.xcodeproj -scheme ShamelaGPTUITests -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:ShamelaGPTUITests/AuthUITests/testAuthScreenElementsVisible -only-testing:ShamelaGPTUITests/ChatFlowUITests/testNetworkErrorShowsRetryBanner -only-testing:ShamelaGPTUITests/HistoryUITests/testSwipeActionsShareAndDeleteFlow -only-testing:ShamelaGPTUITests/SettingsUITests/testLanguageSwitchUpdatesUIAndPersists`
- Coverage-enabled unit:
  - `cd shamelagpt-ios && xcodebuild test -project ShamelaGPT.xcodeproj -scheme ShamelaGPTTests -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -enableCodeCoverage YES`

## Publishing Artifacts
- Android connected tests:
  - `shamelagpt-android/app/build/reports/androidTests/connected/debug/index.html`
- Android JaCoCo:
  - `shamelagpt-android/app/build/reports/jacoco/jacocoTestReport/html/index.html`
  - `shamelagpt-android/app/build/reports/jacoco/jacocoTestReport/jacocoTestReport.xml`
- iOS test results:
  - `/Users/macintosh/Library/Developer/Xcode/DerivedData/ShamelaGPT-gfmgygkizfykobahpbvplkyensjf/Logs/Test/*.xcresult`

## Checkpoint Linkage
- Each CI batch run should append a checkpoint record in:
  - `prompts/outputs/documentation/batch-checkpoints.md`
