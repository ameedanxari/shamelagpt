# ShamelaGPT Android - Quick Start Guide

## 🚀 Installation (30 seconds)

```bash
# Navigate to project
cd /Users/macintosh/Documents/Projects/ShamelaGPT/shamelagpt-android

# Build APK
./gradlew assembleDebug

# Install on device
adb install app/build/outputs/apk/debug/app-debug.apk
```

**APK Location**: `app/build/outputs/apk/debug/app-debug.apk` (58 MB)

---

## ✅ What's Built

All 10 prompts completed - **100% functional Android app**

### Features Ready to Test
1. ✅ **Chat** - Send/receive AI messages
2. ✅ **Voice Input** - Speak in English or Arabic
3. ✅ **Image OCR** - Extract text from photos
4. ✅ **History** - View past conversations
5. ✅ **Settings** - Change language (EN/AR)
6. ✅ **RTL Support** - Arabic layouts
7. ✅ **Dark Mode** - System theme support
8. ✅ **Offline** - Works without internet

---

## 🧪 Quick Test (5 minutes)

1. **Launch App** → See welcome screen (first time only)
2. **Send Message** → Type "What is Islam?" → Send
3. **Voice Input** → Tap mic → Speak → See text
4. **Image OCR** → Tap camera → Take photo → Extract text
5. **Switch Language** → Settings → Language → العربية
6. **Check RTL** → Navigate around → Everything mirrors
7. **View History** → History tab → See past chats
8. **Dark Mode** → System settings → Toggle dark mode

---

## 📁 Key Files

### Source Code (74 Kotlin files)
```
app/src/main/java/com/shamelagpt/android/
├── presentation/
│   ├── chat/ChatScreen.kt           # Main chat UI
│   ├── history/HistoryScreen.kt     # Conversation list
│   ├── settings/SettingsScreen.kt   # App settings
│   └── welcome/WelcomeScreen.kt     # First-time screen
├── domain/usecase/
│   └── SendMessageUseCase.kt        # Chat business logic
├── data/repository/
│   ├── ChatRepositoryImpl.kt        # API integration
│   └── ConversationRepositoryImpl.kt # Database ops
└── core/
    ├── util/VoiceInputManager.kt    # Voice recognition
    └── util/OCRManager.kt            # Image text extraction
```

### Configuration
- **API**: `core/util/Constants.kt` (BASE_URL)
- **Theme**: `presentation/theme/Color.kt` (Brand colors)
- **Strings**: `res/values/strings.xml` (English)
- **Arabic**: `res/values-ar/strings.xml` (Arabic)

---

## 🔧 Common Tasks

### Change API URL
Edit `app/src/main/java/com/shamelagpt/android/core/util/Constants.kt`:
```kotlin
const val BASE_URL = "https://your-api.com/"
```

### Update Colors
Edit `app/src/main/java/com/shamelagpt/android/presentation/theme/Color.kt`:
```kotlin
val md_theme_light_primary = Color(0xFF1B5E20) // Deep Green
```

### Add New String
Edit `app/src/main/res/values/strings.xml`:
```xml
<string name="new_feature">My New Feature</string>
```

### Debug Build
```bash
./gradlew assembleDebug
```

### Release Build (Signed)
```bash
./gradlew assembleRelease
```

---

## 📚 Full Documentation

- **[README.md](README.md)** - Complete project overview
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md)** - Detailed build instructions
- **[docs/TESTING_CHECKLIST.md](docs/TESTING_CHECKLIST.md)** - Test scenarios
- **[docs/prompts/ALL_PROMPTS.md](docs/prompts/ALL_PROMPTS.md)** - Build prompts used

---

## ❓ Troubleshooting

### Build Fails
```bash
./gradlew clean
./gradlew assembleDebug --stacktrace
```

### ADB Not Found
```bash
# macOS
export PATH=$PATH:~/Library/Android/sdk/platform-tools

# Windows
set PATH=%PATH%;C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools
```

### Device Not Detected
```bash
adb devices
# If empty, enable USB debugging on device
```

### App Crashes on Launch
```bash
adb logcat | grep ShamelaGPT
# Check logs for errors
```

---

## 🎯 Next Steps

1. **Test thoroughly** - Run through test scenarios
2. **Customize** - Update colors, strings, branding
3. **Add features** - Implement Phase 2 roadmap
4. **Optimize** - Reduce APK size, improve performance
5. **Release** - Prepare for Play Store

---

**Need Help?** Check the full documentation in the `docs/` folder.
