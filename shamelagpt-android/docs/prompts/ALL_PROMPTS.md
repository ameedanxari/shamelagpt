# ShamelaGPT Android - Complete Build Prompts

This file contains all 10 sequential prompts to build the ShamelaGPT Android app. Use each prompt with your AI assistant in order.

---

# PROMPT 1: Project Setup

## Objective
Create the Android Studio project with proper structure, dependencies, and configuration.

## Prerequisites
- Android Studio Iguana or later
- Basic understanding of Kotlin and Jetpack Compose

## Instructions to AI Assistant

I want to create an Android app called "ShamelaGPT" - an AI-powered Islamic knowledge app. Please help me set up the project following these requirements:

### Project Configuration
- **Name**: ShamelaGPT
- **Package Name**: com.shamelagpt.android
- **Min SDK**: 26 (Android 8.0)
- **Target SDK**: 34 (Android 14)
- **Language**: Kotlin
- **UI Toolkit**: Jetpack Compose (Material 3)
- **Build System**: Gradle (Kotlin DSL)

### Folder Structure
Create this package structure under `com.shamelagpt.android`:
```
com.shamelagpt.android/
├── ShamelaGPTApplication.kt
├── core/
│   ├── di/ (Koin modules)
│   ├── network/
│   ├── database/
│   └── util/
├── domain/
│   ├── model/
│   ├── usecase/
│   └── repository/
├── data/
│   ├── repository/
│   ├── remote/
│   └── local/
├── presentation/
│   ├── theme/
│   ├── navigation/
│   ├── components/
│   └── screens/
└── MainActivity.kt
```

### Dependencies (libs.versions.toml)
Add these libraries:
1. **Jetpack Compose** (Material 3)
2. **Koin** (Dependency Injection)
3. **Retrofit** + **OkHttp** (Networking)
4. **Room** (Local Database)
5. **Coroutines** (Async)
6. **Coil** (Image Loading)
7. **Navigation Compose**

### Permissions (AndroidManifest.xml)
Add these permissions:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
```

### Colors (Theme.kt)
Define these colors:
- Primary: #10B981 (Emerald-500)
- PrimaryContainer: #D1FAE5
- Secondary: #F59E0B (Amber-500)

### Initial Files
1. `ShamelaGPTApplication.kt` - App entry point (setup Koin)
2. `MainActivity.kt` - Host Activity
3. `Theme.kt` - Material 3 theme setup

Please provide step-by-step instructions and code for setting up this project.

## Success Criteria
- [ ] Project builds without errors
- [ ] Folder structure matches specification
- [ ] Dependencies resolved
- [ ] App launches with "Hello World" screen

---

# PROMPT 2: Data Layer Implementation

## Objective
Implement Room database, entities, and repository pattern for local storage.

## Context
I have the ShamelaGPT project set up. Now I need to implement the data layer using Room to store conversations and messages locally.

## Instructions to AI Assistant

Please help me implement the data layer with these requirements:

### Room Database
Create `AppDatabase` with these entities:

**ConversationEntity**:
- `id`: String (UUID)
- `threadId`: String?
- `title`: String
- `createdAt`: Long (Timestamp)
- `updatedAt`: Long

**MessageEntity**:
- `id`: String (UUID)
- `conversationId`: String (Foreign Key)
- `content`: String
- `isUserMessage`: Boolean
- `timestamp`: Long
- `sources`: String? (JSON string)

### DAOs
Create `ConversationDao` and `MessageDao` with standard CRUD operations (suspend functions and Flow).

### Domain Models
Create clean domain models:
```kotlin
data class Conversation(
    val id: String,
    val title: String,
    val messages: List<Message> = emptyList(),
    // ...
)

data class Message(
    val id: String,
    val content: String,
    val isUserMessage: Boolean,
    // ...
)
```

### Repository
Create `ChatRepository` interface and implementation.

### Dependency Injection
Register database and repository in Koin module.

Please provide complete implementation.

## Success Criteria
- [ ] Room database created
- [ ] Can save/fetch conversations
- [ ] Can save/fetch messages
- [ ] Data persists after app restart

---

# PROMPT 3: Networking Layer Implementation

## Objective
Implement API client using Retrofit to communicate with ShamelaGPT API.

## Context
Base URL: `https://api.shamelagpt.com`. Only `/api/chat` works.

## Instructions to AI Assistant

Please help me implement the networking layer:

### API Service
Create `ApiService` interface with Retrofit:
- `GET /api/health`
- `POST /api/chat`

### Models
Create DTOs (Data Transfer Objects) for requests and responses using Kotlin Serialization or Gson.

### Response Parsing
The API returns markdown with sources at the end. Create a parser to extract:
1. Clean content
2. List of `Source` objects

### Repository Update
Update `ChatRepositoryImpl` to:
1. Call API
2. Parse response
3. Save to local DB
4. Emit `Flow<Resource<Message>>`

### Dependency Injection
Register Retrofit, OkHttp, and ApiService in Koin.

Please provide complete implementation.

## Success Criteria
- [ ] Can call `/api/health`
- [ ] Can send message to `/api/chat`
- [ ] Can parse response and sources

---

# PROMPT 4: Chat Feature Implementation

## Objective
Build the main chat screen with Jetpack Compose.

## Instructions to AI Assistant

Please help me implement the chat feature:

### ChatViewModel
- `StateFlow` for UI state (messages, loading, error)
- Functions: `sendMessage`, `loadMessages`

### ChatScreen (Compose)
- `Scaffold` with TopBar
- `LazyColumn` for messages (reverse layout)
- `TextField` and `IconButton` for input

### Components
- **MessageBubble**:
  - User: Right-aligned, Emerald background
  - AI: Left-aligned, Gray background
  - Markdown support (use `richtext-ui-material3` library)
- **InputBar**:
  - Text field
  - Send button
  - Mic/Camera buttons

### State Management
Use `collectAsStateWithLifecycle` in the UI.

Please provide complete implementation.

## Success Criteria
- [ ] Chat screen displays
- [ ] Can send/receive messages
- [ ] Markdown renders correctly

---

# PROMPT 5: Voice & Image Input Implementation

## Objective
Add voice input (SpeechRecognizer) and image OCR (ML Kit).

## Instructions to AI Assistant

Please help me implement advanced inputs:

### VoiceInputManager
- Use `SpeechRecognizer`
- Handle `RECORD_AUDIO` permission
- Expose `StateFlow<String>` for transcription

### OCRManager
- Use `com.google.mlkit:text-recognition`
- Handle `CAMERA` permission
- Process `Bitmap` or `ImageProxy`

### UI Integration
- Add Mic button to InputBar (hold to record?)
- Add Camera button (opens system camera or custom implementation)
- Update `ChatViewModel` to handle these inputs

Please provide complete implementation.

## Success Criteria
- [ ] Can record voice and see text
- [ ] Can take photo and extract text

---

# PROMPT 6: History Feature Implementation

## Objective
Build conversation history screen.

## Instructions to AI Assistant

Please help me implement the history feature:

### HistoryViewModel
- Load conversations from repository
- Delete conversation function

### HistoryScreen
- List of conversations
- Swipe-to-delete
- Tap to navigate to chat

### Navigation
- Update `NavHost` to support navigation between History and Chat.

Please provide complete implementation.

## Success Criteria
- [ ] History list displays
- [ ] Can delete conversation
- [ ] Can navigate to chat

---

# PROMPT 7: Settings & Welcome Screens

## Objective
Implement welcome screen and settings.

## Instructions to AI Assistant

Please help me implement these screens:

### WelcomeScreen
- Show on first launch (DataStore preferences)
- "Get Started" button

### SettingsScreen
- Language selection (English/Arabic)
- Support link (PayPal)
- About/Privacy

### Localization
- Support `res/values-ar/strings.xml`
- Handle app language change (LocaleManager)

Please provide complete implementation.

## Success Criteria
- [ ] Welcome screen shows once
- [ ] Settings screen functional
- [ ] Language switching works

---

# PROMPT 8: Navigation Integration

## Objective
Connect all screens using Navigation Compose.

## Instructions to AI Assistant

Please help me implement complete navigation:

### Navigation Graph
- Routes: `Welcome`, `Chat`, `History`, `Settings`
- Arguments: `conversationId` for Chat route

### Bottom Navigation
- `Scaffold` with `BottomBar`
- Items: Chat, History, Settings

### Deep Linking
- Handle `shamelagpt://` links

Please provide complete implementation.

## Success Criteria
- [ ] Bottom navigation works
- [ ] Can navigate between all screens

---

# PROMPT 9: Polish & Testing

## Objective
Add final polish, animations, and testing.

## Instructions to AI Assistant

Please help me polish the app:

### RTL Support
- Ensure layouts mirror correctly for Arabic

### Dark Mode
- Verify colors in dark theme

### Testing
- Unit tests for ViewModel and Repository (JUnit4, MockK)
- UI tests for ChatScreen (Compose Test Rule)

Please provide complete implementation.

## Success Criteria
- [ ] RTL works
- [ ] Dark mode works
- [ ] Tests pass
