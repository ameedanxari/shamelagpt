# iOS Troubleshooting Guide

This guide provides solutions for common issues encountered when building and running the ShamelaGPT iOS application.

## Build and Compilation Issues

### CocoaPods Dependency Issues
If you encounter errors related to missing pods or linking errors:
1. Ensure CocoaPods is installed: `sudo gem install cocoapods` or `brew install cocoapods`.
2. Clean existing pods: `rm -rf Pods Podfile.lock`.
3. Reinstall pods: `pod install`.
4. **Important**: Always open the `.xcworkspace` file, not the `.xcodeproj`.

### Xcode Version Compatibility
ShamelaGPT requires **Xcode 15.0** or later for SwiftUI compatibility and modern Swift features. Check your version in `Xcode > About Xcode`.

### Missing or Invalid Bundle ID
If you see "No profiles for 'com.shamelagpt.ios' were found":
1. Go to the project settings in Xcode.
2. Select the `shamelagpt` target.
3. In **Signing & Capabilities**, ensure a valid Team is selected.
4. If you are a guest developer, change the Bundle Identifier to something unique (e.g., `com.yourname.shamelagpt`).

## Simulator and Runtime Issues

### Simulator Crash on Launch
If the app crashes immediately in the simulator:
1. `Device > Erase All Content and Settings...` in the Simulator menu.
2. Clean Build Folder in Xcode: `Cmd + Shift + K`.
3. Delete the `derivedData` folder: `rm -rf ~/Library/Developer/Xcode/DerivedData`.

### Language and Localization Not Updating
If changing the language in Settings doesn't reflect in the UI:
1. Ensure the simulator has the corresponding languages added in `Settings > General > Language & Region`.
2. Check the `LanguageManager` logs in the Xcode console to see if the language was successfully switched.

### Networking / API Connection Failures
If the app cannot connect to the backend:
1. Ensure the `BASE_URL` in `Constants.swift` is correct and reachable.
2. If testing locally, ensure your computer and the API server are on the same network.
3. Check `App Transport Security` settings in `Info.plist` if using a non-HTTPS endpoint.

## Unit and UI Testing Issues

### XCUITest Failures
If UI tests fail to find elements:
1. Verify that the `accessibilityIdentifier` is correctly set in the SwiftUI view.
2. Use the **Accessibility Inspector** (Xcode > Open Developer Tool) to verify identifiers at runtime.
3. Ensure the simulator screen is not obscured and the keyboard is dismissed if necessary.

### Localized Test Failures
UI tests might fail if the simulator is set to a language different from what the test expects (e.g., Arabic RTL vs English LTR).
1. Set the simulator language to English (United States) before running tests.
2. Some tests are designed to reset the language; ensure these have the correct permissions.

---

For further assistance, please contact the development team or open a GitHub issue.
