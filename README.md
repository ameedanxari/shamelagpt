# ShamelaGPT

ShamelaGPT is a cross-platform mobile application (iOS & Android) designed to provide AI-powered chat functionality with specialized features like OCR, voice input, and fact-checking against trusted sources.

## 📚 Documentation

The project documentation is organized in the `docs/` directory:

- **[Project Status](docs/PROJECT_STATUS.md)**: Current state of the project and next steps.
- **[Theming Guide](docs/THEMING.md)**: Color palette, typography, and design system reference.
- **[Quick Reference](docs/QUICK_REFERENCE.md)**: Cheat sheet for common commands and architecture.

### Platform-Specific Guides

#### iOS (`shamelagpt-ios/`)
- **[iOS Test Plan](docs/iOS_TEST_PLAN.md)**: Comprehensive test strategy for iOS.
- **[Architecture](shamelagpt-ios/docs/01_Architecture.md)**: Technical architecture and design patterns.
- **[Build Guide](shamelagpt-ios/docs/BUILD_GUIDE.md)**: Instructions for building and running the iOS app.

#### Android (`shamelagpt-android/`)
- **[Android Test Plan](docs/ANDROID_TEST_PLAN.md)**: Comprehensive test strategy for Android.
- **[Architecture](shamelagpt-android/docs/01_Architecture.md)**: Technical architecture and design patterns.
- **[Build Guide](shamelagpt-android/docs/BUILD_GUIDE.md)**: Instructions for building and running the Android app.

## 🚀 Getting Started

1.  **Clone the repository**.
2.  **Review the [Build Guides](#platform-specific-guides)** for your target platform.
3.  **Check the [Theming Guide](docs/THEMING.md)** for UI/UX standards.

## 🧪 Testing

- **iOS**: Open `ShamelaGPT.xcodeproj` and run `Cmd+U` or use `xcodebuild test`.
- **Android**: Run `./gradlew testDebugUnitTest` or `./gradlew connectedDebugAndroidTest`.

See the respective test plans for detailed coverage and scenarios.
