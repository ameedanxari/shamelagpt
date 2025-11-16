# ShamelaGPT iOS - Complete Build Prompts

This file contains all 10 sequential prompts to build the ShamelaGPT iOS app. Use each prompt with your AI assistant in order.

---

# PROMPT 1: Project Setup

## Objective
Create the Xcode project with proper structure, dependencies, and configuration.

## Prerequisites
- macOS with Xcode 15+ installed
- Basic understanding of Swift and iOS development

## Instructions to AI Assistant

I want to create an iOS app called "ShamelaGPT" - an AI-powered Islamic knowledge app. Please help me set up the Xcode project following these requirements:

### Project Configuration
- **Name**: ShamelaGPT
- **Bundle ID**: com.shamelagpt.ios
- **Min iOS Version**: 15.0
- **Interface**: SwiftUI
- **Language**: Swift
- **Architecture**: MVVM + Coordinator Pattern

### Folder Structure
Create this exact folder structure:
```
ShamelaGPT/
├── App/
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
├── Presentation/
│   ├── Coordinators/
│   ├── Scenes/
│   ├── Components/
│   └── Theme/
└── Resources/
```

### Dependencies (Swift Package Manager)
Add these packages:
1. **Swinject** - https://github.com/Swinject/Swinject (v2.10.0+)
2. **swift-markdown-ui** - https://github.com/gonzalezreal/swift-markdown-ui (v2.0.0+)

### Info.plist Entries
Add these keys:
```xml
<key>NSCameraUsageDescription</key>
<string>ShamelaGPT needs camera access to scan text from images for your questions.</string>

<key>NSMicrophoneUsageDescription</key>
<string>ShamelaGPT needs microphone access to let you ask questions using your voice.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>ShamelaGPT needs photo library access to let you select images for text recognition.</string>
```

### Colors (Assets.xcassets)
Create these color sets:
- Primary: #1B5E20 (Deep Green)
- PrimaryLight: #4C8C4A
- Accent: #D4AF37 (Gold)

### Initial Files to Create
1. `ShamelaGPTApp.swift` - App entry point
2. `DependencyContainer.swift` - Swinject setup
3. `Constants.swift` - App constants
4. `Extensions.swift` - Common extensions

Please provide step-by-step instructions and code for setting up this project.

## Success Criteria
- [ ] Project builds without errors
- [ ] Folder structure matches specification
- [ ] Dependencies resolved
- [ ] App launches with "Hello World" screen

---

# PROMPT 2: Data Layer Implementation

## Objective
Implement Core Data database, entities, and repository pattern for local storage.

## Context
I have the ShamelaGPT project set up. Now I need to implement the data layer using Core Data to store conversations and messages locally (the API doesn't support conversation management yet).

## Instructions to AI Assistant

Please help me implement the data layer with these requirements:

### Core Data Model
Create `ShamelaGPT.xcdatamodeld` with these entities:

**ConversationEntity**:
- `id`: String (UUID)
- `threadId`: String? (from API responses)
- `title`: String
- `createdAt`: Date
- `updatedAt`: Date
- Relationship: `messages` → MessageEntity (one-to-many, cascade delete)

**MessageEntity**:
- `id`: String (UUID)
- `conversationId`: String
- `content`: String (message text)
- `isUserMessage`: Bool
- `timestamp`: Date
- `sources`: String? (JSON string of source citations)
- Relationship: `conversation` → ConversationEntity (many-to-one)

### Core Data Stack
Implement `CoreDataStack.swift`:
- Singleton pattern
- Background context support
- Error handling
- Automatic merging from parent context

### DAOs (Data Access Objects)
Create these operations:
- **ConversationDAO**: CRUD for conversations
- **MessageDAO**: CRUD for messages

### Domain Models
Create clean domain models (separate from Core Data):
```swift
struct Conversation {
    let id: String
    var threadId: String?
    let title: String
    let createdAt: Date
    var updatedAt: Date
    var messages: [Message]
}

struct Message {
    let id: String
    let content: String
    let isUserMessage: Bool
    let timestamp: Date
    let sources: [Source]?
}

struct Source {
    let bookName: String
    let sourceURL: String
}
```

### Mappers
Create mappers to convert:
- `ConversationEntity` ↔ `Conversation`
- `MessageEntity` ↔ `Message`

### Repository Interface
Create `ChatRepository` protocol and implementation using Repository pattern.

### Dependency Injection
Register all data layer components in Swinject container.

Please provide complete implementation with error handling and best practices.

## Success Criteria
- [ ] Core Data model created
- [ ] Can save conversation
- [ ] Can save message
- [ ] Can fetch conversations
- [ ] Can fetch messages for a conversation
- [ ] Data persists after app restart
- [ ] No crashes on invalid data

---

# PROMPT 3: Networking Layer Implementation

## Objective
Implement API client using URLSession to communicate with ShamelaGPT API.

## Context
The API base URL is `https://api.shamelagpt.com`. Only the `/api/chat` endpoint works currently. Conversation management endpoints return 500 errors, so we handle everything locally.

## Instructions to AI Assistant

Please help me implement the networking layer:

### API Service
Create `APIClient.swift` using URLSession:
- Base URL: `https://api.shamelagpt.com`
- JSON encoding/decoding
- Error handling
- Timeout configuration (30s)

### Endpoints
Implement these endpoints:

**Health Check**:
```
GET /api/health
Response: {"status": "ok", "service": "shamela-llm"}
```

**Chat** (working):
```
POST /api/chat
Request: {
  "question": "string",
  "thread_id": "string?" // optional, for conversation continuation
}
Response: {
  "answer": "string", // markdown formatted with sources
  "thread_id": "string" // UUID
}
```

### Models
Create request/response models:
```swift
struct ChatRequest: Codable {
    let question: String
    let threadId: String?
}

struct ChatResponse: Codable {
    let answer: String
    let threadId: String
}
```

### Response Parsing
The `answer` field contains markdown with sources at the end:
```markdown
Content...

Sources:

* **book_name:** Book Title, **source_url:** https://shamela.ws/book/123/45
```

Parse this to extract:
1. Clean content (without sources section)
2. Array of `Source` objects

### Error Handling
Create `NetworkError` enum:
- `.invalidURL`
- `.invalidResponse`
- `.httpError(statusCode: Int)`
- `.decodingError(Error)`
- `.noConnection`
- `.timeout`

### Network Monitor
Implement `NetworkMonitor` using `Network` framework to detect connectivity.

### Repository Implementation
Update `ChatRepositoryImpl` to:
1. Send message to API
2. Parse response
3. Save messages locally
4. Handle offline mode

### Combine Integration
Use Combine publishers for async operations.

Please provide complete implementation with proper error handling.

## Success Criteria
- [ ] Can call `/api/health` successfully
- [ ] Can send message to `/api/chat`
- [ ] Can receive and parse response
- [ ] thread_id extracted correctly
- [ ] Sources parsed from markdown
- [ ] Errors handled gracefully
- [ ] Network status monitored

---

# PROMPT 4: Chat Feature Implementation

## Objective
Build the main chat screen with message list, input bar, and real-time messaging.

## Instructions to AI Assistant

Please help me implement the chat feature:

### ChatViewModel
Create `ChatViewModel.swift`:
- Conforms to `ObservableObject`
- Published properties:
  - `@Published var messages: [Message] = []`
  - `@Published var inputText: String = ""`
  - `@Published var isLoading: Bool = false`
  - `@Published var error: String? = nil`
  - `@Published var conversationId: String?`
  - `@Published var threadId: String?`
- Methods:
  - `sendMessage()`
  - `loadMessages()`
  - `updateInputText(_ text: String)`
  - `clearError()`
- Use `SendMessageUseCase` for business logic
- Handle API responses
- Update UI state

### ChatScreen
Create `ChatView.swift`:
- SwiftUI view
- Contains:
  1. **Navigation Bar**: Title + menu button
  2. **Message List**: ScrollView with LazyVStack
  3. **Input Bar**: Text field + send button
- Auto-scroll to bottom on new message
- Show loading indicator (typing dots)
- Error handling with retry

### Message Bubble Component
Create `MessageBubbleView.swift`:
- User messages: Right-aligned, blue background
- AI messages: Left-aligned, gray background
- Rounded corners (18pt radius)
- Display timestamp
- Show sources as tappable links
- Long-press menu: Copy, Share
- Markdown rendering for AI messages

### Input Bar Component
Create `InputBarView.swift`:
- Text field with placeholder: "Ask a question about Islam..."
- Send button (arrow icon)
- Disable send when empty or loading
- Clear field after sending
- Auto-expanding text field (max 5 lines)

### Typing Indicator
Create `TypingIndicatorView.swift`:
- Three animated dots
- Shows while `isLoading == true`
- Smooth bounce animation

### Empty State
Show when no messages:
- Icon
- "Start a conversation"
- Suggested questions (optional)

### State Management
Use Combine to handle:
- Input text changes
- Message sending
- Loading states
- Error states

Implement with SwiftUI best practices, Material Design principles, and smooth animations.

## Success Criteria
- [ ] Chat screen displays
- [ ] Can type in input field
- [ ] Can send message
- [ ] User message appears immediately
- [ ] Typing indicator shows
- [ ] AI response appears
- [ ] Messages display correctly
- [ ] Markdown renders properly
- [ ] Sources are clickable
- [ ] Can copy message
- [ ] Can share message
- [ ] Scrolls to bottom automatically

---

# PROMPT 5: Voice & Image Input Implementation

## Objective
Add voice input (Speech framework) and image OCR (Vision framework) capabilities.

## Instructions to AI Assistant

Please help me implement advanced input methods:

### Voice Input Manager
Create `VoiceInputManager.swift`:
- Use `Speech` framework
- Use `AVFoundation` for audio
- Methods:
  - `requestPermission()`
  - `startRecording(locale: Locale)`
  - `stopRecording()`
- Real-time transcription support
- Handle permissions
- Support English and Arabic locales
- Published properties for transcribed text

### Voice Input UI
Add to `InputBarView`:
- Microphone FAB button
- Recording indicator (animated)
- Permission handling
- Show transcribed text in input field
- Allow editing before sending

### OCR Manager
Create `OCRManager.swift`:
- Use `Vision` framework
- Use `VNRecognizeTextRequest`
- Methods:
  - `recognizeText(from: UIImage)`
- Support Arabic and English
- Accurate recognition level
- Published properties for extracted text

### Image Input UI
Add to `InputBarView`:
- Camera/Gallery FAB button
- Image picker (PhotosPicker or UIImagePickerController)
- Permission handling
- Loading indicator during OCR
- Show extracted text in input field
- Allow editing before sending

### Permissions
Add Info.plist keys (if not already added):
- `NSMicrophoneUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

### Integration with Chat
Update `ChatViewModel`:
- Add `startVoiceInput()` method
- Add `selectImage()` method
- Handle voice/OCR results
- Update input text field

### Error Handling
Handle these cases:
- Permission denied
- Recognition failed
- No text found
- Device doesn't support feature

Implement with smooth UX and proper feedback.

## Success Criteria
- [ ] Microphone button shows
- [ ] Can tap to start recording
- [ ] Recording indicator animates
- [ ] Voice transcribed to text
- [ ] Transcribed text appears in input field
- [ ] Can edit transcribed text
- [ ] Image button shows
- [ ] Can take photo with camera
- [ ] Can select from photo library
- [ ] OCR extracts text
- [ ] Extracted text appears in input field
- [ ] Can edit extracted text
- [ ] Permissions handled properly
- [ ] Errors shown to user

---

# PROMPT 6: History Feature Implementation

## Objective
Build conversation history screen to view and manage past conversations.

## Instructions to AI Assistant

Please help me implement the conversation history feature:

### HistoryViewModel
Create `HistoryViewModel.swift`:
- Published properties:
  - `@Published var conversations: [Conversation] = []`
  - `@Published var isLoading: Bool = false`
  - `@Published var error: String? = nil`
- Methods:
  - `loadConversations()`
  - `deleteConversation(_ id: String)`
  - `deleteAllConversations()`
  - `createNewConversation()`
- Use `GetConversationsUseCase`
- Fetch from local database
- Sort by most recent first

### HistoryScreen
Create `HistoryView.swift`:
- Navigation bar with "History" title
- "New Chat" button in toolbar
- List of conversations (LazyVStack or List)
- Pull-to-refresh
- Empty state when no conversations

### Conversation Card Component
Create `ConversationCardView.swift`:
- Title (from first message)
- Last message preview (1-2 lines)
- Timestamp (relative: "2 hours ago")
- Chevron indicator
- Tap to open conversation
- Swipe actions:
  - Delete (red)
  - Share (blue) - optional

### Navigation
- Tap conversation → Navigate to ChatView with conversation ID
- Load existing messages
- Continue conversation with same thread_id

### Empty State
Show when no conversations:
- Clock icon
- "No Conversations"
- "Start a new chat to begin"

### Auto-Title Generation
Generate conversation title from first user message:
- Truncate to 50 characters
- Add "..." if truncated

### Delete Confirmation
Show alert before deleting:
- "Delete Conversation?"
- "This action cannot be undone."
- Cancel / Delete buttons

Implement with smooth animations and SwiftUI best practices.

## Success Criteria
- [ ] History screen displays
- [ ] Shows list of conversations
- [ ] Conversations sorted by recent
- [ ] Tap conversation opens chat
- [ ] Chat loads previous messages
- [ ] Can continue conversation
- [ ] Can delete conversation
- [ ] Delete confirmation appears
- [ ] Deleted conversation removed from list
- [ ] Empty state shows when no conversations
- [ ] New chat button works
- [ ] Pull-to-refresh works

---

# PROMPT 7: Settings & Welcome Screens

## Objective
Implement welcome screen (first launch) and settings screen.

## Instructions to AI Assistant

Please help me implement these screens:

### Welcome Screen
Create `WelcomeView.swift`:

Display this message (provided by user):
```
🌿 Welcome to ShamelaGPT

ShamelaGPT is built upon the vast and trusted library of Shamela.ws,
bringing authentic Islamic knowledge closer to everyone.
Our mission is to make reliable, reference-based information accessible
in a natural and conversational way — across languages, backgrounds,
and levels of understanding.

Whether you seek deeper insight, quick clarifications, or evidence-backed
answers to common misconceptions, ShamelaGPT helps you explore Islam's
rich heritage with accuracy, respect, and ease.

"Seek knowledge from the cradle to the grave." — Let this be your
companion on that journey.

---

🔐 Sign In for a Better Experience

Log in to save your conversations, revisit your past questions, and
share meaningful discussions with others.
Creating an account also helps us improve your learning experience —
personalizing insights, language preferences, and reference trails for you.

👉 Sign in now and continue your journey of knowledge with consistency
and clarity.
```

Components:
- App logo (centered, 80pt)
- Scrollable message
- "Get Started" button (primary, filled)
- "Skip to Chat" button (text button)
- Show only on first launch (use UserDefaults)

### Settings Screen
Create `SettingsView.swift`:

Sections:
1. **General**:
   - Language (shows current, navigates to language selection)

2. **Support**:
   - "❤️ Support ShamelaGPT" → Opens PayPal donation
   - URL: `https://www.paypal.com/donate/?hosted_button_id=MSBDG5ESU2AMU`

3. **About**:
   - About ShamelaGPT
   - Privacy Policy
   - Terms of Service

4. **Footer**:
   - Version 1.0.0 (centered, gray text)

Use Form or List style.

### Language Selection Screen
Create `LanguageSelectionView.swift`:
- List of languages:
  - English
  - العربية (Arabic)
- Current selection marked
- Tap to select
- Update immediately
- Navigate back automatically

### Language Management
Create `LanguageManager.swift`:
- Store selected language in UserDefaults
- Apply language change
- Support localization

### Donation Link Handler
Use `SFSafariViewController` to open donation link in-app.

### First Launch Detection
Use UserDefaults to track:
```swift
@AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
```

Implement with Material Design components.

## Success Criteria
- [ ] Welcome screen shows on first launch only
- [ ] Can tap "Get Started"
- [ ] Can tap "Skip to Chat"
- [ ] Both navigate to chat
- [ ] Settings screen accessible via tab bar
- [ ] All settings sections display
- [ ] Language selection works
- [ ] Selected language persists
- [ ] UI updates when language changed
- [ ] Donation button opens PayPal in Safari
- [ ] About buttons navigate (can be placeholder screens)
- [ ] Version number displays

---

# PROMPT 8: Navigation Integration

## Objective
Connect all screens with proper navigation using Coordinator pattern and tab bar.

## Instructions to AI Assistant

Please help me implement complete app navigation:

### Navigation Routes
Define routes using Swift enums:
```swift
enum AppRoute: Hashable {
    case welcome
    case chat(conversationId: String?)
    case history
    case settings
    case languageSelection
}
```

### App Coordinator
Create `AppCoordinator.swift`:
- ObservableObject
- `@Published var navigationPath: NavigationPath`
- Methods:
  - `start()` - Determine initial route
  - `navigate(to: AppRoute)`
  - `pop()`
  - `popToRoot()`
- Handle first launch → welcome screen
- Handle returning user → chat/last conversation

### Main App Structure
Update `ShamelaGPTApp.swift`:
```swift
@main
struct ShamelaGPTApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            if coordinator.shouldShowWelcome {
                WelcomeView(coordinator: coordinator)
            } else {
                MainTabView(coordinator: coordinator)
            }
        }
    }
}
```

### Tab Bar
Create `MainTabView.swift`:
- Three tabs:
  1. **Chat** (SF Symbol: `message.fill`)
  2. **History** (SF Symbol: `clock.fill`)
  3. **Settings** (SF Symbol: `gearshape.fill`)
- Use NavigationStack for each tab
- Maintain separate navigation stacks
- Deep linking support

### Navigation Stack Setup
Each tab has its own NavigationStack:
```swift
NavigationStack(path: $coordinator.chatPath) {
    ChatView()
        .navigationDestination(for: AppRoute.self) { route in
            // Handle navigation
        }
}
```

### Deep Linking
Handle deep links to:
- Specific conversation
- Settings screen
- Direct to chat

### State Preservation
Save and restore:
- Current tab
- Navigation state
- Last conversation ID

Implement following iOS navigation best practices.

## Success Criteria
- [ ] App launches to correct screen (welcome or tabs)
- [ ] Tab bar shows at bottom
- [ ] All three tabs functional
- [ ] Tapping tab switches view
- [ ] Navigation between screens works
- [ ] Back button works
- [ ] Can navigate from history to chat
- [ ] Can open settings
- [ ] Can return from settings
- [ ] Tab state preserved
- [ ] No navigation glitches

---

# PROMPT 9: Polish & Testing

## Objective
Add final polish, animations, error states, and conduct thorough testing.

## Instructions to AI Assistant

Please help me polish the app:

### RTL Support
Ensure RTL works for Arabic:
- Use `.leading` and `.trailing` throughout
- Test with Arabic language selected
- Verify message bubbles swap sides correctly
- Check all layouts mirror properly
- Test bidirectional text

### Dark Mode
Test and fix dark mode:
- Use semantic colors throughout
- Test all screens in dark mode
- Fix any contrast issues
- Ensure readability

### Animations
Add these animations:
- Message appearance (slide up + fade in)
- Typing indicator bounce
- Tab switching fade
- Sheet presentations
- Loading spinners
- Button press feedback

### Loading States
Ensure loading states for:
- Initial app launch
- Message sending
- Conversation loading
- Image OCR processing
- Voice transcription
- History loading

### Error States
Implement error handling for:
- No internet connection
- API failures
- Permission denied
- OCR failure
- Voice recognition failure
- Database errors

### Empty States
Design empty states for:
- No conversations
- No messages in conversation
- No search results (if applicable)

### Accessibility
Implement VoiceOver support:
- Labels for all buttons
- Hints for complex interactions
- Proper reading order
- Test with VoiceOver enabled

### Performance Optimization
- Lazy loading for long conversations
- Image caching
- Efficient Core Data queries
- Memory leak prevention
- Smooth scrolling (60 FPS)

### Unit Tests
Write tests for:
- ViewModels
- Use Cases
- Repositories
- Mappers

### UI Tests
Write tests for:
- Message sending
- Conversation creation
- Navigation flow

### Bug Fixes
Test and fix:
- Edge cases
- Crash scenarios
- Data validation
- Input validation

Use the TESTING_CHECKLIST.md to validate everything works.

## Success Criteria
- [ ] All tests pass
- [ ] RTL works perfectly
- [ ] Dark mode looks good
- [ ] Animations smooth
- [ ] No crashes
- [ ] Good performance
- [ ] Accessible
- [ ] All features tested

---

# PROMPT 10: Localization

## Objective
Complete multi-language support for English and Arabic.

## Instructions to AI Assistant

Please help me fully localize the app:

### String Extraction
Create `Localizable.strings` files:
- `en.lproj/Localizable.strings` (English)
- `ar.lproj/Localizable.strings` (Arabic)

### Key Strings to Localize
Extract ALL hardcoded strings:
- Screen titles
- Button labels
- Input placeholders
- Error messages
- Empty state messages
- Alert messages
- Tab bar labels
- Settings options
- Welcome message (already provided)

### String Catalog (iOS 15+)
Optionally use String Catalog (.xcstrings) for easier management.

### Arabic Translation
Translate all strings to Arabic:
- Use proper Arabic grammar
- Consider cultural context
- Test with native speakers if possible

### Pluralization
Handle plurals correctly:
```swift
// Example
String(format: NSLocalizedString("conversation_count", comment: ""), count)
```

### String Formatting
Handle formatted strings:
```swift
String(format: NSLocalizedString("greeting_%@", comment: ""), name)
```

### Testing
Test both languages:
- Switch between languages
- Verify all text displays
- Check layout in both LTR and RTL
- Ensure no text truncation
- Verify proper word breaking

### Language Persistence
Ensure language choice persists:
- Save to UserDefaults
- Apply on app launch
- Update immediately when changed

Provide complete English and Arabic translations.

## Success Criteria
- [ ] All strings localized
- [ ] No hardcoded strings
- [ ] English version complete
- [ ] Arabic version complete
- [ ] Both languages display correctly
- [ ] RTL works with Arabic
- [ ] LTR works with English
- [ ] Language switching works
- [ ] Selection persists
- [ ] No layout issues in either language

---

## 🎉 Congratulations!

After completing all 10 prompts, you will have a fully functional ShamelaGPT iOS app with:

✅ Complete chat interface
✅ Voice and image input
✅ Conversation history
✅ Settings and preferences
✅ Multi-language support (EN/AR)
✅ RTL layout support
✅ Offline functionality
✅ Polish and animations
✅ Comprehensive testing

## Next Steps

1. **Test thoroughly** using TESTING_CHECKLIST.md
2. **Fix any bugs** found during testing
3. **Get user feedback** from beta testers
4. **Prepare for App Store** submission
5. **Plan Phase 2 features** (authentication, cloud sync, etc.)

## Remember

- Use each prompt sequentially with your AI assistant
- Test after each phase before moving forward
- Commit code after completing each prompt
- Refer to documentation files when needed
- Ask questions if anything is unclear

**Happy Building! 🚀**
