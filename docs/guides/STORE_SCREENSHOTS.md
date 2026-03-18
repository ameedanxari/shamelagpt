# Store Screenshots (xcodebuild + Gradle)

Use this when you need App Store / Play Store screenshot sets without Fastlane. Screens are deterministic using mock data and locale overrides.

## Prerequisites
- Xcode with simulators installed (names in script: iPhone 16 Pro Max, iPhone 11 Pro Max, iPhone 8 Plus, iPad Pro 12.9" 6th gen).
- Android SDK + emulator; `adb` on PATH.
- M1+/Intel host with ~20 GB free for simulators / emulators.

## Scenarios & fixtures
- Configure desired screens/locales in `docs/screenshot_scenarios.yaml` (mirrors both platforms).
- iOS uses `NetworkMockHelper` fixtures; Android uses mock view models inside the screenshot test.

## One-shot script (recommended)
From repo root:
```bash
scripts/run_store_screenshots.sh
```
This entrypoint now delegates to the unified runner (`scripts/run_screenshots.sh --store`).

Artifacts are always written under the repo `artifacts/` folder (git-ignored), including logs and debug output.
The unified runner now automatically performs a post-run visual QC step and writes:
- `artifacts/visual_qc/summary.json`
- `artifacts/visual_qc/contact_sheet__*.png`

The script auto-selects simulators from the currently installed set and supports `--ios` / `--android` platform filtering.

For targeted validation (single screen/locale/scenario), use:
```bash
scripts/run_targeted_screenshots.sh --screen auth --android
```
or directly:
```bash
scripts/run_screenshots.sh --targeted --screen auth --android
```

## Manual commands
### iOS (single device/locale)
```bash
SCREENSHOT_OUTPUT_DIR=artifacts/ios \
SCREENSHOT_DEVICE="iPhone 16 Pro Max" \
xcodebuild test \
  -project shamelagpt-ios/ShamelaGPT.xcodeproj \
  -scheme ShamelaGPT \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
  -only-testing:ShamelaGPTUITests/StoreScreenshotUITests/test_storeScreenshots_chatAndSettings \
  -skip-testing:ShamelaGPTTests \
  APPLE_LANGUAGE=en APPLE_LOCALE=en_US
```
Outputs are also attached in the `.xcresult` bundle at `artifacts/ios/...`.

### Android (per locale)
```bash
cd shamelagpt-android
./gradlew :app:connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.class=com.shamelagpt.android.screenshots.StoreScreenshotTest \
  -Plocale=en
adb pull /sdcard/Android/data/com.shamelagpt.android/files/screenshots ../artifacts/android || true
```
Repeat with `-Plocale=ar` and `-Plocale=ur`. Device matrix is controlled by your running emulator(s).

## Notes
- iOS files also honor `SCREENSHOT_OUTPUT_DIR`/`SCREENSHOT_DEVICE`; Android uses external files dir, pulled by the script.
- Keep emulators/simulators pre-booted to reduce run time.
- For QA visual sweeps, reuse the same scenarios; expand the scenario file rather than hardcoding in tests.
- Both platforms now emit light and dark variants; filenames include `_dark` when captured in dark mode.
