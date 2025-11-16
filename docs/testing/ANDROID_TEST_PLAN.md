# Android Test Plan

This document outlines the testing strategy for the ShamelaGPT Android application.

## 1. Unit Testing
We use **JUnit4**, **MockK**, and **Google Truth** for unit testing. Our goal is 80%+ coverage of the Domain and Presentation (ViewModel) layers.

### Key Components to Test
- **ViewModels**: Observe `uiState` using `runTest` and `testScheduler`.
- **Use Cases**: Verify repository calls.
- **Repositories**: Test logic for caching and network interaction.

### Running Unit Tests
```bash
./gradlew test
```

## 2. Integration Testing
Testing collaborations between ViewModels and Repositories using `MockConversationRepository`.

## 3. UI Testing (Instrumented)
We use **Jetpack Compose Test Rule** and **Espresso** for instrumented tests.
- **Scope**: Screen-level interaction and navigation.
- **Mocks**: Inject mock repositories via Koin during test setup.

## 4. Manual Testing Checklist
- [ ] Authentication (Signup/Login/Google).
- [ ] Chat streaming responsiveness.
- [ ] Speech-to-text accuracy.
- [ ] Image picking and OCR processing.
- [ ] Language switching persistence.
- [ ] Accessibility (TalkBack).

## 5. Continuous Integration (CI)
Tests are run automatically on GitHub Actions.
- Target: `Pixel 6` Emulator, API 33.
- Quality Gate: 100% test pass rate.
