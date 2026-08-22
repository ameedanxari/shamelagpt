# iOS 1.1 — release assets

Everything needed for the App Store Connect submission of ShamelaGPT iOS `1.1`.

| | |
|---|---|
| Marketing version | `1.1` |
| Build at time of writing | `2` |
| Bundle id | `com.shamelagpt.ios` |
| Extensions | `com.shamelagpt.ios.FactCheckAction`, `com.shamelagpt.ios.FactCheckShareExtension` |
| Team | `SSTKXHNR6U` |

**The build number is not fixed by this directory.** `CURRENT_PROJECT_VERSION` is an input to the TestFlight workflow and increments on every upload, because App Store Connect rejects a build that does not exceed the last one for the same marketing version. Record the build that actually shipped in `submitted.md` when you upload.

## Contents

```
release/ios/1.1/
├── README.md          this file
├── release-notes.md   store copy, internal changelog, ASC checklist, known issues
└── screenshots/
    ├── en/
    ├── ar/
    └── ur/
```

## Screenshots

**Not generated yet, deliberately.** They must come from the final merged build — the madhhab picker and the reasoning panel both landed this week, and a screenshot taken from an intermediate commit would show a version of Settings that never shipped.

Generate them after the merge pass:

```bash
cd shamelagpt-ios
xcodebuild test \
  -scheme ShamelaGPT \
  -destination 'id=<simulator-udid>' \
  -testPlan StoreScreenshots \
  -only-testing:ShamelaGPTUITests/StoreScreenshotUITests
```

`StoreScreenshots.xctestplan` exists for this and sets `STOREKIT_SANDBOX_EMAIL`. Targeted captures are also available if only one screen needs redoing:

- `TargetedScreenshotUITests/test_captureWelcomeScreenshots`
- `.../test_captureAuthScreenshots`
- `.../test_captureChatScreenshots`
- `.../test_captureHistoryScreenshots`
- `.../test_captureSettingsScreenshots`

Output lands in the test results bundle as attachments; copy the PNGs into the locale folder above.

### Two things that will cost a rejection if missed

**Device sizes.** App Store Connect requires 6.9" and 6.5" display screenshots for iPhone. Capture on a Pro Max class simulator, not the iPhone 17 Pro used for the test runs, or the upload will be refused for wrong dimensions.

**Arabic is right-to-left.** The `ar` screenshots must be captured with the app in Arabic, not the English build with Arabic captions bolted on. The layout mirrors, and reviewers do check.

### Run these alone

The UI suite is badly contention-sensitive — individual tests take 76–260s, and two full runs were lost to simulator contention during development. Do not run screenshot capture alongside another simulator job, and do not trust a batch result.

## Before submitting

`release-notes.md` section 3 has the full App Store Connect checklist. Sensitive information is now declared in the manifest — the madhhab preference is a stored statement of religious affiliation, so it qualifies. One item still needs a person rather than typing:

1. **Arabic and Urdu release notes** must be written by the native speaker reviewing issue #70 — not machine-translated. They sit beside professionally written in-app copy.

## Known and unfixed in this version

- `iOS UI Tests` red on `main` since 12 August (#64)
- Five Arabic/Urdu strings awaiting native-speaker review (#70)
- Nothing in this release has run on a physical device — verification was simulator plus live API calls against production
