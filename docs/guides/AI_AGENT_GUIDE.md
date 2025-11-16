# AI Agent Guide

This guide is for AI assistants (like Claude, Gemini, or GitHub Copilot) working on the ShamelaGPT codebase. Following these rules ensures consistency and prevents platform drift.

## 1. The Rule of Parity
**NEVER** implement a feature on one platform without creating a corresponding task/draft for the other.
- If you add a field to `Message` on iOS, you must add it to `Message` on Android.
- If you fix a bug in the streaming logic on Android, check if the same bug exists on iOS.

## 2. Code Patterns to Follow

### Dependency Injection
- **iOS**: Use `Swinject` or Protocol-based DI.
- **Android**: Use `Koin` or constructor injection with Compose hilt/koin-viewModel.

### Asynchrony
- **iOS**: Use `Swift Concurrency` (async/await) where possible, falling back to `Combine`.
- **Android**: Use `Kotlin Coroutines` and `Flow`.

### UI
- **iOS**: Use `SwiftUI` with `ViewModifier`s for the Emerald/Amber theme.
- **Android**: Use `Jetpack Compose` with custom `MaterialTheme`.

## 3. Testing Requirements
Any significant logic change MUST be accompanied by a unit test.
- Use `runTest` on Android.
- Use `XCTest` on iOS.
- Mock all network and database dependencies.

## 4. File Organization
Stick to the established folder structure. If you need a new utility, put it in `Core/Utilities`. Avoid spreading logic across files.

## 5. Common Pitfalls
- **Hardcoded Strings**: Always use resource files.
- **Density Independent Pixels**: Use `.dp` on Android and standard points on iOS.
- **Force Unwrapping**: Avoid `!` in Swift and `!!` in Kotlin. Use safe calls and `let`/`run`.
