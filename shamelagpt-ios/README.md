# ShamelaGPT iOS

An AI-powered Islamic knowledge app built with SwiftUI and Clean Architecture.

## 📱 Project Status

**Note**: This is the iOS project for ShamelaGPT. The Android version is complete and functional. The iOS implementation has the foundation set up but requires Xcode to complete the build.

- **Platform**: iOS 15.0+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM + Coordinator Pattern

## 🏗️ Architecture

**Clean Architecture** with MVVM pattern:
- **App Layer**: Entry point and app-wide configuration
- **Core Layer**: DI, Networking, Storage, Utilities
- **Domain Layer**: Models, Use Cases, Repository interfaces
- **Data Layer**: Repository implementations, Core Data, API clients
- **Presentation Layer**: Views, ViewModels, Coordinators, Components

**Tech Stack**:
- SwiftUI (UI)
- Core Data (Database)
- URLSession (Networking)
- Swinject (Dependency Injection)
- swift-markdown-ui (Markdown Rendering)
- Combine (Reactive Programming)

## 📁 Project Structure

```
ShamelaGPT/
├── App/
│   ├── ShamelaGPTApp.swift
│   └── DependencyContainer.swift
├── Core/
│   ├── DependencyInjection/
│   ├── Networking/
│   ├── Storage/
│   └── Utilities/
├── Domain/
│   ├── Models/
│   ├── UseCases/
│   └── Repositories/
├── Data/
│   ├── Repositories/
│   ├── DataSources/
│   └── CoreData/
└── Presentation/
    ├── Coordinators/
    ├── Scenes/
    ├── Components/
    └── Theme/
```

## ✨ Planned Features

The iOS app will include the same features as the Android version:

### Core Features
- 💬 **Real-time Chat** - AI-powered Islamic knowledge Q&A
- 🎤 **Voice Input** - English & Arabic speech recognition
- 📷 **Image OCR** - Extract text from images using Vision framework
- 📜 **Conversation History** - Save and manage past conversations
- 🌍 **Multi-language** - Full support for English and Arabic
- 🌙 **Dark Mode** - Native iOS theming

### Advanced Features
- **RTL Support** - Automatic layout mirroring for Arabic
- **Offline Mode** - Local database with Core Data
- **Deep Linking** - Universal links support
- **Handoff** - Continuity between devices
- **Pull-to-Refresh** - Conversation list updates
- **Smooth Animations** - Native iOS animations

## 🚀 Getting Started

### Prerequisites
- macOS with Xcode 15+ installed
- iOS 15.0+ deployment target
- Swift 5.9+
- CocoaPods or Swift Package Manager

### Setup Instructions

1. **Clone the repository**
   ```bash
   cd /Users/macintosh/Documents/Projects/ShamelaGPT/shamelagpt-ios
   ```

2. **Open in Xcode**
   ```bash
   open shamelagpt.xcodeproj
   # or
   xed .
   ```

3. **Add Swift Package Dependencies**
   - Open project in Xcode
   - Go to File → Add Packages
   - Add the following packages:
     - Swinject: `https://github.com/Swinject/Swinject` (v2.10.0+)
     - swift-markdown-ui: `https://github.com/gonzalezreal/swift-markdown-ui` (v2.0.0+)

4. **Configure Info.plist**
   
   Add these permissions:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>ShamelaGPT needs camera access to scan text from images.</string>
   
   <key>NSMicrophoneUsageDescription</key>
   <string>ShamelaGPT needs microphone access for voice input.</string>
   
   <key>NSPhotoLibraryUsageDescription</key>
   <string>ShamelaGPT needs photo library access to select images.</string>
   ```

5. **Build and Run**
   - Select a simulator or device
   - Press Cmd+R to build and run

## 📚 Documentation

### Build Documentation
- **[BUILD_GUIDE.md](docs/BUILD_GUIDE.md)** - Complete build instructions
- **[ALL_PROMPTS.md](docs/prompts/ALL_PROMPTS.md)** - 10 sequential build prompts
- **[TESTING_CHECKLIST.md](docs/TESTING_CHECKLIST.md)** - Testing scenarios

### Technical Documentation
- **[01_Architecture.md](docs/01_Architecture.md)** - Architecture deep dive
- **[02_Features.md](docs/02_Features.md)** - Feature specifications
- **[03_API_Integration.md](docs/03_API_Integration.md)** - API documentation
- **[04_UI_UX.md](docs/04_UI_UX.md)** - UI/UX guidelines
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 🔧 Configuration

### API Endpoint
Base URL: `https://api.shamelagpt.com/`

**Working Endpoints**:
- `GET /api/health` - Health check
- `POST /api/chat` - Send message

**Note**: Conversation management endpoints return 500 errors, so all conversation data is stored locally using Core Data.

### Colors (Assets.xcassets)
- **Primary**: #1B5E20 (Deep Green)
- **PrimaryLight**: #4C8C4A
- **Accent**: #D4AF37 (Gold)

## 🧪 Testing

### Manual Testing
1. **First Launch**: Welcome screen should appear
2. **Chat**: Send a message and receive AI response
3. **Voice Input**: Tap mic, speak, see transcription
4. **Image OCR**: Tap camera, take photo, extract text
5. **Language Switch**: Settings → Language → العربية
6. **RTL Layout**: Verify Arabic text displays right-to-left
7. **History**: View past conversations, swipe to delete

### Test Scenarios
See [TESTING_CHECKLIST.md](docs/TESTING_CHECKLIST.md) for comprehensive test scenarios.

## 📦 Build Information

- **Bundle ID**: com.shamelagpt.ios
- **Min iOS Version**: 15.0
- **Swift Version**: 5.9+
- **Xcode Version**: 15.0+

## 🛣️ Roadmap

### Phase 1 (In Progress)
Following the 10-prompt build plan:
1. ✅ Project Setup
2. ✅ Data Layer (Core Data)
3. ✅ Networking Layer (URLSession)
4. ⏳ Chat Feature (SwiftUI)
5. ⏳ Voice & Image Input
6. ⏳ History Feature
7. ⏳ Settings & Welcome
8. ⏳ Navigation Integration
9. ⏳ Polish & Testing
10. ⏳ Localization

### Phase 2 (Planned)
- User authentication (Firebase Auth)
- Cloud sync (CloudKit or Firebase)
- Push notifications (APNs)
- Advanced search
- Export conversations
- App Store release
- Widgets and App Clips

## 🔗 Related Projects

- **Android App**: [shamelagpt-android](../shamelagpt-android) - Complete and functional
- **Backend API**: `https://api.shamelagpt.com/`

## 📝 License

Built for the Muslim community. May this app help spread authentic Islamic knowledge.

---

**Built with ❤️ using SwiftUI**

For the complete and functional version, see the [Android app](../shamelagpt-android).
