# Android Features Document - ShamelaGPT

## Version: 1.0
## Date: 2025-11-02
## Target Platform: Android API 26+ (Android 8.0 Oreo)

---

## Table of Contents
1. [Feature Overview](#feature-overview)
2. [Phase 1 Features (MVP)](#phase-1-features-mvp)
3. [Future Phase Features](#future-phase-features)
4. [Feature Specifications](#feature-specifications)
5. [User Flows](#user-flows)
6. [Accessibility Features](#accessibility-features)

---

## 1. Feature Overview

### App Purpose
ShamelaGPT is an AI-powered Islamic knowledge app that provides authentic, reference-based answers to questions about Islam, built upon the trusted Shamela.ws library.

### Target Audience
- Muslims seeking authentic Islamic knowledge
- Students of Islamic studies
- Researchers and scholars
- Individuals with questions about Islam

### Core Value Proposition
- Authentic sources from Shamela.ws library
- Multi-language support (Arabic, English, and more)
- RTL and LTR support
- Conversational, ChatGPT-like interface
- Source citations for transparency

---

## 2. Phase 1 Features (MVP)

### 2.1 Welcome Screen
**Priority**: High
**Status**: Phase 1

#### Description
An onboarding screen that welcomes users and explains the app's purpose.

#### Components
- **Welcome Message**: Multi-paragraph text explaining ShamelaGPT's mission
- **Get Started Button**: Navigate to chat interface
- **Skip to Chat Button**: Direct access to chat (anonymous mode)

#### Implementation Notes
- Display on first launch only (track with SharedPreferences)
- Support RTL for Arabic and other RTL languages
- Responsive layout for all Android screen sizes
- Material Design 3 styling
- Dark theme support

---

### 2.2 Chat Interface
**Priority**: High
**Status**: Phase 1

#### Description
A ChatGPT-style interface for asking questions and receiving AI-generated responses.

#### Core Components

##### Message List
- **LazyColumn** for efficient scrolling
- **User messages** (aligned to end in LTR, start in RTL)
- **AI responses** (aligned to start in LTR, end in RTL)
- **Typing indicator** while AI is generating response
- **Markdown rendering** for formatted responses
- **Source citations** as clickable links
- **Timestamp** (subtle, below each message)

##### Input Bar
- **TextField** with hint: "Ask a question about Islam..."
- **Send button** (disabled when empty)
- **Voice input button** (microphone FAB)
- **Image input button** (camera/gallery FAB)

##### Additional Features
- **Copy message** (long-press)
- **Share message** (long-press)
- **Scroll to bottom FAB** (when not at bottom)
- **Loading state** with skeleton screens
- **Error state** with retry button
- **Empty state** with suggested questions

#### User Interactions
1. User types or speaks a question
2. User taps send button
3. User message appears in chat
4. Typing indicator appears
5. AI response appears (character-by-character if supported)
6. Sources appear below the answer as links
7. User can copy, share, or continue conversation

#### Implementation Notes
- Use Jetpack Compose for UI
- Implement virtual scrolling with LazyColumn
- Support bidirectional text
- Offline indicator if no network connection

---

### 2.3 Voice Input
**Priority**: High
**Status**: Phase 1

#### Description
Allow users to ask questions using voice instead of typing.

#### Technology
- **Android SpeechRecognizer** (native)
- **Locale**: Auto-detect or user-selected (Arabic, English, etc.)
- **On-Device Processing**: Google's speech-to-text

#### User Flow
1. User taps microphone FAB
2. Permission prompt appears (first time only)
3. Audio recording starts (visual indicator)
4. User speaks the question
5. User taps stop or auto-stops after silence
6. Text appears in input field
7. User reviews and edits if needed
8. User sends message

#### Implementation Details
```kotlin
class VoiceInputManager(private val context: Context) {
    private val speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
    private var isListening = false

    fun startListening(
        locale: Locale = Locale.getDefault(),
        onResult: (String) -> Unit,
        onError: (String) -> Unit
    ) {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale.toLanguageTag())
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        }

        speechRecognizer.setRecognitionListener(object : RecognitionListener {
            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                matches?.firstOrNull()?.let { onResult(it) }
            }

            override fun onError(error: Int) {
                onError(getErrorMessage(error))
            }

            // Other overrides...
        })

        speechRecognizer.startListening(intent)
        isListening = true
    }

    fun stopListening() {
        speechRecognizer.stopListening()
        isListening = false
    }
}
```

#### Permissions Required
- `android.permission.RECORD_AUDIO`

#### Supported Languages (Phase 1)
- Arabic (ar-SA)
- English (en-US)

---

### 2.4 Image Input (OCR)
**Priority**: Medium
**Status**: Phase 1

#### Description
Allow users to upload images of text (e.g., book pages, screenshots) and extract text using OCR.

#### Technology
- **ML Kit Text Recognition** (Google)
- **On-Device Processing**: Privacy-focused
- **Supported Scripts**: Latin, Arabic

#### User Flow
1. User taps camera/gallery FAB
2. Permission prompt appears (first time)
3. User selects image source:
   - Camera (take new photo)
   - Gallery (select existing photo)
4. Image appears with loading indicator
5. OCR processes text
6. Extracted text appears in input field
7. User reviews, edits, and sends

#### Implementation Details
```kotlin
class OCRManager(private val context: Context) {
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    suspend fun recognizeText(imageUri: Uri): Result<String> = withContext(Dispatchers.IO) {
        try {
            val image = InputImage.fromFilePath(context, imageUri)
            val result = recognizer.process(image).await()
            val text = result.text
            Result.success(text)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
```

#### Permissions Required
- None when using system picker (`ActivityResultContracts.GetContent`) and `TakePicture` with `FileProvider`.

#### Dependencies
- `com.google.mlkit:text-recognition:16.0.0`

#### Supported Languages
- Arabic (ar)
- English (en)

---

### 2.5 Conversation History
**Priority**: High
**Status**: Phase 1 (Local Only, no account required)

#### Description
Users can view past conversations and resume them.

#### Components
- **Conversation List Screen**
  - LazyColumn of conversations
  - Conversation title (auto-generated from first question)
  - Last message preview
  - Timestamp
  - Swipe-to-delete action
  - Pull-to-refresh

- **Conversation Detail**
  - Full message history
  - Continue conversation
  - Delete conversation option (menu)

#### Local Storage
- Stored in **Room Database**
- No server sync in Phase 1 (anonymous users)
- Persists until app deletion or manual deletion

#### Implementation Notes
- Auto-generate titles from first user question (truncate if long)
- Sort by most recent first
- Limit to last 100 conversations (configurable)
- Archive older conversations

---

### 2.6 Copy and Share
**Priority**: High
**Status**: Phase 1

#### Description
Allow users to copy individual messages or share them with others.

#### Copy Functionality
- Long-press on message bubble
- "Copy" option in context menu
- Copies message text + sources (if applicable)
- Confirmation toast: "Copied to clipboard"

#### Share Functionality
- Long-press on message bubble
- "Share" option in context menu
- Opens Android share sheet with:
  - Message text
  - App link (optional)
  - Source citations

#### Share Formats
- **Plain Text**: For messages, notes, email
- **Formatted Text**: With markdown (if supported by destination)

#### Implementation
```kotlin
// Copy to clipboard
val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
val clip = ClipData.newPlainText("Message", messageText)
clipboard.setPrimaryClip(clip)

// Share
val shareIntent = Intent(Intent.ACTION_SEND).apply {
    type = "text/plain"
    putExtra(Intent.EXTRA_TEXT, messageText)
}
context.startActivity(Intent.createChooser(shareIntent, "Share message"))
```

---

### 2.7 Donation Button
**Priority**: Medium
**Status**: Phase 1

#### Description
A prominent button linking to PayPal donation page.

#### Location
- **Settings screen** (primary)
- **About screen** (secondary)

#### Button Design
- Icon: Heart or donation symbol
- Text: "Support ShamelaGPT"
- Style: Material Design 3 filled button with accent color

#### Action
- Opens Chrome Custom Tabs (in-app browser)
- URL: `https://www.paypal.com/donate/?hosted_button_id=MSBDG5ESU2AMU`
- Fallback to external browser if Custom Tabs unavailable

#### Implementation
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

#### Dependencies
- `androidx.browser:browser:1.7.0`

---

### 2.8 Multi-Language Support
**Priority**: High
**Status**: Phase 1

#### Supported Languages (Phase 1)
- **Arabic** (ar)
- **English** (en)

#### Localization Files
- `res/values/strings.xml` (English)
- `res/values-ar/strings.xml` (Arabic)

#### String Examples
```xml
<!-- English (values/strings.xml) -->
<resources>
    <string name="app_name">ShamelaGPT</string>
    <string name="welcome_title">Welcome to ShamelaGPT</string>
    <string name="chat_placeholder">Ask a question about Islam...</string>
    <string name="send">Send</string>
</resources>

<!-- Arabic (values-ar/strings.xml) -->
<resources>
    <string name="app_name">شاملة GPT</string>
    <string name="welcome_title">مرحبًا بك في شاملة GPT</string>
    <string name="chat_placeholder">اطرح سؤالًا عن الإسلام...</string>
    <string name="send">إرسال</string>
</resources>
```

#### Language Selection
- Auto-detect from device settings
- Manual override in Settings screen
- Persistent preference (SharedPreferences)

#### RTL/LTR Support
- Declare `android:supportsRtl="true"` in AndroidManifest.xml
- Use `start`/`end` instead of `left`/`right` in layouts
- Compose automatically handles RTL with `LocalLayoutDirection`

```kotlin
@Composable
fun MessageBubble(message: Message) {
    val layoutDirection = LocalLayoutDirection.current

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (message.isUserMessage) {
            Arrangement.End
        } else {
            Arrangement.Start
        }
    ) {
        // Message content
    }
}
```

---

### 2.9 Splash Screen
**Priority**: Medium
**Status**: Phase 1

#### Description
A branded launch screen while the app initializes.

#### Implementation
Android 12+ uses **SplashScreen API**:

```xml
<!-- themes.xml -->
<style name="Theme.App.Starting" parent="Theme.SplashScreen">
    <item name="windowSplashScreenBackground">@color/primary</item>
    <item name="windowSplashScreenAnimatedIcon">@drawable/ic_launcher_foreground</item>
    <item name="postSplashScreenTheme">@style/Theme.ShamelaGPT</item>
</style>
```

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Handle the splash screen transition
        val splashScreen = installSplashScreen()

        super.onCreate(savedInstanceState)

        splashScreen.setKeepOnScreenCondition { false }

        setContent { /* ... */ }
    }
}
```

#### Dependencies
- `androidx.core:core-splashscreen:1.0.1`

---

### 2.10 Loading States
**Priority**: High
**Status**: Phase 1

#### Components

##### Skeleton Screens
- Message bubbles loading state
- Conversation list loading state

##### Progress Indicators
- `CircularProgressIndicator` for short waits
- `LinearProgressIndicator` for longer operations

##### Typing Indicator
- Three animated dots while AI is responding
- Material Design animation

#### Implementation
```kotlin
@Composable
fun TypingIndicator() {
    Row(
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        modifier = Modifier
            .background(
                color = MaterialTheme.colorScheme.surfaceVariant,
                shape = RoundedCornerShape(18.dp)
            )
            .padding(12.dp)
    ) {
        repeat(3) { index ->
            val infiniteTransition = rememberInfiniteTransition()
            val scale by infiniteTransition.animateFloat(
                initialValue = 0.5f,
                targetValue = 1.0f,
                animationSpec = infiniteRepeatable(
                    animation = tween(600),
                    repeatMode = RepeatMode.Reverse,
                    initialStartOffset = StartOffset(index * 200)
                )
            )

            Box(
                modifier = Modifier
                    .size(8.dp)
                    .scale(scale)
                    .background(
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        shape = CircleShape
                    )
            )
        }
    }
}
```

---

### 2.11 Navigation Structure
**Priority**: High
**Status**: Phase 1

#### Navigation Pattern: Bottom Navigation Bar (Material Design 3)

##### Bottom Navigation Items
1. **Chat** (Icon: `Icons.Filled.Message`)
   - New conversation
   - Quick access to chat

2. **History** (Icon: `Icons.Filled.History`)
   - Conversation list
   - Resume past conversations

3. **Settings** (Icon: `Icons.Filled.Settings`)
   - Language preferences
   - About
   - Donation link
   - App version

#### Navigation Hierarchy
```
Bottom Navigation
├── Chat Tab
│   ├── Chat Screen
│   └── (Bottom Sheet) Voice Recording
│
├── History Tab
│   ├── Conversation List Screen
│   └── Chat Screen (with history)
│
└── Settings Tab
    ├── Settings Screen
    ├── Language Settings Screen
    ├── About Screen
    └── Donation Link (Chrome Custom Tab)
```

#### Implementation
```kotlin
@Composable
fun ShamelaGPTApp() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    icon = { Icon(Icons.Filled.Message, "Chat") },
                    label = { Text("Chat") },
                    selected = currentRoute?.contains("chat") == true,
                    onClick = { navController.navigate(ChatRoute()) }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Filled.History, "History") },
                    label = { Text("History") },
                    selected = currentRoute == HistoryRoute.toString(),
                    onClick = { navController.navigate(HistoryRoute) }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Filled.Settings, "Settings") },
                    label = { Text("Settings") },
                    selected = currentRoute == SettingsRoute.toString(),
                    onClick = { navController.navigate(SettingsRoute) }
                )
            }
        }
    ) { paddingValues ->
        ShamelaGPTNavGraph(
            navController = navController,
            modifier = Modifier.padding(paddingValues)
        )
    }
}
```

---

## 2.12 UX Enhancements & Critical Bug Fixes
**Priority**: High
**Status**: Phase 1
**Source**: Improvements from iOS implementation

### Overview
This section documents critical UX improvements and bug fixes discovered during iOS development that must be implemented in the Android version.

---

### 2.12.1 Keyboard Management
**Priority**: High

#### Issues Addressed
- Keyboard hiding input field
- No tap-to-dismiss functionality
- Poor UX on smaller screens

#### Android Implementation

**1. Keyboard-Aware Layout**
```kotlin
// Use imePadding modifier for automatic keyboard adjustment
@Composable
fun ChatScreen() {
    Scaffold { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .imePadding() // Automatically adjusts for keyboard
        ) {
            MessageList(modifier = Modifier.weight(1f))
            InputBar()
        }
    }
}
```

**2. Tap-to-Dismiss Keyboard**
```kotlin
// Add clickable modifier to background
Box(
    modifier = Modifier
        .fillMaxSize()
        .pointerInput(Unit) {
            detectTapGestures(onTap = {
                focusManager.clearFocus() // Dismiss keyboard
            })
        }
) {
    // Chat content
}
```

**3. Keyboard State Handling**
```kotlin
val imeVisible by rememberUpdatedState(
    WindowInsets.ime.getBottom(LocalDensity.current) > 0
)

LaunchedEffect(imeVisible) {
    if (imeVisible) {
        // Keyboard shown - scroll to bottom
        scrollToBottom()
    }
}
```

#### Key Features
- ✅ Automatic content adjustment when keyboard appears
- ✅ Tap anywhere outside input to dismiss keyboard
- ✅ Smooth animations during keyboard show/hide
- ✅ Proper focus management

---

### 2.12.2 Voice Input Improvements
**Priority**: High

#### Issues Addressed
- No visual feedback when recording
- Can't stop recording once started
- Button disabled when input field empty

#### Android Implementation

**1. Recording State UI**
```kotlin
@Composable
fun VoiceInputButton(
    isRecording: Boolean,
    isProcessingOCR: Boolean,
    onClick: () -> Unit
) {
    FloatingActionButton(
        onClick = onClick,
        enabled = !isProcessingOCR, // Only disable during OCR
        containerColor = if (isRecording) Color.Red else MaterialTheme.colorScheme.primary
    ) {
        if (isRecording) {
            // Show stop icon (square) when recording
            Icon(
                imageVector = Icons.Default.Stop,
                contentDescription = "Stop recording",
                modifier = Modifier.size(20.dp)
            )
        } else {
            // Show microphone icon when not recording
            Icon(
                imageVector = Icons.Default.Mic,
                contentDescription = "Start voice input"
            )
        }
    }
}
```

**2. Pulsing Animation**
```kotlin
val scale by animateFloatAsState(
    targetValue = if (isRecording) 1.1f else 1.0f,
    animationSpec = infiniteRepeatable(
        animation = tween(600),
        repeatMode = RepeatMode.Reverse
    )
)

FloatingActionButton(
    modifier = Modifier.scale(scale),
    // ... other params
)
```

**3. Recording Banner**
```kotlin
@Composable
fun RecordingBanner(isVisible: Boolean) {
    AnimatedVisibility(
        visible = isVisible,
        enter = fadeIn() + slideInVertically(),
        exit = fadeOut() + slideOutVertically()
    ) {
        Surface(
            color = Color.Red.copy(alpha = 0.9f),
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(
                modifier = Modifier.padding(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.Mic, "Recording")
                Spacer(modifier = Modifier.width(8.dp))
                Text("Recording... Tap to stop", color = Color.White)
            }
        }
    }
}
```

#### Key Features
- ✅ Visual feedback with red button when recording
- ✅ Stop button functionality (tap same button to stop)
- ✅ Works when input field is empty
- ✅ Pulsing animation during recording
- ✅ Clear recording status banner

---

### 2.12.3 Optimistic UI Updates
**Priority**: High

#### Description
Show user messages immediately before API response, with rollback on error.

#### Android Implementation

```kotlin
@HiltViewModel
class ChatViewModel @Inject constructor(
    private val sendMessageUseCase: SendMessageUseCase,
    private val chatRepository: ChatRepository
) : ViewModel() {

    private val _messages = MutableStateFlow<List<Message>>(emptyList())
    val messages = _messages.asStateFlow()

    fun sendMessage(text: String) {
        if (text.isBlank()) return

        // Create optimistic user message
        val optimisticMessage = Message(
            id = "temp-${UUID.randomUUID()}",
            conversationId = conversationId,
            content = text,
            isUserMessage = true,
            timestamp = System.currentTimeMillis(),
            sources = emptyList()
        )

        // Add to UI immediately
        _messages.value = _messages.value + optimisticMessage
        _inputText.value = "" // Clear input immediately

        viewModelScope.launch {
            try {
                // Send to API
                val result = sendMessageUseCase.execute(conversationId, text)

                // Replace optimistic message with real messages
                loadMessages()

            } catch (e: Exception) {
                // Remove optimistic message on error
                _messages.value = _messages.value.filter { it.id != optimisticMessage.id }
                _inputText.value = text // Restore text to input
                _error.value = e.message
            }
        }
    }
}
```

#### Benefits
- Instant user feedback
- Better perceived performance
- Graceful error handling
- Maintains user input on failure

---

### 2.12.4 Empty Conversation Management
**Priority**: High

#### Issues Addressed
- Database cluttered with empty conversations
- No reuse of existing empty conversations
- History shows empty chats

#### Android Implementation

**1. Repository Method**
```kotlin
interface ChatRepository {
    suspend fun fetchMostRecentEmptyConversation(): Conversation?
    // ... other methods
}

class ChatRepositoryImpl @Inject constructor(
    private val conversationDao: ConversationDao
) : ChatRepository {

    override suspend fun fetchMostRecentEmptyConversation(): Conversation? {
        return conversationDao.getMostRecentEmptyConversation()
    }
}
```

**2. Room DAO Query**
```kotlin
@Dao
interface ConversationDao {
    @Query("""
        SELECT * FROM conversations
        WHERE (SELECT COUNT(*) FROM messages WHERE conversationId = conversations.id) = 0
        ORDER BY updatedAt DESC
        LIMIT 1
    """)
    suspend fun getMostRecentEmptyConversation(): ConversationEntity?
}
```

**3. ViewModel Logic**
```kotlin
class MainViewModel @Inject constructor(
    private val chatRepository: ChatRepository
) : ViewModel() {

    suspend fun ensureConversationExists(): String {
        // Try to find existing empty conversation
        chatRepository.fetchMostRecentEmptyConversation()?.let {
            return it.id
        }

        // No empty conversation found, create new one
        return chatRepository.createConversation("New Conversation").id
    }

    suspend fun validateCurrentConversation(conversationId: String): String {
        // Check if conversation still exists
        val exists = chatRepository.getConversation(conversationId) != null

        return if (exists) {
            conversationId
        } else {
            // Conversation was deleted, create new one
            ensureConversationExists()
        }
    }
}
```

**4. Filter Empty Conversations from History**
```kotlin
class HistoryViewModel @Inject constructor(
    private val chatRepository: ChatRepository
) : ViewModel() {

    val conversations = chatRepository.observeConversations()
        .map { conversations ->
            // Filter out empty conversations
            conversations.filter { it.messages.isNotEmpty() }
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )
}
```

#### Key Features
- ✅ Reuses empty conversations instead of creating new ones
- ✅ Creates conversations on-the-fly when sending first message
- ✅ Validates conversation exists before sending message
- ✅ Auto-recovers after "Clear All" without restart
- ✅ Empty conversations hidden from history

---

### 2.12.5 Scroll Anchoring Strategy
**Priority**: Medium

#### Issue
Long assistant responses are cut off at the top when new messages arrive.

#### Solution
Anchor new messages at their **top** instead of **bottom** for better UX.

#### Android Implementation

```kotlin
@Composable
fun ChatScreen(viewModel: ChatViewModel) {
    val messages by viewModel.messages.collectAsState()
    val listState = rememberLazyListState()
    val coroutineScope = rememberCoroutineScope()

    LazyColumn(
        state = listState,
        reverseLayout = true, // Messages flow from bottom to top
        modifier = Modifier.fillMaxSize()
    ) {
        items(messages.reversed()) { message ->
            MessageBubble(message = message)
        }
    }

    // Scroll to top of new message (bottom of list in reverse layout)
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            coroutineScope.launch {
                // Scroll to first item (newest message)
                listState.animateScrollToItem(0)
            }
        }
    }
}
```

#### Benefits
- Beginning of long responses always visible
- Better UX for multi-paragraph answers
- Consistent behavior across messages

---

### 2.12.6 Markdown Rendering
**Priority**: High

#### Approach
Use stock Android markdown library (Markwon) without preprocessing.

#### Android Implementation

**1. Add Dependency**
```gradle
dependencies {
    implementation "io.noties.markwon:core:4.6.2"
    implementation "io.noties.markwon:ext-strikethrough:4.6.2"
    implementation "io.noties.markwon:ext-tables:4.6.2"
}
```

**2. Simple Markdown Parsing**
```kotlin
@Composable
fun MarkdownText(
    markdown: String,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val markwon = remember {
        Markwon.builder(context)
            .usePlugin(StrikethroughPlugin.create())
            .usePlugin(TablesPlugin.create(context))
            .build()
    }

    AndroidView(
        modifier = modifier,
        factory = { ctx ->
            TextView(ctx).apply {
                movementMethod = LinkMovementMethod.getInstance()
            }
        },
        update = { textView ->
            markwon.setMarkdown(textView, markdown)
        }
    )
}
```

**3. Usage in Message Bubble**
```kotlin
@Composable
fun MessageBubble(message: Message) {
    Card {
        if (message.isUserMessage) {
            Text(text = message.content) // Plain text for user
        } else {
            MarkdownText(markdown = message.content) // Markdown for AI
        }
    }
}
```

#### Supported Markdown
- ✅ Headings (`#`, `##`, `###`)
- ✅ Lists (numbered and bulleted)
- ✅ Bold, italic, strikethrough
- ✅ Code blocks
- ✅ Links
- ✅ Tables

---

### 2.12.7 Comprehensive Logging
**Priority**: High

#### Technology
Use **Timber** for Android (equivalent to iOS's os.log)

#### Implementation

**1. Add Dependency**
```gradle
dependencies {
    implementation "com.jakewharton.timber:timber:5.0.1"
}
```

**2. Initialize in Application Class**
```kotlin
class ShamelaGPTApp : Application() {
    override fun onCreate() {
        super.onCreate()

        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        } else {
            // Plant production tree (Crashlytics, etc.)
            Timber.plant(ProductionTree())
        }
    }
}
```

**3. Category-Based Logging**
```kotlin
object AppLogger {
    private const val TAG_NETWORK = "Network"
    private const val TAG_UI = "UI"
    private const val TAG_VOICE = "VoiceInput"
    private const val TAG_OCR = "OCR"
    private const val TAG_DATABASE = "Database"
    private const val TAG_CHAT = "Chat"

    fun network(message: String) = Timber.tag(TAG_NETWORK).d(message)
    fun ui(message: String) = Timber.tag(TAG_UI).d(message)
    fun voice(message: String) = Timber.tag(TAG_VOICE).d(message)
    fun ocr(message: String) = Timber.tag(TAG_OCR).d(message)
    fun database(message: String) = Timber.tag(TAG_DATABASE).d(message)
    fun chat(message: String) = Timber.tag(TAG_CHAT).d(message)

    fun error(tag: String, message: String, throwable: Throwable? = null) {
        Timber.tag(tag).e(throwable, message)
    }
}
```

**4. Usage Throughout App**
```kotlin
class ChatViewModel {
    fun sendMessage(text: String) {
        AppLogger.chat("Sending message: ${text.take(50)}...")

        viewModelScope.launch {
            try {
                val result = sendMessageUseCase.execute(conversationId, text)
                AppLogger.chat("Message sent successfully")
            } catch (e: Exception) {
                AppLogger.error("Chat", "Failed to send message", e)
            }
        }
    }
}
```

#### Log Categories
- **Network**: API calls, responses, errors
- **UI**: Screen navigation, user interactions
- **VoiceInput**: Speech recognition events
- **OCR**: Text recognition processing
- **Database**: Room queries, inserts, updates
- **Chat**: Message sending, conversation management

---

## Implementation Priority

### Must-Have (Phase 1)
1. ✅ Empty Conversation Management (Critical bug fix)
2. ✅ Optimistic UI Updates (UX improvement)
3. ✅ Keyboard Management (UX improvement)
4. ✅ Voice Input Improvements (Feature completion)
5. ✅ Comprehensive Logging (Debugging essential)

### Should-Have (Phase 1)
6. ✅ History Filter (Hide empty conversations)
7. ✅ Markdown Rendering (Content quality)
8. ✅ Scroll Anchoring (UX polish)

---

## 3. Future Phase Features

### 3.1 Authentication & Profile Management
**Priority**: High
**Status**: Phase 2

#### Features
- Email/password authentication
- Google Sign-In
- User profile creation
- Avatar upload
- Preference management

#### Benefits
- Cloud sync for conversations
- Cross-device access
- Personalized experience

---

### 3.2 Push Notifications
**Priority**: Medium
**Status**: Phase 2

#### Use Cases
- New response notification (if async)
- Daily Islamic knowledge tip
- Reminder for unanswered questions

#### Implementation
- Firebase Cloud Messaging (FCM)
- Notification channels for different types
- Notification preferences in Settings

---

### 3.3 Share Extension
**Priority**: Medium
**Status**: Phase 2

#### Description
Allow users to share text from other apps directly to ShamelaGPT.

#### Implementation
- Intent filter for ACTION_SEND
- Handle `text/plain` MIME type
- Open app with pre-filled question

---

### 3.4 Advanced Features
**Priority**: Low
**Status**: Phase 3+

- **Voice Responses**: AI responds with audio
- **Bookmarks**: Save favorite responses
- **Search**: Search within conversation history
- **Export**: Export conversations as PDF/text
- **Custom Themes**: User-selectable color themes
- **Widgets**: Home screen widgets for quick questions
- **Wear OS App**: Quick questions on smartwatch

---

## 4. Feature Specifications

### 4.1 Message Rendering

#### Markdown Support
Use **compose-richtext** library for Markdown rendering:

```kotlin
dependencies {
    implementation("com.halilibo.compose-richtext:richtext-ui-material3:0.17.0")
    implementation("com.halilibo.compose-richtext:richtext-commonmark:0.17.0")
}
```

#### Supported Markdown
- **Headers**: # H1, ## H2, ### H3
- **Bold**: **text** or __text__
- **Italic**: *text* or _text_
- **Lists**: Ordered and unordered
- **Links**: [text](url)
- **Code**: `inline code` and ```code blocks```
- **Blockquotes**: > quote

#### Source Citations
- Rendered as clickable links
- Format: `book_name` - `source_url`
- Opens in Chrome Custom Tabs

---

### 4.2 Conversation Management

#### Auto-Title Generation
```kotlin
fun generateConversationTitle(question: String): String {
    val maxLength = 50
    val trimmed = question.trim()

    return if (trimmed.length > maxLength) {
        trimmed.take(maxLength) + "..."
    } else {
        trimmed
    }
}
```

#### Conversation Limits
- **Max conversations**: 100 (configurable)
- **Max messages per conversation**: Unlimited (but paginated)
- **Auto-archive**: Conversations older than 90 days

---

## 5. User Flows

### 5.1 First-Time User Flow
```
App Launch
    ↓
Splash Screen (1-2s)
    ↓
Welcome Screen
    ↓
[Get Started] or [Skip to Chat]
    ↓
Chat Screen (New Conversation)
    ↓
User asks question
    ↓
AI responds with answer
    ↓
User continues or navigates to History
```

### 5.2 Returning User Flow
```
App Launch
    ↓
Splash Screen (1-2s)
    ↓
Chat Screen (Last Conversation or New)
    ↓
User can:
  - Continue current conversation
  - Start new conversation
  - View history (bottom nav)
  - Access settings (bottom nav)
```

### 5.3 Voice Input Flow
```
User taps microphone FAB
    ↓
[First time] Permission request
    ↓
Recording starts (visual indicator)
    ↓
User speaks
    ↓
User taps stop or auto-stops
    ↓
Text appears in input field
    ↓
User reviews/edits
    ↓
User sends message
```

### 5.4 Image OCR Flow
```
User taps camera/gallery FAB
    ↓
[First time] Permission request
    ↓
User selects image source:
  - Camera: Take photo
  - Gallery: Select existing photo
    ↓
Image selected
    ↓
OCR processing (loading indicator)
    ↓
Text extracted and appears in input field
    ↓
User reviews/edits
    ↓
User sends message
```

---

## 6. Accessibility Features

### 6.1 TalkBack (Screen Reader)
- All interactive elements have content descriptions
- Semantic headings for navigation
- Proper focus order

```kotlin
IconButton(
    onClick = { /* ... */ },
    modifier = Modifier.semantics {
        contentDescription = "Send message"
        role = Role.Button
    }
) {
    Icon(Icons.Filled.Send, contentDescription = null)
}
```

### 6.2 Large Text Support
- Support Android's text scaling preferences
- Use `sp` units for text sizes
- Test with largest text sizes

### 6.3 High Contrast
- Ensure sufficient color contrast ratios (WCAG AA)
- Support system high contrast mode

### 6.4 Touch Target Sizes
- Minimum 48dp for interactive elements
- Proper spacing between tappable areas

---

## Feature Priority Matrix

| Feature | Priority | Phase | Effort | Impact |
|---------|----------|-------|--------|--------|
| Chat Interface | High | 1 | High | High |
| Welcome Screen | High | 1 | Low | Medium |
| Voice Input | High | 1 | Medium | High |
| Image OCR | Medium | 1 | Medium | Medium |
| Conversation History | High | 1 | Medium | High |
| Copy/Share | High | 1 | Low | Medium |
| Donation Button | Medium | 1 | Low | Low |
| Multi-Language | High | 1 | High | High |
| Splash Screen | Medium | 1 | Low | Low |
| Authentication | High | 2 | High | High |
| Push Notifications | Medium | 2 | Medium | Medium |
| Share Extension | Medium | 2 | Low | Medium |
| Voice Responses | Low | 3 | High | Medium |
| Search | Low | 3 | Medium | Medium |

---

## Conclusion

This feature set provides a comprehensive ChatGPT-like experience for Islamic knowledge seekers using modern Android development practices. Phase 1 focuses on core functionality without requiring user authentication, allowing users to immediately start using the app. The implementation leverages Jetpack Compose, Material Design 3, and Android best practices for a native, accessible, and performant user experience.
