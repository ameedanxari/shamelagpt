# ShamelaGPT Android - Complete Build Prompts

This file contains 10 sequential prompts to build the ShamelaGPT Android app. This guide ensures the Android application maintains full feature parity and architectural consistency with the iOS version.

---

# PROMPT 1: Project Setup & Foundation

## Objective
Establish the Android Studio project with a robust Material 3 theme, Koin for Dependency Injection, and a clean package structure.

## Instructions to AI Assistant
Help me set up the "ShamelaGPT" Android project following these specifications:

### Project Config
- **Language**: Kotlin with Gradle Kotlin DSL (.kts).
- **UI**: Jetpack Compose (Material 3).
- **Min SDK**: 26 | **Target SDK**: 34.
- **Package**: `com.shamelagpt.android`.

### Package Structure
```
com.shamelagpt.android/
├── core/
│   ├── di/          # Koin modules
│   ├── network/     # Retrofit & SSE logic
│   ├── database/    # Room DB setup
│   └── util/        # Logger, Formatters
├── domain/
│   ├── model/       # Clean Domain Entities
│   ├── usecase/     # Business logic
│   └── repository/  # Repository Interfaces
├── data/
│   ├── repository/  # Repository Impls
│   ├── remote/      # API Clients & DTOs
│   └── local/       # Room DAOs & Entities
└── presentation/
    ├── theme/       # Emerald & Amber Theme
    ├── navigation/  # Compose Navigation
    └── screens/     # ViewModels & Composables
```

### Dependencies (libs.versions.toml)
Include: Koin (Android/Compose), Retrofit, OkHttp, Room (with KSP), Coroutines, Coil, Lifecycle ViewModel/Compose.

### Theme (Emerald & Amber)
- **Primary**: #10B981 (Emerald Green)
- **Secondary**: #F59E0B (Amber/Gold)
- Implement light/dark variants using Material 3 semantic tokens.

---

# PROMPT 2: Local Persistence Layer

## Objective
Implement a robust Room database to store chat history locally, matching the iOS Core Data schema.

## Instructions to AI Assistant
Implement the local data layer:

### Room Entities
1. **ConversationEntity**: `id` (UUID), `threadId`, `title`, `updatedAt`, `createdAt`.
2. **MessageEntity**: `id` (UUID), `conversationId` (FK), `content`, `isUserMessage`, `timestamp`, `sources` (JSON string).

### DAOs
- Support Flow-oriented queries (e.g., `getMessagesForConversation(id): Flow<List<MessageEntity>>`).
- Support atomic inserts/deletes.

### Domain Models & Mappers
Create clean `Conversation` and `Message` domain models and mappers to switch between entity and domain types.

---

# PROMPT 3: Networking & API Client (Retrofit + SSE)

## Objective
Implement the networking layer with support for standard REST calls and Server-Sent Events (SSE) for streaming message chunks.

## Instructions to AI Assistant
Implement the networking layer:

### API Client
- Base URL: `https://shamelagpt.com`
- Interceptors: Auth token injection, Logging.

### Endpoints
- `GET /api/health`
- `POST /api/chat` (Regular response)
- `POST /api/chat/stream` (SSE response)
- `POST /api/chat/ocr` (Image processing)

### SSE Implementation
Implement a robust SSE consumer that parses `data:` chunks and updates the UI in real-time. Handle `[DONE]` signals and error chunks.

---

# PROMPT 4: Chat Screen & Messaging Logic

## Objective
Build the main chat interface with real-time updates, markdown support, and auto-scrolling.

## Instructions to AI Assistant
Build the Chat feature:

### ChatViewModel
- Manage `ChatUiState`: `messages`, `isLoading`, `errorMessage`, `threadId`.
- Implement `sendMessage(text)`: handles optimistic UI updates and real-time streaming.

### ChatScreen (Composables)
- `MessageBubble`: Distinct styles for User (Emerald) vs AI (Gray).
- **Markdown**: Use a library like `richtext-ui-material3` to render AI answers.
- `AutoScroll`: Ensure the list scrolls to the bottom when new message chunks arrive.

---

# PROMPT 5: Voice Recognition (STT)

## Objective
Integrate Android's SpeechRecognizer to allow users to ask questions using their voice.

## Instructions to AI Assistant
Implement voice input:

### VoiceInputManager
- Use `android.speech.SpeechRecognizer`.
- Handle `RECORD_AUDIO` permissions gracefully.
- Provide a `StateFlow` and callbacks for partial and final results.

### UI Integration
- Animated Mic button in the `InputBar`.
- Visual feedback during recording (waves or pulsing icon).

---

# PROMPT 6: Vision & OCR (Fact-Check)

## Objective
Use ML Kit combined with API confirmation to allow users to verify claims from printed text/images.

## Instructions to AI Assistant
Implement the OCR/Fact-Check flow:

### OCRManager
- Use `com.google.mlkit:text-recognition`.
- Process images from Camera or Gallery.

### Hybrid Flow
1. Extract text locally using ML Kit.
2. Show confirmation dialog to user.
3. On confirm, send `imageBase64` to `/api/chat/confirm-factcheck`.
4. Stream the fact-check result.

---

# PROMPT 7: Authentication & Profile

## Objective
Implement user registration, login (including Google Sign-In), and account management.

## Instructions to AI Assistant
Implement Auth features:

### AuthRepository
- `signup`, `login`, `logout`.
- Google Sign-In integration (Credential Manager API).
- Token persistence in `DataStore` or `SharedPreferences`.

### Screens
- Welcome/Onboarding screen.
- Unified Auth screen (Login/Register toggle).
- Profile/Settings screen with "Delete Account" and "Logout".

---

# PROMPT 8: History & Conversation Management

## Objective
Build the history list with search, swipe-to-delete, and title generation.

## Instructions to AI Assistant
Build the History feature:

### HistoryViewModel
- Fetch and sort conversations by `updatedAt` descending.
- Implement deletion through the repository.

### HistoryScreen
- List of conversation cards.
- "New Chat" button to reset state.
- Empty states for when no history exists.

---

# PROMPT 9: Localization & RTL Support

## Objective
Full support for Arabic (RTL) and English (LTR).

## Instructions to AI Assistant
Localize the application:

### Resource Management
- Extract all hardcoded strings to `strings.xml`.
- Provide complete Arabic translations in `values-ar/strings.xml`.

### Layout Mirroring
- Use `start`/`end` instead of `left`/`right`.
- Verify behavior in RTL mode.
- Add Language Picker in Settings to switch locales at runtime.

---

# PROMPT 10: Polishing & Unit Testing

## Objective
Ensure 100% test pass rate and smooth UI/UX with transitions and error handling.

## Instructions to AI Assistant
Final polish and verification:

### Unit Tests
- Comprehensive tests for `ChatViewModel`, `HistoryViewModel`, and `AuthRepositoryImpl` using MockK.
- Achieve high coverage for business logic.

### UI/UX Polish
- Add loading skeletons or pulsing dots.
- Implement smooth transitions between screens using Navigation library animations.
- Final verify of the Emerald-Amber color scheme implementation.
