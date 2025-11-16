# iOS Test Plan

This document outlines the testing strategy for the ShamelaGPT iOS application.

## 1. Unit Testing
We use **XCTest** for unit testing. Our goal is to cover all business logic in ViewModels and Use Cases.

### Key Components to Test
- **ViewModels**: State transitions, error handling, input validation.
- **Use Cases**: Correct interaction with repositories.
- **Repositories**: Data mapping, caching logic, error mapping.
- **Mappers**: Correct conversion between types.

### Running Unit Tests
Press `Cmd + U` or run from terminal:
```bash
xcodebuild test -workspace ShamelaGPT.xcworkspace -scheme ShamelaGPT -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 2. Integration Testing
Integration tests verify that different layers work together (e.g., ViewModel + UseCase + MockRepository).

## 3. UI Testing
We use **XCUITest** for automated UI testing.
- **Mocks**: We use `MockURLProtocol` to intercept network requests and provide deterministic JSON responses.
- **Scope**: Critical user flows (Login, Send Message, Delete Conversation).

## 4. Manual Testing Checklist
- [ ] New user onboarding flow.
- [ ] Voice input in both English and Arabic.
- [ ] Image OCR with various lighting conditions.
- [ ] Dark mode toggle.
- [ ] RTL/LTR layout verification.
- [ ] Background/Foreground app transitions.

## 5. Continuous Integration (CI)
Tests are automatically run on every Pull Request via GitHub Actions.
- Target: `iOS 17.0` simulator.
- Quality Gate: No test failures allowed.
