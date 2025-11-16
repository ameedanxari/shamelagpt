# Mock Infrastructure Guide

To ensure tests are fast, deterministic, and isolated from external services, ShamelaGPT uses a robust mock infrastructure on both platforms.

## iOS Mocking Strategy

### 1. Network Mocking: `MockURLProtocol`
Instead of mocking the `APIClient` protocol everywhere, we often use `MockURLProtocol` which intercepts all `URLSession` traffic.
- **How to use**: Set `MockURLProtocol.requestHandler` with a closure that returns a mock `HTTPURLResponse` and `Data`.
- **Benefit**: Tests the actual `APIClient` logic, encoding, and decoding.

### 2. Protocol Mocking
For ViewModels, we inject protocol-based mocks:
- `MockAuthRepository`
- `MockChatRepository`
- `MockSendMessageUseCase`

## Android Mocking Strategy

### 1. MockK
We use **MockK** for general-purpose mocking.
- `coEvery { ... } returns ...` for suspend functions.
- `relaxed = true` for mocks where we don't care about every interaction.

### 2. Fake Repositories
For complex state (like chat history), we use "Fakes" instead of mocks:
- `MockConversationRepository`: An in-memory implementation of the repository that behaves like a real database.

## Test Data Factory
Both platforms include a `TestData` utility (module or class) to generate consistent model objects for tests.

- **iOS**: `TestData.swift` in `shamelagptTests`.
- **Android**: `TestData.kt` in `com.shamelagpt.android.mock`.

## UI Test Mocking

### iOS
In UI tests, we set environment variables (e.g., `process.environment["UI_TESTING"] = "1"`) which tricks the `DependencyContainer` into injecting `MockURLProtocol`.

### Android
In instrumented tests, we use Koin's `loadKoinModules` to override production repositories with mocks/fakes before the test starts.
