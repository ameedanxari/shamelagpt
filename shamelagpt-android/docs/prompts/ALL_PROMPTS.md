# ShamelaGPT Android - Complete Build Prompts

This file contains all 10 sequential prompts to build the ShamelaGPT Android app. Use each prompt with your AI assistant in order.

---

# PROMPT 1: Project Setup

## Objective
Create the Android Studio project with proper structure, dependencies, and configuration.

## Prerequisites
- Windows/macOS/Linux with Android Studio Hedgehog (2023.1.1) or later
- JDK 17 or later
- Android SDK API 34 installed
- Basic understanding of Kotlin and Android development

## Instructions to AI Assistant

I want to create an Android app called "ShamelaGPT" - an AI-powered Islamic knowledge app. Please help me set up the Android Studio project following these requirements:

### Project Configuration
- **Name**: ShamelaGPT
- **Package**: com.shamelagpt.android
- **Min SDK**: API 26 (Android 8.0 Oreo)
- **Target SDK**: API 34 (Android 14)
- **Language**: Kotlin
- **UI Framework**: Jetpack Compose
- **Architecture**: MVVM + Clean Architecture

### Folder Structure
Create this exact folder structure:
```
app/src/main/java/com/shamelagpt/
├── ShamelaGPTApplication.kt
├── core/
│   ├── di/
│   ├── network/
│   ├── database/
│   ├── util/
│   └── preferences/
├── domain/
│   ├── model/
│   ├── repository/
│   └── usecase/
├── data/
│   ├── remote/
│   │   ├── dto/
│   │   └── datasource/
│   ├── local/
│   │   ├── entity/
│   │   └── datasource/
│   ├── mapper/
│   └── repository/
└── presentation/
    ├── MainActivity.kt
    ├── navigation/
    ├── theme/
    ├── components/
    ├── welcome/
    ├── chat/
    ├── history/
    └── settings/
```

### Dependencies (build.gradle.kts)
Add these dependencies:

**Core**:
- androidx.core:core-ktx:1.12.0
- androidx.lifecycle:lifecycle-runtime-ktx:2.7.0
- androidx.activity:activity-compose:1.8.2

**Compose BOM**:
- androidx.compose:compose-bom:2024.02.00
- androidx.compose.ui:ui
- androidx.compose.material3:material3
- androidx.navigation:navigation-compose:2.7.7

**Koin (Dependency Injection)**:
- io.insert-koin:koin-android:3.5.3
- io.insert-koin:koin-androidx-compose:3.5.3

**Retrofit (Networking)**:
- com.squareup.retrofit2:retrofit:2.9.0
- com.squareup.retrofit2:converter-gson:2.9.0
- com.squareup.okhttp3:logging-interceptor:4.12.0

**Room (Database)**:
- androidx.room:room-runtime:2.6.1
- androidx.room:room-ktx:2.6.1
- ksp("androidx.room:room-compiler:2.6.1")

**Kotlin Serialization**:
- org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2

**Coroutines**:
- org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3

### AndroidManifest.xml
Add these permissions:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

Set application name:
```xml
android:name=".ShamelaGPTApplication"
android:supportsRtl="true"
```

### Colors (Color.kt)
Create Material Design 3 color scheme:
- Primary: #1B5E20 (Deep Green)
- Primary Container: #4C8C4A
- Tertiary: #D4AF37 (Gold Accent)

### Initial Files to Create
1. `ShamelaGPTApplication.kt` - App entry point with Koin initialization
2. `MainActivity.kt` - Compose activity
3. `Theme.kt` - Material Design 3 theme setup
4. `Constants.kt` - App constants

Please provide step-by-step instructions and code for setting up this project.

## Success Criteria
- [ ] Project builds without errors
- [ ] Folder structure matches specification
- [ ] Dependencies resolved
- [ ] App launches with "Hello World" Compose screen
- [ ] Koin initialized successfully

---

# PROMPT 2: Data Layer Implementation

## Objective
Implement Room database, entities, DAOs, and repository pattern for local storage.

## Context
I have the ShamelaGPT project set up. Now I need to implement the data layer using Room to store conversations and messages locally (the API doesn't support conversation management yet).

## Instructions to AI Assistant

Please help me implement the data layer with these requirements:

### Room Database Schema
Create `AppDatabase.kt` with these entities:

**ConversationEntity** (table: conversations):
- `id`: String (Primary Key, UUID)
- `threadId`: String? (from API responses)
- `title`: String
- `createdAt`: Long (timestamp)
- `updatedAt`: Long (timestamp)

**MessageEntity** (table: messages):
- `id`: String (Primary Key, UUID)
- `conversationId`: String (Foreign Key → ConversationEntity.id, CASCADE delete)
- `content`: String (message text)
- `isUserMessage`: Boolean
- `timestamp`: Long
- `sources`: String? (JSON string of source citations)

Add proper indices on `conversationId` for MessageEntity.

### DAOs (Data Access Objects)

**ConversationDao**:
- `getAllConversations(): Flow<List<ConversationEntity>>` - sorted by updatedAt DESC
- `getConversationById(id: String): ConversationEntity?`
- `insertConversation(conversation: ConversationEntity)`
- `updateConversation(conversation: ConversationEntity)`
- `deleteConversation(conversation: ConversationEntity)`
- `deleteAllConversations()`

**MessageDao**:
- `getMessagesByConversationId(conversationId: String): Flow<List<MessageEntity>>`
- `insertMessage(message: MessageEntity)`
- `deleteMessagesByConversationId(conversationId: String)`

### Domain Models
Create clean domain models (separate from Room entities):

```kotlin
data class Conversation(
    val id: String,
    var threadId: String?,
    val title: String,
    val createdAt: Long,
    var updatedAt: Long,
    var messages: List<Message> = emptyList()
)

data class Message(
    val id: String,
    val content: String,
    val isUserMessage: Boolean,
    val timestamp: Long,
    val sources: List<Source>? = null
)

data class Source(
    val bookName: String,
    val sourceURL: String
)
```

### Mappers
Create extension functions to convert:
- `ConversationEntity.toDomain(): Conversation`
- `Conversation.toEntity(): ConversationEntity`
- `MessageEntity.toDomain(): Message`
- `Message.toEntity(conversationId: String): MessageEntity`

### Type Converters
Create `Converters.kt` for:
- JSON string ↔ List<Source>

### Repository Interface & Implementation
Create `ConversationRepository` interface and `ConversationRepositoryImpl`:
- `getConversations(): Flow<List<Conversation>>`
- `getConversationById(id: String): Conversation?`
- `createConversation(title: String): Conversation`
- `deleteConversation(id: String)`
- `saveMessage(message: Message, conversationId: String)`

### Dependency Injection (Koin)
Register all data layer components in `DatabaseModule.kt`:
- AppDatabase (singleton)
- DAOs (singleton)
- Repositories (singleton)

Please provide complete implementation with proper error handling.

## Success Criteria
- [ ] Room database created
- [ ] Can save conversation
- [ ] Can save message
- [ ] Can fetch conversations
- [ ] Can fetch messages for a conversation
- [ ] Data persists after app restart
- [ ] No crashes on invalid data
- [ ] Foreign key constraints work (cascade delete)

---

# PROMPT 3: Networking Layer Implementation

## Objective
Implement API client using Retrofit to communicate with ShamelaGPT API.

## Context
The API base URL is `https://api.shamelagpt.com`. Only the `/api/chat` endpoint works currently. Conversation management endpoints return 500 errors, so we handle everything locally.

## Instructions to AI Assistant

Please help me implement the networking layer:

### API Service (Retrofit)
Create `ApiService.kt` interface:

**Endpoints**:

1. **Health Check**:
```kotlin
@GET("api/health")
suspend fun checkHealth(): HealthResponse
```

2. **Chat** (working):
```kotlin
@POST("api/chat")
suspend fun sendMessage(@Body request: ChatRequest): ChatResponse
```

### DTOs (Data Transfer Objects)

**Request**:
```kotlin
data class ChatRequest(
    val question: String,
    @SerializedName("thread_id")
    val threadId: String? = null,
    @SerializedName("user_id")
    val userId: String? = null
)
```

**Response**:
```kotlin
data class ChatResponse(
    val answer: String, // markdown formatted with sources
    @SerializedName("thread_id")
    val threadId: String
)

data class HealthResponse(
    val status: String,
    val service: String
)
```

### Response Parsing
The `answer` field contains markdown with sources at the end:
```markdown
Content...

Sources:

* **book_name:** Book Title, **source_url:** https://shamela.ws/book/123/45
```

Create a parser to extract:
1. Clean content (without sources section)
2. List of `Source` objects

### Error Handling
Create `NetworkError` sealed class:
```kotlin
sealed class NetworkError : Exception() {
    data class HttpError(val code: Int, override val message: String) : NetworkError()
    data class NetworkException(override val message: String) : NetworkError()
    data class UnknownError(override val message: String) : NetworkError()
}
```

Create `safeApiCall` wrapper function using try-catch.

### Network Connectivity Monitor
Create `NetworkMonitor.kt` using `ConnectivityManager`:
- Detect if device is online
- Emit Flow<Boolean> for connectivity state

### Remote Data Source
Create `ChatRemoteDataSource` interface and implementation:
- `sendMessage(question: String, threadId: String?): ChatResponse`
- `checkHealth(): HealthResponse`

### Repository Implementation
Create `ChatRepository` interface and `ChatRepositoryImpl`:
1. Send message to API
2. Parse response and extract sources
3. Save user message + AI response to local database
4. Return Result<ChatResponse>
5. Handle offline mode gracefully

### Retrofit Configuration
Create Retrofit instance with:
- Base URL: https://api.shamelagpt.com/
- Gson converter
- OkHttp client with:
  - 30s timeout
  - Logging interceptor (debug builds only)

### Dependency Injection (Koin)
Register in `NetworkModule.kt`:
- OkHttpClient
- Retrofit
- ApiService
- ChatRemoteDataSource
- ChatRepository

Please provide complete implementation with proper error handling.

## Success Criteria
- [ ] Can call `/api/health` successfully
- [ ] Can send message to `/api/chat`
- [ ] Can receive and parse response
- [ ] thread_id extracted correctly
- [ ] Sources parsed from markdown
- [ ] Errors handled gracefully
- [ ] Network status monitored
- [ ] Offline mode doesn't crash app

---

# PROMPT 4: Chat Feature Implementation

## Objective
Build the main chat screen with message list, input bar, and real-time messaging using Jetpack Compose.

## Instructions to AI Assistant

Please help me implement the chat feature:

### ChatViewModel
Create `ChatViewModel.kt`:

**UI State**:
```kotlin
data class ChatUiState(
    val messages: List<Message> = emptyList(),
    val inputText: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val conversationId: String? = null,
    val threadId: String? = null,
    val conversationTitle: String? = null
)
```

**Methods**:
- `sendMessage(text: String)`
- `updateInputText(text: String)`
- `clearError()`
- `loadConversation(conversationId: String?)`

**Events** (using Channel):
```kotlin
sealed class ChatEvent {
    data class ShowError(val message: String) : ChatEvent()
    object MessageSent : ChatEvent()
    object ScrollToBottom : ChatEvent()
}
```

Use `SendMessageUseCase` for business logic.

### ChatScreen
Create `ChatScreen.kt` composable:

**Structure**:
1. **TopAppBar**: Title (conversation title or "ShamelaGPT") + menu button
2. **Message List**: LazyColumn with auto-scroll to bottom
3. **Input Bar**: Text field + send button

**Features**:
- Auto-scroll to bottom when new message arrives
- Show typing indicator while loading
- Display error state with retry button
- Handle keyboard properly (IME actions)

### MessageBubble Component
Create `MessageBubble.kt`:

**User Messages**:
- Aligned to end (right in LTR, left in RTL)
- Primary color background
- White text

**AI Messages**:
- Aligned to start (left in LTR, right in RTL)
- Surface variant background
- On-surface variant text color
- Markdown rendering for formatted text
- Sources displayed as clickable links below message

**Features**:
- Rounded corners (16dp)
- Max width 300dp
- Timestamp below bubble (small, gray)
- Long-press context menu: Copy, Share

### InputBar Component
Create `InputBar.kt`:

**Layout**:
- Row with: Image button | Mic button | TextField (weight=1) | Send button
- Material Design 3 OutlinedTextField
- Rounded shape (24dp)
- Placeholder: "Ask a question about Islam..."

**Behavior**:
- Send button disabled when text is empty or loading
- Send button icon colored when enabled
- TextField max 5 lines, then scrolls
- Disable all inputs while loading

### TypingIndicator Component
Create `TypingIndicator.kt`:
- Three animated dots
- Bounce animation with staggered delay
- Surface variant background
- Display in message list while loading

### Empty State
Show when no messages:
- Icon (message outline)
- "Start a conversation"
- Optional: Suggested questions

### Markdown Rendering
Use `compose-richtext` library:
```kotlin
dependencies {
    implementation("com.halilibo.compose-richtext:richtext-ui-material3:0.17.0")
    implementation("com.halilibo.compose-richtext:richtext-commonmark:0.17.0")
}
```

Render AI messages with markdown support.

### Use Cases
Create `SendMessageUseCase.kt`:
```kotlin
class SendMessageUseCase(
    private val chatRepository: ChatRepository,
    private val conversationRepository: ConversationRepository
) {
    suspend operator fun invoke(
        question: String,
        conversationId: String?,
        threadId: String?
    ): Result<ChatResponse>
}
```

Implement with Compose best practices and Material Design 3.

## Success Criteria
- [ ] Chat screen displays
- [ ] Can type in input field
- [ ] Can send message
- [ ] User message appears immediately
- [ ] Typing indicator shows
- [ ] AI response appears
- [ ] Messages display correctly (bidirectional text)
- [ ] Markdown renders properly
- [ ] Sources are clickable
- [ ] Can copy message
- [ ] Can share message
- [ ] Auto-scrolls to bottom
- [ ] Keyboard handling works
- [ ] RTL layout works for Arabic

---

# PROMPT 5: Voice & Image Input Implementation

## Objective
Add voice input (Android SpeechRecognizer) and image OCR (ML Kit Text Recognition) capabilities.

## Instructions to AI Assistant

Please help me implement advanced input methods:

### Voice Input Manager
Create `VoiceInputManager.kt`:

**Technology**: Android `SpeechRecognizer` API

**Features**:
- Request RECORD_AUDIO permission
- Start/stop listening
- Real-time transcription (partial results)
- Support English and Arabic locales
- Handle errors gracefully

**Implementation**:
```kotlin
class VoiceInputManager(private val context: Context) {
    private val speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)

    fun startListening(
        locale: Locale = Locale.getDefault(),
        onResult: (String) -> Unit,
        onError: (String) -> Unit
    )

    fun stopListening()
}
```

### Voice Input UI
Update `InputBar.kt`:
- Microphone IconButton
- Permission request dialog (first time)
- Recording indicator (animated red dot + pulse)
- Show transcribed text in TextField in real-time
- Allow editing before sending
- Stop button while recording

### Voice Input State
Add to `ChatViewModel`:
```kotlin
data class VoiceInputState(
    val isRecording: Boolean = false,
    val transcribedText: String = "",
    val error: String? = null
)
```

Methods:
- `startVoiceInput()`
- `stopVoiceInput()`
- `onVoiceResult(text: String)`
- `onVoiceError(error: String)`

### OCR Manager
Create `OCRManager.kt`:

**Technology**: Google ML Kit Text Recognition

**Dependencies**:
```kotlin
implementation("com.google.mlkit:text-recognition:16.0.0")
```

**Implementation**:
```kotlin
class OCRManager(private val context: Context) {
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    suspend fun recognizeText(imageUri: Uri): Result<String>
}
```

**Features**:
- Support Arabic and Latin scripts
- Process image on device (privacy-focused)
- Extract text with high accuracy
- Handle errors

### Image Input UI
Add to `InputBar.kt`:
- Image/Camera IconButton
- Permission requests (CAMERA, READ_MEDIA_IMAGES)
- Image picker (ActivityResultContract):
  - Take photo (camera)
  - Select from gallery
- Loading indicator during OCR
- Show extracted text in TextField
- Allow editing before sending

### Image Input State
Add to `ChatViewModel`:
```kotlin
data class ImageInputState(
    val isProcessing: Boolean = false,
    val extractedText: String = "",
    val error: String? = null
)
```

Methods:
- `selectImageFromGallery()`
- `takePhoto()`
- `processImage(uri: Uri)`
- `onOcrResult(text: String)`
- `onOcrError(error: String)`

### Permissions Handling
Create `PermissionsHandler.kt`:
- Request permissions using `rememberLauncherForActivityResult`
- Show rationale dialogs
- Handle permission denied
- Navigate to settings if permanently denied

### Error Handling
Handle these cases:
- Permission denied
- Recognition failed
- No text found in image
- Device doesn't support SpeechRecognizer
- Network required for speech recognition

### UI Feedback
- Toast messages for quick feedback
- Snackbar for errors with retry
- Loading indicators
- Animated icons during recording/processing

Implement with proper permission handling and user feedback.

## Success Criteria
- [ ] Microphone button shows
- [ ] Can tap to start recording
- [ ] Recording indicator animates
- [ ] Voice transcribed to text (real-time)
- [ ] Transcribed text appears in input field
- [ ] Can edit transcribed text
- [ ] Image/camera button shows
- [ ] Can take photo with camera
- [ ] Can select from gallery
- [ ] OCR extracts text accurately
- [ ] Extracted text appears in input field
- [ ] Can edit extracted text
- [ ] Permissions handled properly
- [ ] Permission rationale shown
- [ ] Errors shown to user
- [ ] Arabic and English both work

---

# PROMPT 6: History Feature Implementation

## Objective
Build conversation history screen to view and manage past conversations.

## Instructions to AI Assistant

Please help me implement the conversation history feature:

### HistoryViewModel
Create `HistoryViewModel.kt`:

**UI State**:
```kotlin
data class HistoryUiState(
    val conversations: List<Conversation> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)
```

**Methods**:
- `loadConversations()`
- `deleteConversation(id: String)`
- `deleteAllConversations()`
- `createNewConversation()`

Use `GetConversationsUseCase` and `DeleteConversationUseCase`.

### HistoryScreen
Create `HistoryScreen.kt`:

**Structure**:
1. **TopAppBar**: "History" title + "New Chat" action button
2. **Conversation List**: LazyColumn
3. **Pull-to-Refresh**: Material 3 pull refresh
4. **Empty State**: When no conversations

**Features**:
- Sort conversations by most recent first
- Tap to open conversation in ChatScreen
- Swipe-to-delete with confirmation
- Pull-to-refresh
- Loading skeleton

### ConversationCard Component
Create `ConversationCard.kt`:

**Layout**:
- Card with rounded corners (12dp)
- Title (bold, 1 line, ellipsis)
- Last message preview (2 lines, gray, ellipsis)
- Timestamp (relative: "2 hours ago", gray, small)
- Delete IconButton (right side, error color)

**Interactions**:
- Tap card → Navigate to ChatScreen with conversationId
- Tap delete → Show confirmation dialog
- Long-press → Show context menu (optional)

### Empty State
Create `EmptyState.kt` (reusable component):
- Icon (centered, large)
- Title text (centered, medium)
- Message text (centered, gray)
- Optional action button

Show when no conversations:
- Clock icon
- "No Conversations"
- "Start a new chat to begin"

### Auto-Title Generation
Create utility function:
```kotlin
fun generateConversationTitle(firstMessage: String): String {
    val maxLength = 50
    return if (firstMessage.length > maxLength) {
        firstMessage.take(maxLength) + "..."
    } else {
        firstMessage
    }
}
```

Generate title from first user message when creating conversation.

### Delete Confirmation Dialog
Create `DeleteConfirmationDialog.kt`:
- Material 3 AlertDialog
- Title: "Delete Conversation?"
- Message: "This action cannot be undone."
- Actions: Cancel (TextButton) | Delete (Button, error color)

### Navigation Integration
Update navigation to:
- Navigate from HistoryScreen to ChatScreen with conversationId
- Load conversation messages in ChatScreen
- Continue conversation with same threadId

### Use Cases
Create these use cases:

**GetConversationsUseCase**:
```kotlin
class GetConversationsUseCase(
    private val conversationRepository: ConversationRepository
) {
    operator fun invoke(): Flow<List<Conversation>>
}
```

**DeleteConversationUseCase**:
```kotlin
class DeleteConversationUseCase(
    private val conversationRepository: ConversationRepository
) {
    suspend operator fun invoke(conversationId: String): Result<Unit>
}
```

### Relative Timestamp Formatting
Create utility function:
```kotlin
fun formatRelativeTimestamp(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diff = now - timestamp

    return when {
        diff < 60_000 -> "Just now"
        diff < 3600_000 -> "${diff / 60_000}m ago"
        diff < 86400_000 -> "${diff / 3600_000}h ago"
        diff < 604800_000 -> "${diff / 86400_000}d ago"
        else -> SimpleDateFormat("MMM dd", Locale.getDefault()).format(Date(timestamp))
    }
}
```

Implement with Material Design 3 components and smooth animations.

## Success Criteria
- [ ] History screen displays
- [ ] Shows list of conversations
- [ ] Conversations sorted by most recent
- [ ] Tap conversation opens chat
- [ ] Chat loads previous messages correctly
- [ ] Can continue conversation
- [ ] Can delete conversation
- [ ] Delete confirmation dialog appears
- [ ] Deleted conversation removed from list and database
- [ ] Empty state shows when no conversations
- [ ] New chat button creates new conversation
- [ ] Pull-to-refresh works
- [ ] Timestamps display correctly (relative)
- [ ] Titles auto-generated from first message

---

# PROMPT 7: Settings & Welcome Screens

## Objective
Implement welcome screen (first launch) and settings screen with language selection.

## Instructions to AI Assistant

Please help me implement these screens:

### Welcome Screen
Create `WelcomeScreen.kt`:

**Message Content** (use string resources):
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

**Components**:
- App logo/icon (120dp, centered)
- Scrollable Column with welcome message
- "Get Started" Button (primary, filled, 56dp height)
- "Skip to Chat" TextButton

**First Launch Detection**:
Use `SharedPreferences`:
```kotlin
@Composable
fun rememberHasSeenWelcome(): MutableState<Boolean> {
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)

    return remember {
        mutableStateOf(prefs.getBoolean("has_seen_welcome", false))
    }
}
```

Show WelcomeScreen only if `has_seen_welcome == false`.

### Settings Screen
Create `SettingsScreen.kt`:

**Structure** using LazyColumn:

1. **General Section**:
   - Language → Navigate to LanguageSelectionScreen

2. **Support Section**:
   - "❤️ Support ShamelaGPT" → Open PayPal donation link

3. **About Section**:
   - About ShamelaGPT
   - Privacy Policy
   - Terms of Service

4. **Footer**:
   - Version 1.0.0 (centered, gray, small)

**Components**:
```kotlin
@Composable
fun SettingsSectionHeader(title: String)

@Composable
fun SettingsItem(
    title: String,
    subtitle: String? = null,
    icon: ImageVector,
    onClick: () -> Unit
)
```

### Language Selection Screen
Create `LanguageSelectionScreen.kt`:

**Languages**:
- English
- العربية (Arabic)

**Layout**:
- TopAppBar with back button
- LazyColumn with RadioButton list items
- Current selection marked
- Tap to select
- Save to SharedPreferences
- Update locale immediately
- Navigate back automatically

### Language Manager
Create `LanguageManager.kt`:
```kotlin
class LanguageManager(private val context: Context) {
    fun setLanguage(languageCode: String) {
        val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("selected_language", languageCode).apply()

        // Update app locale
        val locale = Locale(languageCode)
        Locale.setDefault(locale)

        val config = context.resources.configuration
        config.setLocale(locale)
        context.createConfigurationContext(config)
    }

    fun getLanguage(): String {
        val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
        return prefs.getString("selected_language", "en") ?: "en"
    }
}
```

### Donation Link Handler
Open link using Chrome Custom Tabs:

**Dependencies**:
```kotlin
implementation("androidx.browser:browser:1.7.0")
```

**Implementation**:
```kotlin
fun openDonationLink(context: Context) {
    val url = "https://www.paypal.com/donate/?hosted_button_id=MSBDG5ESU2AMU"
    val builder = CustomTabsIntent.Builder()
    val customTabsIntent = builder.build()

    try {
        customTabsIntent.launchUrl(context, Uri.parse(url))
    } catch (e: Exception) {
        // Fallback to browser
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        context.startActivity(intent)
    }
}
```

### Navigation Integration
Update navigation graph:
- WelcomeScreen → ChatScreen (clear backstack)
- SettingsScreen ↔ LanguageSelectionScreen
- SettingsScreen → AboutScreen (placeholder)

### App Entry Point
Update `MainActivity.kt`:
```kotlin
setContent {
    ShamelaGPTTheme {
        val hasSeenWelcome = rememberHasSeenWelcome()

        if (hasSeenWelcome.value) {
            ShamelaGPTApp()
        } else {
            WelcomeScreen(
                onGetStarted = {
                    // Save flag
                    hasSeenWelcome.value = true
                }
            )
        }
    }
}
```

Implement with Material Design 3 styling.

## Success Criteria
- [ ] Welcome screen shows on first launch only
- [ ] Can tap "Get Started"
- [ ] Can tap "Skip to Chat"
- [ ] Both navigate to main app
- [ ] Welcome flag persists
- [ ] Settings screen accessible via bottom nav
- [ ] All settings sections display
- [ ] Language selection screen opens
- [ ] Can select language (English/Arabic)
- [ ] Selected language persists
- [ ] UI updates when language changed
- [ ] Donation button opens PayPal in Custom Tabs
- [ ] About buttons navigate (can be placeholder)
- [ ] Version number displays correctly

---

# PROMPT 8: Navigation Integration

## Objective
Connect all screens with proper navigation using Jetpack Navigation Compose (type-safe) and bottom navigation bar.

## Instructions to AI Assistant

Please help me implement complete app navigation:

### Navigation Routes (Type-Safe)
Define routes using Kotlin Serialization:

```kotlin
import kotlinx.serialization.Serializable

@Serializable
object WelcomeRoute

@Serializable
data class ChatRoute(val conversationId: String? = null)

@Serializable
object HistoryRoute

@Serializable
object SettingsRoute

@Serializable
object LanguageSelectionRoute
```

### Navigation Graph
Create `NavGraph.kt`:

```kotlin
@Composable
fun ShamelaGPTNavGraph(
    navController: NavHostController,
    startDestination: Any,
    modifier: Modifier = Modifier
) {
    NavHost(
        navController = navController,
        startDestination = startDestination,
        modifier = modifier
    ) {
        composable<WelcomeRoute> {
            WelcomeScreen(
                onNavigateToChat = {
                    navController.navigate(ChatRoute()) {
                        popUpTo<WelcomeRoute> { inclusive = true }
                    }
                }
            )
        }

        composable<ChatRoute> { backStackEntry ->
            val route = backStackEntry.toRoute<ChatRoute>()
            ChatScreen(
                conversationId = route.conversationId
            )
        }

        composable<HistoryRoute> {
            HistoryScreen(
                onNavigateToChat = { conversationId ->
                    navController.navigate(ChatRoute(conversationId = conversationId))
                }
            )
        }

        composable<SettingsRoute> {
            SettingsScreen(
                onNavigateToLanguage = {
                    navController.navigate(LanguageSelectionRoute)
                },
                onNavigateBack = { navController.navigateUp() }
            )
        }

        composable<LanguageSelectionRoute> {
            LanguageSelectionScreen(
                onNavigateBack = { navController.navigateUp() }
            )
        }
    }
}
```

### Bottom Navigation Bar
Create `BottomNavigationBar.kt`:

```kotlin
@Composable
fun BottomNavigationBar(
    navController: NavHostController,
    modifier: Modifier = Modifier
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    NavigationBar(modifier = modifier) {
        // Chat Tab
        NavigationBarItem(
            icon = { Icon(Icons.Filled.Message, contentDescription = null) },
            label = { Text(stringResource(R.string.chat)) },
            selected = currentDestination?.route?.contains("ChatRoute") == true,
            onClick = {
                navController.navigate(ChatRoute()) {
                    popUpTo(navController.graph.findStartDestination().id) {
                        saveState = true
                    }
                    launchSingleTop = true
                    restoreState = true
                }
            }
        )

        // History Tab
        NavigationBarItem(
            icon = { Icon(Icons.Filled.History, contentDescription = null) },
            label = { Text(stringResource(R.string.history)) },
            selected = currentDestination?.route?.contains("HistoryRoute") == true,
            onClick = {
                navController.navigate(HistoryRoute) {
                    popUpTo(navController.graph.findStartDestination().id) {
                        saveState = true
                    }
                    launchSingleTop = true
                    restoreState = true
                }
            }
        )

        // Settings Tab
        NavigationBarItem(
            icon = { Icon(Icons.Filled.Settings, contentDescription = null) },
            label = { Text(stringResource(R.string.settings)) },
            selected = currentDestination?.route?.contains("SettingsRoute") == true,
            onClick = {
                navController.navigate(SettingsRoute) {
                    popUpTo(navController.graph.findStartDestination().id) {
                        saveState = true
                    }
                    launchSingleTop = true
                    restoreState = true
                }
            }
        )
    }
}
```

### Main App Structure
Create `ShamelaGPTApp.kt`:

```kotlin
@Composable
fun ShamelaGPTApp() {
    val navController = rememberNavController()

    Scaffold(
        bottomBar = {
            // Only show bottom bar on main tabs
            val currentRoute = navController.currentBackStackEntryAsState()
                .value?.destination?.route

            if (currentRoute?.contains("ChatRoute") == true ||
                currentRoute?.contains("HistoryRoute") == true ||
                currentRoute?.contains("SettingsRoute") == true) {
                BottomNavigationBar(navController = navController)
            }
        }
    ) { paddingValues ->
        ShamelaGPTNavGraph(
            navController = navController,
            startDestination = ChatRoute(),
            modifier = Modifier.padding(paddingValues)
        )
    }
}
```

### Splash Screen (Android 12+)
Add Splash Screen API:

**Dependencies**:
```kotlin
implementation("androidx.core:core-splashscreen:1.0.1")
```

**MainActivity**:
```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install splash screen
        val splashScreen = installSplashScreen()

        super.onCreate(savedInstanceState)

        // Keep splash visible while checking first launch
        var keepSplashScreen = true
        splashScreen.setKeepOnScreenCondition { keepSplashScreen }

        setContent {
            ShamelaGPTTheme {
                val context = LocalContext.current
                val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
                val hasSeenWelcome = remember {
                    mutableStateOf(prefs.getBoolean("has_seen_welcome", false))
                }

                // Hide splash after check
                LaunchedEffect(Unit) {
                    delay(500)
                    keepSplashScreen = false
                }

                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    if (hasSeenWelcome.value) {
                        ShamelaGPTApp()
                    } else {
                        WelcomeScreen(
                            onGetStarted = {
                                prefs.edit()
                                    .putBoolean("has_seen_welcome", true)
                                    .apply()
                                hasSeenWelcome.value = true
                            }
                        )
                    }
                }
            }
        }
    }
}
```

### Splash Screen Theme
Add to `themes.xml`:

```xml
<style name="Theme.App.Starting" parent="Theme.SplashScreen">
    <item name="windowSplashScreenBackground">@color/primary</item>
    <item name="windowSplashScreenAnimatedIcon">@drawable/ic_launcher_foreground</item>
    <item name="postSplashScreenTheme">@style/Theme.ShamelaGPT</item>
</style>
```

Update `AndroidManifest.xml`:
```xml
<activity
    android:name=".MainActivity"
    android:theme="@style/Theme.App.Starting">
```

### Deep Linking (Optional)
Add deep link support for opening specific conversations:
```kotlin
val uri = "shamelagpt://chat/{conversationId}"
```

Implement following Android navigation best practices.

## Success Criteria
- [ ] App launches with splash screen
- [ ] Launches to welcome (first time) or main app (returning)
- [ ] Bottom nav bar shows on main tabs
- [ ] All three tabs functional
- [ ] Tapping tab switches view correctly
- [ ] Navigation between screens works
- [ ] Back button works as expected
- [ ] Can navigate from history to chat
- [ ] Can open settings and language selection
- [ ] Can return from settings
- [ ] Tab state preserved during navigation
- [ ] No navigation glitches or crashes
- [ ] Backstack handled correctly

---

# PROMPT 9: Polish & Testing

## Objective
Add final polish, animations, error states, RTL support, accessibility, and conduct thorough testing.

## Instructions to AI Assistant

Please help me polish the app:

### RTL Support
Ensure proper RTL layout for Arabic:

**AndroidManifest.xml**:
```xml
android:supportsRtl="true"
```

**Bidirectional Text**:
```kotlin
@Composable
fun BiDirectionalText(
    text: String,
    style: TextStyle = MaterialTheme.typography.bodyLarge
) {
    val layoutDirection = remember(text) {
        if (text.firstOrNull()?.let { isRTLChar(it) } == true) {
            LayoutDirection.Rtl
        } else {
            LayoutDirection.Ltr
        }
    }

    CompositionLocalProvider(LocalLayoutDirection provides layoutDirection) {
        Text(text = text, style = style)
    }
}

fun isRTLChar(char: Char): Boolean {
    return char.code in 0x0590..0x08FF || // Hebrew, Arabic, Syriac
            char.code in 0xFB1D..0xFDFF ||
            char.code in 0xFE70..0xFEFF
}
```

**Test**:
- Switch to Arabic language
- Verify message bubbles swap sides correctly
- Check all layouts mirror properly
- Test mixed LTR/RTL text

### Dark Theme
Verify dark mode works:
- All screens look good in dark mode
- Proper contrast ratios (WCAG AA)
- Test dynamic colors on Android 12+
- Verify readability

### Animations
Add smooth animations:

**Message Appearance**:
```kotlin
items(
    items = messages,
    key = { it.id }
) { message ->
    MessageBubble(
        message = message,
        modifier = Modifier.animateItemPlacement(
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            )
        )
    )
}
```

**Tab Switching**:
```kotlin
AnimatedContent(
    targetState = selectedTab,
    transitionSpec = {
        fadeIn(animationSpec = tween(300)) with
            fadeOut(animationSpec = tween(300))
    }
) { tab ->
    // Tab content
}
```

**Button Press Feedback**:
- Use Material ripple effects (default)
- Haptic feedback for important actions

### Loading States
Ensure loading states everywhere:
- Initial app launch
- Message sending (typing indicator)
- Conversation loading (skeleton)
- Image OCR processing (progress indicator)
- Voice transcription (animated mic icon)
- History loading (circular progress)

**Create Skeleton Loader**:
```kotlin
@Composable
fun SkeletonLoader(modifier: Modifier = Modifier) {
    val infiniteTransition = rememberInfiniteTransition()
    val alpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 0.7f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000),
            repeatMode = RepeatMode.Reverse
        )
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(80.dp)
            .background(
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = alpha),
                RoundedCornerShape(12.dp)
            )
    )
}
```

### Error States
Implement comprehensive error handling:

**No Internet**:
```kotlin
@Composable
fun NoInternetBanner() {
    val isOnline by networkMonitor.isOnline.collectAsState(initial = true)

    AnimatedVisibility(visible = !isOnline) {
        Surface(
            color = MaterialTheme.colorScheme.errorContainer,
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(
                modifier = Modifier.padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Filled.CloudOff, "Offline")
                Spacer(Modifier.width(8.dp))
                Text("No internet connection")
            }
        }
    }
}
```

**Error Dialog**:
```kotlin
@Composable
fun ErrorDialog(
    error: String,
    onDismiss: () -> Unit,
    onRetry: (() -> Unit)? = null
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Error") },
        text = { Text(error) },
        confirmButton = {
            if (onRetry != null) {
                Button(onClick = {
                    onDismiss()
                    onRetry()
                }) {
                    Text("Retry")
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Dismiss")
            }
        }
    )
}
```

### Empty States
Design clean empty states:
- No conversations (History)
- No messages (Chat - first time)
- No search results

### Accessibility (TalkBack)
Implement proper accessibility:

**Content Descriptions**:
```kotlin
IconButton(
    onClick = onSend,
    modifier = Modifier.semantics {
        contentDescription = "Send message"
        role = Role.Button
    }
) {
    Icon(Icons.Filled.Send, contentDescription = null)
}
```

**Semantic Headings**:
```kotlin
Text(
    text = "Settings",
    modifier = Modifier.semantics { heading() }
)
```

**Touch Target Sizes**:
- Minimum 48dp for all interactive elements
- Proper spacing between tappable areas

**Test**:
- Enable TalkBack
- Navigate through entire app
- Verify all elements are announced correctly

### Performance Optimization
Optimize app performance:

**LazyColumn Optimization**:
```kotlin
LazyColumn(
    modifier = Modifier.fillMaxSize(),
    contentPadding = PaddingValues(16.dp)
) {
    items(
        items = messages,
        key = { it.id }
    ) { message ->
        MessageBubble(message = message)
    }
}
```

**Image Loading** (if needed):
- Use Coil for efficient image loading
- Cache images properly

**Database Queries**:
- Use proper indices
- Limit query results when needed
- Use Flow for reactive updates

**Memory Leak Prevention**:
- Properly cancel coroutines in ViewModels
- Use `viewModelScope`
- Clear resources in `onCleared()`

### Unit Tests
Write tests for critical components:

**ViewModel Test**:
```kotlin
class ChatViewModelTest {
    @Test
    fun `sendMessage updates state correctly`() = runTest {
        // Given
        val viewModel = ChatViewModel(/* mock dependencies */)

        // When
        viewModel.sendMessage("Test question")

        // Then
        val state = viewModel.uiState.value
        assertTrue(state.isLoading)
    }
}
```

**Repository Test**:
```kotlin
class ChatRepositoryTest {
    @Test
    fun `sendMessage saves to database`() = runTest {
        // Test implementation
    }
}
```

### UI Tests (Compose)
Write basic UI tests:

```kotlin
@Test
fun chatScreen_displaysMessages() {
    composeTestRule.setContent {
        ShamelaGPTTheme {
            ChatScreen()
        }
    }

    composeTestRule
        .onNodeWithTag("messageList")
        .assertExists()
}
```

### Bug Fixes
Test and fix edge cases:
- Empty input validation
- Very long messages (10,000+ characters)
- Rapid message sending
- App backgrounding during API call
- Database migration (if schema changes)
- Network interruption mid-request

Use the TESTING_CHECKLIST.md to validate everything works.

## Success Criteria
- [ ] All tests pass (unit + UI)
- [ ] RTL works perfectly for Arabic
- [ ] Dark mode looks professional
- [ ] Animations are smooth (60 FPS)
- [ ] No crashes in normal usage
- [ ] Good performance on mid-range devices
- [ ] TalkBack fully functional
- [ ] All features thoroughly tested
- [ ] No memory leaks
- [ ] Proper error handling everywhere

---

# PROMPT 10: Localization

## Objective
Complete multi-language support for English and Arabic with proper RTL layouts.

## Instructions to AI Assistant

Please help me fully localize the app:

### String Resources Structure
Create localization files:
- `app/src/main/res/values/strings.xml` (English - default)
- `app/src/main/res/values-ar/strings.xml` (Arabic)

### String Extraction
Extract ALL hardcoded strings to resources:

**English (values/strings.xml)**:
```xml
<resources>
    <!-- App -->
    <string name="app_name">ShamelaGPT</string>

    <!-- Welcome Screen -->
    <string name="welcome_title">Welcome to ShamelaGPT</string>
    <string name="welcome_message">ShamelaGPT is built upon the vast and trusted library of Shamela.ws, bringing authentic Islamic knowledge closer to everyone.\n\nOur mission is to make reliable, reference-based information accessible in a natural and conversational way — across languages, backgrounds, and levels of understanding.\n\nWhether you seek deeper insight, quick clarifications, or evidence-backed answers to common misconceptions, ShamelaGPT helps you explore Islam\'s rich heritage with accuracy, respect, and ease.\n\n\"Seek knowledge from the cradle to the grave.\" — Let this be your companion on that journey.</string>
    <string name="get_started">Get Started</string>
    <string name="skip_to_chat">Skip to Chat</string>

    <!-- Bottom Navigation -->
    <string name="chat">Chat</string>
    <string name="history">History</string>
    <string name="settings">Settings</string>

    <!-- Chat Screen -->
    <string name="chat_placeholder">Ask a question about Islam...</string>
    <string name="send">Send</string>
    <string name="typing">AI is typing...</string>
    <string name="copy">Copy</string>
    <string name="share">Share</string>
    <string name="copied">Copied to clipboard</string>
    <string name="start_conversation">Start a conversation</string>

    <!-- History Screen -->
    <string name="no_conversations">No Conversations</string>
    <string name="start_new_chat">Start a new chat to begin</string>
    <string name="delete_conversation">Delete Conversation?</string>
    <string name="delete_confirmation">This action cannot be undone.</string>
    <string name="delete">Delete</string>
    <string name="cancel">Cancel</string>
    <string name="new_chat">New Chat</string>

    <!-- Settings Screen -->
    <string name="general">General</string>
    <string name="language">Language</string>
    <string name="support">Support</string>
    <string name="support_shamelagpt">Support ShamelaGPT</string>
    <string name="about">About</string>
    <string name="about_shamelagpt">About ShamelaGPT</string>
    <string name="privacy_policy">Privacy Policy</string>
    <string name="terms_of_service">Terms of Service</string>
    <string name="version">Version %s</string>

    <!-- Language Selection -->
    <string name="select_language">Select Language</string>
    <string name="english">English</string>
    <string name="arabic">العربية</string>

    <!-- Voice Input -->
    <string name="voice_input">Voice Input</string>
    <string name="listening">Listening...</string>
    <string name="tap_to_speak">Tap to speak</string>
    <string name="permission_required">Permission Required</string>
    <string name="microphone_permission">Microphone permission is required for voice input.</string>

    <!-- Image Input -->
    <string name="image_input">Image Input</string>
    <string name="processing_image">Processing image...</string>
    <string name="take_photo">Take Photo</string>
    <string name="choose_from_gallery">Choose from Gallery</string>
    <string name="camera_permission">Camera permission is required to take photos.</string>
    <string name="storage_permission">Storage permission is required to select images.</string>

    <!-- Errors -->
    <string name="error_occurred">An error occurred</string>
    <string name="no_internet">No internet connection</string>
    <string name="retry">Retry</string>
    <string name="dismiss">Dismiss</string>
    <string name="no_text_found">No text found in image</string>
    <string name="voice_recognition_failed">Voice recognition failed</string>

    <!-- Content Descriptions -->
    <string name="send_message">Send message</string>
    <string name="voice_input_button">Voice input</string>
    <string name="image_input_button">Image input</string>
    <string name="menu">Menu</string>
    <string name="back">Back</string>
    <string name="delete_button">Delete</string>
</resources>
```

**Arabic (values-ar/strings.xml)**:
```xml
<resources>
    <!-- App -->
    <string name="app_name">شاملة GPT</string>

    <!-- Welcome Screen -->
    <string name="welcome_title">مرحبًا بك في شاملة GPT</string>
    <string name="welcome_message">شاملة GPT مبني على مكتبة شاملة الشاملة والموثوقة على Shamela.ws، مما يجعل المعرفة الإسلامية الأصيلة أقرب إلى الجميع.\n\nمهمتنا هي جعل المعلومات الموثوقة والمدعومة بالمراجع متاحة بطريقة طبيعية ومحادثة - عبر اللغات والخلفيات ومستويات الفهم.\n\nسواء كنت تسعى للحصول على رؤى أعمق، أو توضيحات سريعة، أو إجابات مدعومة بالأدلة على المفاهيم الخاطئة الشائعة، فإن شاملة GPT يساعدك على استكشاف التراث الإسلامي الغني بدقة واحترام وسهولة.\n\n\"اطلبوا العلم من المهد إلى اللحد.\" - دع هذا يكون رفيقك في هذه الرحلة.</string>
    <string name="get_started">ابدأ</string>
    <string name="skip_to_chat">تخطى إلى المحادثة</string>

    <!-- Bottom Navigation -->
    <string name="chat">محادثة</string>
    <string name="history">السجل</string>
    <string name="settings">الإعدادات</string>

    <!-- Chat Screen -->
    <string name="chat_placeholder">اطرح سؤالاً عن الإسلام...</string>
    <string name="send">إرسال</string>
    <string name="typing">الذكاء الاصطناعي يكتب...</string>
    <string name="copy">نسخ</string>
    <string name="share">مشاركة</string>
    <string name="copied">تم النسخ إلى الحافظة</string>
    <string name="start_conversation">ابدأ محادثة</string>

    <!-- History Screen -->
    <string name="no_conversations">لا توجد محادثات</string>
    <string name="start_new_chat">ابدأ محادثة جديدة للبدء</string>
    <string name="delete_conversation">حذف المحادثة؟</string>
    <string name="delete_confirmation">لا يمكن التراجع عن هذا الإجراء.</string>
    <string name="delete">حذف</string>
    <string name="cancel">إلغاء</string>
    <string name="new_chat">محادثة جديدة</string>

    <!-- Settings Screen -->
    <string name="general">عام</string>
    <string name="language">اللغة</string>
    <string name="support">الدعم</string>
    <string name="support_shamelagpt">ادعم شاملة GPT</string>
    <string name="about">حول</string>
    <string name="about_shamelagpt">حول شاملة GPT</string>
    <string name="privacy_policy">سياسة الخصوصية</string>
    <string name="terms_of_service">شروط الخدمة</string>
    <string name="version">الإصدار %s</string>

    <!-- Language Selection -->
    <string name="select_language">اختر اللغة</string>
    <string name="english">English</string>
    <string name="arabic">العربية</string>

    <!-- Voice Input -->
    <string name="voice_input">إدخال صوتي</string>
    <string name="listening">الاستماع...</string>
    <string name="tap_to_speak">اضغط للتحدث</string>
    <string name="permission_required">الإذن مطلوب</string>
    <string name="microphone_permission">مطلوب إذن الميكروفون للإدخال الصوتي.</string>

    <!-- Image Input -->
    <string name="image_input">إدخال صورة</string>
    <string name="processing_image">معالجة الصورة...</string>
    <string name="take_photo">التقاط صورة</string>
    <string name="choose_from_gallery">اختر من المعرض</string>
    <string name="camera_permission">مطلوب إذن الكاميرا لالتقاط الصور.</string>
    <string name="storage_permission">مطلوب إذن التخزين لاختيار الصور.</string>

    <!-- Errors -->
    <string name="error_occurred">حدث خطأ</string>
    <string name="no_internet">لا يوجد اتصال بالإنترنت</string>
    <string name="retry">إعادة المحاولة</string>
    <string name="dismiss">رفض</string>
    <string name="no_text_found">لم يتم العثور على نص في الصورة</string>
    <string name="voice_recognition_failed">فشل التعرف على الصوت</string>

    <!-- Content Descriptions -->
    <string name="send_message">إرسال رسالة</string>
    <string name="voice_input_button">إدخال صوتي</string>
    <string name="image_input_button">إدخال صورة</string>
    <string name="menu">القائمة</string>
    <string name="back">رجوع</string>
    <string name="delete_button">حذف</string>
</resources>
```

### Pluralization Support
For strings with plurals, use `plurals.xml`:

**values/plurals.xml**:
```xml
<resources>
    <plurals name="messages_count">
        <item quantity="one">%d message</item>
        <item quantity="other">%d messages</item>
    </plurals>
</resources>
```

**values-ar/plurals.xml**:
```xml
<resources>
    <plurals name="messages_count">
        <item quantity="zero">لا توجد رسائل</item>
        <item quantity="one">رسالة واحدة</item>
        <item quantity="two">رسالتان</item>
        <item quantity="few">%d رسائل</item>
        <item quantity="many">%d رسالة</item>
        <item quantity="other">%d رسالة</item>
    </plurals>
</resources>
```

### String Formatting
Use string formatting for dynamic content:

```kotlin
// In code
val version = stringResource(R.string.version, "1.0.0")

// In strings.xml
<string name="version">Version %s</string>
```

### RTL Layout Verification
Test RTL thoroughly:
- All screens in Arabic
- Message bubbles aligned correctly
- Icons mirror appropriately
- Text direction handled properly
- Navigation drawer (if any) opens from correct side

### Language Persistence
Ensure language selection persists:

```kotlin
class LanguageManager(private val context: Context) {
    private val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)

    fun setLanguage(languageCode: String) {
        prefs.edit().putString("selected_language", languageCode).apply()
        updateLocale(languageCode)
    }

    fun getLanguage(): String {
        return prefs.getString("selected_language", Locale.getDefault().language) ?: "en"
    }

    private fun updateLocale(languageCode: String) {
        val locale = Locale(languageCode)
        Locale.setDefault(locale)

        val config = context.resources.configuration
        config.setLocale(locale)
        context.createConfigurationContext(config)
    }
}
```

Apply locale in `MainActivity.onCreate()` before `setContent`.

### Testing Localization
Test both languages thoroughly:
- Switch between English and Arabic
- Verify all strings display correctly
- Check layout in both LTR and RTL
- Ensure no text truncation
- Verify proper word breaking
- Test mixed-language content

### No Hardcoded Strings
Audit code and remove ALL hardcoded strings:
```kotlin
// ❌ Bad
Text("Send message")

// ✅ Good
Text(stringResource(R.string.send_message))
```

Provide complete English and Arabic translations.

## Success Criteria
- [ ] All strings extracted to resources
- [ ] No hardcoded strings in code
- [ ] English version complete and natural
- [ ] Arabic version complete and natural
- [ ] Both languages display correctly
- [ ] RTL works perfectly with Arabic
- [ ] LTR works perfectly with English
- [ ] Language switching works instantly
- [ ] Language selection persists across app restarts
- [ ] No layout issues in either language
- [ ] Pluralization works correctly
- [ ] String formatting works correctly
- [ ] TalkBack announces in correct language

---

## 🎉 Congratulations!

After completing all 10 prompts, you will have a fully functional ShamelaGPT Android app with:

✅ Complete chat interface (Jetpack Compose)
✅ Voice and image input (SpeechRecognizer + ML Kit)
✅ Conversation history (Room database)
✅ Settings and preferences
✅ Multi-language support (EN/AR)
✅ RTL layout support
✅ Offline functionality
✅ Material Design 3 theming
✅ Polish and animations
✅ Accessibility (TalkBack)

## Next Steps

1. **Test thoroughly** using TESTING_CHECKLIST.md
2. **Fix any bugs** found during testing
3. **Get user feedback** from beta testers (Google Play Internal Testing)
4. **Prepare for Play Store** submission:
   - Create app icon and feature graphic
   - Write store listing (description, screenshots)
   - Set up app signing
   - Configure Play Console
5. **Plan Phase 2 features** (authentication, cloud sync, FCM, etc.)

## Remember

- Use each prompt sequentially with your AI assistant
- Test after each phase before moving forward
- Commit code after completing each prompt
- Refer to documentation files when needed:
  - `01_Architecture.md` - Architecture details
  - `02_Features.md` - Feature specifications
  - `03_API_Integration.md` - API documentation
  - `04_UI_UX.md` - UI/UX guidelines
  - `BUILD_GUIDE.md` - Build instructions
  - `TESTING_CHECKLIST.md` - Testing guide
- Ask questions if anything is unclear

**Happy Building! 🚀**
