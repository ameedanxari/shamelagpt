# ShamelaGPT Android

An AI-powered Islamic knowledge app built with Jetpack Compose and Clean Architecture.

## 🎉 Build Status

✅ **COMPLETE** - All 10 prompts executed successfully

- **APK**: `app/build/outputs/apk/debug/app-debug.apk` (58 MB)
- **Version**: 1.0.0
- **Min SDK**: Android 8.0 (API 26)
- **Target SDK**: Android 14 (API 34)

## 🚀 Quick Start

### Installation
```bash
# Build the app
./gradlew clean assembleDebug

# Install on device
adb install app/build/outputs/apk/debug/app-debug.apk

# Launch the app
adb shell am start -n com.shamelagpt.android/.presentation.MainActivity
```

## ✨ Features

### Core Features
- 💬 **Real-time Chat** - AI-powered Islamic knowledge Q&A
- 🎤 **Voice Input** - English & Arabic speech recognition
- 📷 **Image OCR** - Extract text from images using ML Kit
- 📜 **Conversation History** - Save and manage past conversations
- 🌍 **Multi-language** - Full support for English and Arabic
- 🌙 **Dark Mode** - Material Design 3 theming

### Advanced Features
- **RTL Support** - Automatic layout mirroring for Arabic
- **Offline Mode** - Local database with Room
- **Deep Linking** - `shamelagpt://chat/{conversationId}`
- **Splash Screen** - Modern Android 12+ splash
- **Pull-to-Refresh** - Conversation list updates
- **Smooth Animations** - Spring animations throughout

## 🏗️ Architecture

**Clean Architecture** with MVVM pattern:
- **Presentation Layer**: Jetpack Compose UI (25 screens/components)
- **Domain Layer**: Use cases, repositories (7 use cases)
- **Data Layer**: Room + Retrofit (local + remote)
- **Core Layer**: Utilities, DI with Koin (3 modules)

**Tech Stack**:
- Jetpack Compose (UI)
- Room (Database)
- Retrofit + OkHttp (Networking)
- Koin (Dependency Injection)
- ML Kit (OCR)
- Kotlin Coroutines + Flow

## 📁 Project Structure

```
app/src/main/java/com/shamelagpt/android/
├── ShamelaGPTApplication.kt
├── core/
│   ├── database/     # Room database configuration
│   ├── di/           # Koin dependency injection modules
│   ├── network/      # Retrofit, NetworkMonitor
│   ├── preferences/  # SharedPreferences manager
│   └── util/         # Utilities (VoiceInput, OCR, etc.)
├── data/
│   ├── local/        # DAOs, Entities
│   ├── remote/       # API service, DTOs
│   ├── mapper/       # Entity ↔ Domain mappers
│   └── repository/   # Repository implementations
├── domain/
│   ├── model/        # Domain models
│   ├── repository/   # Repository interfaces
│   └── usecase/      # Business logic
└── presentation/
    ├── chat/         # Chat screen & components
    ├── history/      # Conversation history
    ├── settings/     # Settings & language selection
    ├── welcome/      # Welcome screen
    ├── navigation/   # Nav graph & routes
    ├── components/   # Reusable UI components
    └── theme/        # Material Design 3 theme
```

## 📚 Documentation

- **[BUILD_GUIDE.md](docs/BUILD_GUIDE.md)** - Complete build instructions
- **[TESTING_CHECKLIST.md](docs/TESTING_CHECKLIST.md)** - Testing scenarios
- **[ALL_PROMPTS.md](docs/prompts/ALL_PROMPTS.md)** - 10 sequential build prompts
- **[01_Architecture.md](docs/01_Architecture.md)** - Architecture deep dive
- **[02_Features.md](docs/02_Features.md)** - Feature specifications
- **[03_API_Integration.md](docs/03_API_Integration.md)** - API documentation
- **[04_UI_UX.md](docs/04_UI_UX.md)** - UI/UX guidelines

## 🧪 Testing

### Test the App
1. **First Launch**: Welcome screen should appear
2. **Chat**: Send a message and receive AI response
3. **Voice Input**: Tap mic, speak, see transcription
4. **Image OCR**: Tap camera, take photo, extract text
5. **Language Switch**: Settings → Language → العربية
6. **RTL Layout**: Verify Arabic text displays right-to-left
7. **History**: View past conversations, swipe to delete

### Test Scenarios
See [TESTING_CHECKLIST.md](docs/TESTING_CHECKLIST.md) for comprehensive test scenarios.

## 🔧 Configuration

### API Endpoint
Base URL: `https://api.shamelagpt.com/`

**Working Endpoints**:
- `GET /api/health` - Health check
- `POST /api/chat` - Send message

**Note**: Conversation management endpoints return 500 errors, so all conversation data is stored locally.

### Permissions Required
- `INTERNET` - API communication
- `RECORD_AUDIO` - Voice input

## 🌍 Localization

- **English** (en): 95+ strings
- **Arabic** (ar): 95+ strings

Language selection persists across app restarts.

## 📦 Build Information

- **Build Tool**: Gradle 8.7
- **Kotlin**: 2.0.20
- **Compose**: 1.7.5
- **Min SDK**: 26 (Android 8.0)
- **Target SDK**: 34 (Android 14)
- **Package**: com.shamelagpt.android

## 🛣️ Roadmap

### Phase 1 (Complete) ✅
- Chat interface
- Voice & image input
- Conversation history
- Settings & localization
- Navigation & polish

### Phase 2 (Planned)
- User authentication
- Cloud sync
- Push notifications
- Advanced search
- Export conversations
- Play Store release

## 📝 License

Built for the Muslim community. May this app help spread authentic Islamic knowledge.

---

**Built with ❤️ using Jetpack Compose**
