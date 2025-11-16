# Contributing to ShamelaGPT

Thank you for your interest in contributing to ShamelaGPT! We welcome contributions from the community to help make authentic Islamic knowledge more accessible.

## Code of Conduct
Please be respectful and professional in all interactions. As a project focused on Islamic knowledge, we expect a high standard of conduct and respect for religious sensitivities.

## Development Workflow

### 1. Requirements
- **iOS**: Xcode 15.0+, macOS.
- **Android**: Android Studio Hedgehog+, JDK 17.

### 2. Branching Strategy
- `main`: Production-ready code.
- `develop`: Integration branch for features.
- `feature/*`: New features or enhancements.
- `fix/*`: Bug fixes.

### 3. Pull Request Process
1. Fork the repository.
2. Create a feature branch from `develop`.
3. Implement your changes on **BOTH** iOS and Android platforms to maintain parity.
4. Add unit tests for new logic.
5. Ensure all existing tests pass on both platforms.
6. Submit a PR to the `develop` branch.
7. Address any review comments.

## Coding Standards

### Clean Architecture
We strictly follow clean architecture principles. ViewModels should not know about network implementation, and Views should only observe ViewModels.

### Platform Parity
This is our most important rule. **Do not submit a PR that only implements a feature on one platform** unless you've discussed it with the maintainers first.

### Localization
Always extract strings to:
- `Localizable.strings` (iOS)
- `strings.xml` (Android)

## Testing
- iOS: `Cmd + U` in Xcode.
- Android: `./gradlew test`.

## Licensing
By contributing, you agree that your contributions will be licensed under the project's license (see `LICENSE` file).
