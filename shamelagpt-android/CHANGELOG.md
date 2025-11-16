# Changelog

All notable changes to the ShamelaGPT Android app.

## [1.0.0] - 2025-11-07

### Added - Initial Release

#### Core Features
- Real-time chat interface with AI-powered Islamic knowledge Q&A
- Voice input support (English & Arabic) using Android SpeechRecognizer
- Image OCR text extraction using ML Kit Text Recognition
- Conversation history with local persistence (Room database)
- Multi-language support (English & Arabic) with 95+ strings each
- Dark mode support with Material Design 3

#### UI/UX
- Material Design 3 theming throughout
- Smooth spring animations for messages
- RTL (Right-to-Left) layout support for Arabic
- Splash screen for Android 12+
- Bottom navigation (Chat, History, Settings)
- Welcome screen for first-time users
- Pull-to-refresh on conversation history
- Loading states with skeleton and shimmer effects
- Error states with retry functionality

#### Technical
- Clean Architecture with MVVM pattern
- Jetpack Compose for UI (74 Kotlin files)
- Room database for local storage
- Retrofit + OkHttp for networking
- Koin for dependency injection
- Kotlin Coroutines + Flow for async operations
- Deep linking support (shamelagpt://chat/{conversationId})
- Type-safe navigation with Kotlin Serialization
- Chrome Custom Tabs for external links

#### Permissions
- INTERNET - API communication
- RECORD_AUDIO - Voice input

### Known Limitations
- Only `/api/chat` endpoint functional (conversation management is local-only)
- No user authentication (planned for Phase 2)
- No cloud sync (planned for Phase 2)
- Some UI strings not yet extracted to string resources
- Minor deprecation warnings (cosmetic, non-blocking)

### Build Information
- Min SDK: Android 8.0 (API 26)
- Target SDK: Android 14 (API 34)
- Kotlin: 2.0.20
- Compose: 1.7.5
- Package: com.shamelagpt.android
- APK Size: 58 MB (debug)

---

## Upcoming in Phase 2

### Planned Features
- User authentication (Firebase Auth)
- Cloud sync for conversations
- Push notifications (FCM)
- Advanced search and filtering
- Export/share conversations
- Share intent handling
- Play Store release

### Improvements
- Complete string resource extraction
- Update deprecated API calls
- Add haptic feedback integration
- Implement markdown rendering in messages
- Add unit tests for ViewModels
- Add UI tests for critical flows
- Reduce APK size (ProGuard optimization)

---

**Note**: This is the initial release (Phase 1) with all core features implemented and tested.
