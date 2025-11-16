# Cross-Platform Feature Implementation Checklist

Use this checklist when implementing new features or fixes to ensure parity across both platforms.

## Pre-Implementation

- [ ] Understand the feature requirements clearly
- [ ] Identify which platforms are affected (usually BOTH)
- [ ] Review existing code in both Android and iOS for similar patterns
- [ ] Plan the implementation approach for each platform

## Android Implementation

- [ ] Create/modify Kotlin files in appropriate packages
- [ ] Update UI with Jetpack Compose components
- [ ] Implement ViewModel if needed
- [ ] Add/update data models
- [ ] Integrate API calls if needed
- [ ] Handle error states
- [ ] Handle loading states
- [ ] Update navigation if needed
- [ ] Add any required dependencies to `build.gradle.kts`
- [ ] Test on Android emulator/device

## iOS Implementation

- [ ] Create/modify Swift files in appropriate groups
- [ ] Update UI with SwiftUI views
- [ ] Implement ViewModel/ObservableObject if needed
- [ ] Add/update data models (Codable)
- [ ] Integrate API calls if needed
- [ ] Handle error states
- [ ] Handle loading states
- [ ] Update navigation if needed
- [ ] Add any required dependencies to `Package.swift`
- [ ] Test on iOS simulator/device

## Cross-Platform Validation

- [ ] UI/UX matches between platforms
- [ ] Colors and theming are consistent
- [ ] Text/strings are the same (or properly localized)
- [ ] Navigation flows are identical
- [ ] API requests/responses work on both platforms
- [ ] Error messages are consistent
- [ ] Loading indicators behave similarly
- [ ] Edge cases handled on both platforms
- [ ] Empty states match
- [ ] Success states match

## Testing

- [ ] Test feature on Android
- [ ] Test feature on iOS
- [ ] Test API integration on both platforms
- [ ] Test error scenarios on both platforms
- [ ] Test loading states on both platforms
- [ ] Verify no regressions in existing features

## Documentation

- [ ] Update Android README/docs if needed
- [ ] Update iOS README/docs if needed
- [ ] Document any platform-specific quirks
- [ ] Update API documentation if endpoints changed
- [ ] Add code comments for complex logic

## Code Quality

- [ ] Code follows platform conventions (Kotlin for Android, Swift for iOS)
- [ ] No security vulnerabilities introduced
- [ ] No hardcoded values (use constants/configs)
- [ ] Proper error handling
- [ ] Memory management considered (iOS ARC, Android lifecycle)
- [ ] Performance optimized

## Version Control

- [ ] Changes committed with descriptive message
- [ ] Commit message mentions both platforms if applicable
- [ ] All files tracked in git
- [ ] No sensitive data in commits

## Final Review

- [ ] Both platforms build successfully
- [ ] Feature works as expected on both platforms
- [ ] User experience is smooth on both platforms
- [ ] Ready for deployment/testing

---

**Tip**: Copy this checklist into your task tracker or issue description when starting a new feature!
