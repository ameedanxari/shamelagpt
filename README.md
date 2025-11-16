# ShamelaGPT

**ShamelaGPT** is an advanced AI-powered mobile application designed to provide accurate, source-verified responses for Islamic studies and general knowledge. Built for both iOS and Android, it features a unified design system, robust offline capabilities, and multimodal input support.

![Build Status](https://img.shields.io/badge/build-passing-brightgreen) ![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-blue) ![License](https://img.shields.io/badge/license-Private-red)

## ✨ Key Features

- **AI Chat**: Intelligent conversational agent with context awareness.
- **Source Verification**: All AI responses are fact-checked against trusted sources using a hybrid verified/unverified mechanism.
- **Multimodal Input**: Support for Text, Voice (Speech-to-Text), and Image (OCR) inputs.
- **Cross-Platform**: Native performant apps for iOS (SwiftUI) and Android (Jetpack Compose).
- **Localization**: Full support for English, Arabic (RTL), and Urdu.

## 🚀 Quick Start

### Prerequisites
- **iOS**: Mac with Xcode 15+
- **Android**: Windows/Mac/Linux with Android Studio Hedgehog+

### Installation

1. **Clone the repository**:
   ```bash
   git clone --recursive https://github.com/ameedanxari/shamelagpt.git
   ```

2. **iOS Setup**:
   ```bash
   cd shamelagpt-ios
   pod install
   open ShamelaGPT.xcworkspace
   ```

3. **Android Setup**:
   - Open `shamelagpt-android` in Android Studio.
   - Sync Gradle and Run.

For detailed instructions, see the **[Onboarding Guide](docs/getting-started/ONBOARDING.md)**.

## 📚 Documentation

We maintain comprehensive documentation for the project:

- **[Documentation Index](docs/README.md)**: Start here.
- **[Contributing](CONTRIBUTING.md)**: How to contribute to the codebase.
- **[Architecture](docs/architecture/OVERVIEW.md)**: System design and decisions.
- **[Testing](docs/testing/)**: Test plans and strategies.

## 🧪 Testing

We strictly follow TDD practices.

- **run iOS Tests**: `Cmd+U` in Xcode.
- **run Android Tests**: `./gradlew test` in terminal.

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) to get started.

---
*Built with ❤️ by the ShamelaGPT Team*
