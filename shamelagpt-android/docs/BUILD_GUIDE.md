# ShamelaGPT Android - Build Guide

## Version: 1.0
## Date: 2025-11-04
## Target: Android API 26+ (Android 8.0 Oreo)

---

## 📚 Overview

This guide will help you build the ShamelaGPT Android app from scratch using the comprehensive technical documentation and structured build prompts provided in this repository.

---

## 📂 Documentation Structure

```
shamelagpt-android/docs/
├── 01_Architecture.md          # MVVM + Clean Architecture, Room, Koin
├── 02_Features.md              # Complete feature specifications
├── 03_API_Integration.md       # Retrofit, networking, offline support
├── 04_UI_UX.md                 # Jetpack Compose, Material Design 3
├── BUILD_GUIDE.md              # This file - how to build the app
├── TESTING_CHECKLIST.md        # Comprehensive testing guide
├── TROUBLESHOOTING.md          # Common issues and solutions
└── prompts/
    └── ALL_PROMPTS.md          # 10 sequential build prompts

Also reference:
../THEMING_UPDATE_GUIDE.md      # Emerald/teal color scheme from website
```

---

## 🎯 Build Strategy

### Phase-Based Approach

The build is divided into **10 sequential prompts**, each building on the previous work:

1. **Project Setup** → Foundation
2. **Data Layer** → Local persistence (Room)
3. **Networking Layer** → API integration (Retrofit)
4. **Chat Feature** → Core functionality
5. **Voice & Image Input** → Advanced input methods
6. **History Feature** → Conversation management
7. **Settings & Welcome** → App configuration
8. **Navigation Integration** → Connect all screens
9. **Polish & Testing** → Quality assurance
10. **Localization** → Multi-language support

---

## 🛠️ Prerequisites

### Required Tools
- **Operating System**: Windows 10/11, macOS, or Linux
- **Android Studio**: Hedgehog (2023.1.1) or later
- **JDK**: 17 or later
- **Android SDK**: API 34 (Android 14) for development
- **Minimum SDK**: API 26 (Android 8.0) for deployment

### Required Knowledge
- Kotlin programming language
- Jetpack Compose UI framework
- Android development basics
- Kotlin Coroutines and Flow
- Dependency injection concepts

### Optional Tools
- **Physical Android device** for testing (recommended)
- **Scrcpy** for device mirroring
- **Charles Proxy** or **HTTP Toolkit** for API debugging
- **Android Profiler** for performance analysis

---

## 🚀 How to Use This Guide

### Step 1: Read the Documentation

Before starting, familiarize yourself with:

1. **[01_Architecture.md](01_Architecture.md)** - Understand the app structure
2. **[02_Features.md](02_Features.md)** - Know what features to build
3. **[03_API_Integration.md](03_API_Integration.md)** - Understand API limitations
4. **[04_UI_UX.md](04_UI_UX.md)** - Learn the design system
5. **[../THEMING_UPDATE_GUIDE.md](../THEMING_UPDATE_GUIDE.md)** - Exact color specs

**Time investment**: 2-3 hours to read and understand

### Step 2: Execute Prompts Sequentially

Work through each prompt in the [prompts/](prompts/) folder **in order**:

```
prompts/ALL_PROMPTS.md
    ↓
Section 1: Project Setup
    ↓
Section 2: Data Layer
    ↓
Section 3: Networking Layer
    ↓
... and so on
```

### Step 3: Use Prompts with AI Assistants

Each prompt section is designed to be used with AI coding assistants like:
- **Claude** (Anthropic) - Recommended
- **ChatGPT** (OpenAI)
- **GitHub Copilot Chat**
- **Gemini** (Google)

**How to use**:
1. Open `prompts/ALL_PROMPTS.md`
2. Copy the entire PROMPT section (e.g., "PROMPT 1: Project Setup")
3. Paste it into your AI assistant
4. Follow the AI's instructions and generated code
5. Test the implementation
6. Move to the next prompt

### Step 4: Test After Each Phase

After completing each prompt:
1. Build the project (Build → Make Project)
2. Run on emulator or device (Shift + F10)
3. Test the new functionality
4. Fix any errors before proceeding

### Step 5: Refer to Documentation

Throughout the build process:
- **Architecture questions** → `01_Architecture.md`
- **Feature specifications** → `02_Features.md`
- **API issues** → `03_API_Integration.md`
- **UI/UX questions** → `04_UI_UX.md`
- **Color/theming** → `../THEMING_UPDATE_GUIDE.md`
- **Bugs/issues** → `TROUBLESHOOTING.md`

---

## 📋 Build Timeline Estimate

| Phase | Prompt | Estimated Time | Difficulty |
|-------|--------|----------------|------------|
| 1 | Project Setup | 2-3 hours | Easy |
| 2 | Data Layer (Room) | 3-4 hours | Medium |
| 3 | Networking Layer (Retrofit) | 2-3 hours | Medium |
| 4 | Chat Feature (Compose) | 4-6 hours | Hard |
| 5 | Voice & Image Input | 3-4 hours | Medium |
| 6 | History Feature | 2-3 hours | Easy |
| 7 | Settings & Welcome | 2-3 hours | Easy |
| 8 | Navigation Integration | 2-3 hours | Medium |
| 9 | Polish & Testing | 4-6 hours | Medium |
| 10 | Localization | 2-3 hours | Easy |

**Total Estimated Time**: 28-40 hours (1 week of focused work)

---

## 🎨 Development Workflow

### Recommended Workflow

```
┌─────────────────────────────────────┐
│ 1. Read Prompt Section              │
│    - Understand objectives          │
│    - Note prerequisites             │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 2. Use AI Assistant                 │
│    - Copy prompt to AI              │
│    - Follow AI's guidance           │
│    - Generate code                  │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 3. Implement in Android Studio      │
│    - Create files                   │
│    - Write/paste code               │
│    - Resolve build errors           │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 4. Test Implementation              │
│    - Build project                  │
│    - Run on emulator/device         │
│    - Verify functionality           │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 5. Git Commit                       │
│    - Commit working code            │
│    - Use descriptive message        │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 6. Move to Next Prompt              │
└─────────────────────────────────────┘
```

### Git Strategy

Commit after each completed prompt:

```bash
# After completing prompt 01
git add .
git commit -m "feat: complete project setup (Android)"
git push

# After completing prompt 02
git add .
git commit -m "feat: implement data layer with Room (Android)"
git push

# ... and so on
```

---

## 🧪 Testing Strategy

### After Each Prompt
- ✅ Project builds without errors
- ✅ New feature works as expected
- ✅ Previous features still work (no regressions)
- ✅ No compiler warnings (aim for zero warnings)

### After Completing All Prompts
Use **[TESTING_CHECKLIST.md](TESTING_CHECKLIST.md)** for comprehensive testing:
- Feature validation
- API integration testing
- Offline mode testing
- RTL layout testing
- Accessibility testing
- Performance testing

---

## 🎯 Success Criteria

### Minimum Viable Product (MVP)
After completing all 10 prompts, your app should have:

✅ **Core Features**:
- Chat interface with AI responses
- Message history
- Voice input (local speech-to-text)
- Image OCR input (ML Kit)
- Conversation management
- Multi-language support (English, Arabic)
- RTL layout support

✅ **Quality Benchmarks**:
- App builds without errors
- All features functional
- Smooth UI/UX (60 FPS)
- No crashes in normal usage
- Offline mode works
- Properly localized

---

## 📱 Running the App

### On Emulator
```bash
# Open project in Android Studio
cd shamelagpt-android
studio .

# Or from command line
./gradlew installDebug

# Run on connected emulator
adb shell am start -n com.shamelagpt/.MainActivity
```

### On Physical Device
1. Enable Developer Options on device:
   - Settings → About Phone → Tap "Build number" 7 times
2. Enable USB Debugging:
   - Settings → Developer Options → USB Debugging
3. Connect device via USB
4. Accept USB debugging prompt on device
5. Run from Android Studio (Shift + F10)

### Build Variants
- **Debug**: Development build with logging
- **Release**: Production build (requires signing)

---

## 🐛 Troubleshooting

### Build Errors
Refer to **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** for:
- Gradle sync issues
- Dependency conflicts
- API problems
- Runtime errors
- Performance issues

### Getting Help
1. Check `TROUBLESHOOTING.md` first
2. Review relevant documentation section
3. Search error message on Stack Overflow
4. Ask AI assistant for help with specific error
5. Check Android Developers documentation

---

## 🔄 Iteration and Enhancement

### After MVP Completion

Once you have a working MVP, you can:

1. **Add Phase 2 Features**:
   - User authentication
   - Cloud sync
   - Push notifications (FCM)
   - Share intent handling

2. **Optimize Performance**:
   - Profile with Android Profiler
   - Optimize Room queries
   - Reduce APK size
   - Improve startup time

3. **Enhance UI/UX**:
   - Add animations
   - Improve transitions
   - Add haptic feedback
   - Refine Material Design 3 theming

4. **Expand Testing**:
   - Add unit tests (JUnit)
   - Add UI tests (Compose Testing)
   - Add integration tests
   - Increase code coverage

---

## 📖 Additional Resources

### Official Documentation
- [Android Developers](https://developer.android.com/)
- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [Material Design 3](https://m3.material.io/)
- [Kotlin Documentation](https://kotlinlang.org/docs/home.html)
- [Room Database](https://developer.android.com/training/data-storage/room)
- [Retrofit](https://square.github.io/retrofit/)

### Tutorials
- [Android Developers Codelabs](https://developer.android.com/codelabs)
- [Philipp Lackner YouTube](https://www.youtube.com/c/PhilippLackner)
- [Coding in Flow](https://codinginflow.com/)

### Communities
- [r/androiddev](https://www.reddit.com/r/androiddev/)
- [Kotlin Slack](https://surveys.jetbrains.com/s3/kotlin-slack-sign-up)
- [Android Developers Discord](https://discord.gg/android)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/android)

---

## ✅ Checklist: Before You Start

- [ ] Windows/macOS/Linux with 16GB+ RAM
- [ ] Android Studio Hedgehog or later installed
- [ ] JDK 17+ installed and configured
- [ ] Android SDK 34 installed
- [ ] Android Emulator configured (or physical device ready)
- [ ] Git installed and configured
- [ ] Read all 4 main documentation files
- [ ] Understand the API limitations (conversation endpoints don't work)
- [ ] Ready to commit 28-40 hours over 1 week
- [ ] AI assistant access (Claude, ChatGPT, etc.)
- [ ] Coffee/tea supply secured ☕

---

## 🎊 Final Notes

### Philosophy
This project uses a **documentation-driven development** approach:
1. Comprehensive technical docs define the target
2. Sequential prompts guide the implementation
3. Testing ensures quality at each step
4. Final product matches specifications

### Flexibility
While the prompts are sequential, you can:
- Skip features you don't need
- Modify implementations to suit your needs
- Add custom features beyond the MVP
- Use different libraries if preferred (though Koin/Room/Retrofit are recommended)

### Community
If you build this app and want to share:
- Contribute improvements to the docs
- Share your experience
- Help others troubleshoot
- Build upon the foundation

---

## 🚀 Ready to Build?

1. Start with **[prompts/ALL_PROMPTS.md](prompts/ALL_PROMPTS.md)** - Section 1
2. Follow the instructions
3. Build something amazing!

**Good luck with your build! 🎉**

---

## 📞 Quick Reference

| Need | Location |
|------|----------|
| Architecture overview | `01_Architecture.md` |
| Feature specifications | `02_Features.md` |
| API documentation | `03_API_Integration.md` |
| UI/UX guidelines | `04_UI_UX.md` |
| Color scheme | `../THEMING_UPDATE_GUIDE.md` |
| Build prompts | `prompts/ALL_PROMPTS.md` |
| Testing guide | `TESTING_CHECKLIST.md` |
| Troubleshooting | `TROUBLESHOOTING.md` |

---

*Built with ❤️ for the Muslim community. May this app help spread authentic Islamic knowledge.*
