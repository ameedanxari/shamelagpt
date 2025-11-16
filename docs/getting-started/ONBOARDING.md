# ShamelaGPT Onboarding Guide

Welcome to the ShamelaGPT project! This guide is designed to get you up and running with the codebase in less than 30 minutes.

## Project Overview
ShamelaGPT is a native mobile application (iOS & Android) that provides an AI-powered interface to Islamic knowledge, primarily sourcing from the Shamela.ws library.

### Core Technologies
- **iOS**: Swift, SwiftUI, Combine, Core Data.
- **Android**: Kotlin, Jetpack Compose, Coroutines, Room.
- **Architecture**: MVVM + Repository Pattern.

## Step 1: Environment Setup

### For iOS Developers
1. Install **Xcode 15.0** or later.
2. Clone the repository and navigate to `shamelagpt-ios`.
3. Open `ShamelaGPT.xcworkspace`.
4. Run `pod install` if you are using CocoaPods (check if `Pods` folder exists).
5. Build and run on a simulator.

Detailed guide: [SETUP_IOS.md](SETUP_IOS.md)

### For Android Developers
1. Install **Android Studio Hedgehog** or later.
2. Clone the repository and navigate to `shamelagpt-android`.
3. Open the project in Android Studio.
4. Wait for Gradle sync to complete.
5. Build and run on an emulator (API 26+).

Detailed guide: [SETUP_ANDROID.md](SETUP_ANDROID.md)

## Step 2: Key Concepts

### Repository Pattern
All data access (API or Local DB) goes through a Repository.
- iOS: `ChatRepository.swift`, `AuthRepository.swift`
- Android: `ChatRepository.kt`, `AuthRepository.kt`

### Parity Requirement
ShamelaGPT is a cross-platform project. **Every feature implemented on iOS must also be implemented on Android**, and vice versa. This includes unit tests and UI/UX behaviors.

## Step 3: First Tasks
To familiarize yourself with the codebase, we recommend these small tasks:
1. Update a string in `Localizable.strings` (iOS) or `strings.xml` (Android).
2. Add a simple log statement to a ViewModel.
3. Run the unit test suite (`Cmd+U` in Xcode, `./gradlew test` in Android).

## Step 4: Documentation
Refer to these detailed documents as needed:
- [Architecture Overview](../architecture/OVERVIEW.md)
- [API Reference](../api/API_REFERENCE.md)
- [Theming Guide](../guides/THEMING.md)

## Troubleshooting
If you hit any walls, check:
- [iOS Troubleshooting](TROUBLESHOOTING_IOS.md)
- [Android Troubleshooting](TROUBLESHOOTING_ANDROID.md)
