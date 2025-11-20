# iOS Features Document - ShamelaGPT

## Version: 1.0
## Date: 2025-11-02
## Target Platform: iOS 15.0+

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
- **Welcome Message** (provided by user):
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

- **Get Started Button**: Navigate to chat interface
- **Skip to Chat Button**: Direct access to chat (anonymous mode)

#### Implementation Notes
- Display on first launch only (track with UserDefaults)
- Support RTL for Arabic and other RTL languages
- Responsive layout for all iPhone sizes
- Dark mode support

---

### 2.2 Chat Interface
**Priority**: High
**Status**: Phase 1

#### Description
A ChatGPT-style interface for asking questions and receiving AI-generated responses.

#### Core Components

##### Message List
- **Scrollable message history**
- **User messages** (right-aligned, blue bubble)
- **AI responses** (left-aligned, gray/white bubble)
- **Typing indicator** while AI is generating response
- **Markdown rendering** for formatted responses
- **Source citations** as tappable links
- **Timestamp** (subtle, below each message)

##### Input Bar
- **Text input field** with placeholder: "Ask a question about Islam..."
- **Send button** (disabled when empty)
- **Voice input button** (microphone icon)
- **Image input button** (camera/gallery icon)
- **Character counter** (optional, if there's a limit)

##### Additional Features
- **Copy message** (long-press menu)
- **Share message** (long-press menu)
- **Scroll to bottom button** (when not at bottom)
- **Loading state** with skeleton screens
- **Error state** with retry button
- **Empty state** with suggested questions

#### User Interactions
1. User types or speaks a question
2. User taps send button
3. User message appears in chat
4. Typing indicator appears
5. AI response streams in character-by-character (if supported) or appears in full
6. Sources appear below the answer as links
7. User can copy, share, or continue conversation

#### Implementation Notes
- Use LazyVStack for efficient message rendering
- Implement virtual scrolling for large conversations
- Cache images inline if responses include image references
- Support @-mentions for future multi-user features
- Offline indicator if no network connection

---

### 2.3 Voice Input
**Priority**: High
**Status**: Phase 1

#### Description
Allow users to ask questions using voice instead of typing.

#### Technology
- **Speech Framework** (Apple native)
- **Locale**: Auto-detect or user-selected (Arabic, English, etc.)
- **Local Processing**: All speech-to-text happens on-device (privacy)

#### User Flow
1. User taps microphone button
2. Permission prompt appears (first time only)
3. Audio recording starts (visual indicator)
4. User speaks the question
5. User taps stop or auto-stops after silence
6. Text appears in input field
7. User reviews and edits if needed
8. User sends message

#### Implementation Details
```swift
import Speech

class VoiceInputManager: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false

    func requestPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }

    func startRecording() throws {
        // Implementation
    }

    func stopRecording() {
        // Implementation
    }
}
```

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
- **Vision Framework** (Apple native)
- **VNRecognizeTextRequest** for text detection
- **Local Processing**: All OCR happens on-device

#### User Flow
1. User taps camera/gallery button
2. Permission prompt appears (first time)
3. User selects image from:
   - Camera (take new photo)
   - Photo library
4. Image appears with loading indicator
5. OCR processes text
6. Extracted text appears in input field
7. User reviews, edits, and sends

#### Implementation Details
```swift
import Vision

class OCRManager: ObservableObject {
    @Published var extractedText: String = ""
    @Published var isProcessing: Bool = false

    func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        isProcessing = true

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self?.isProcessing = false
                return
            }

            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            DispatchQueue.main.async {
                self?.extractedText = recognizedStrings.joined(separator: "\n")
                self?.isProcessing = false
            }
        }

        request.recognitionLanguages = ["ar-SA", "en-US"]
        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}
```

#### Supported Languages
- Arabic (ar-SA)
- English (en-US)

---

### 2.5 Conversation History
**Priority**: High
**Status**: Phase 1 (Local Only, no account required)

#### Description
Users can view past conversations and resume them.

#### Components
- **Conversation List Screen**
  - List of all conversations
  - Conversation title (auto-generated from first question)
  - Last message preview
  - Timestamp
  - Swipe-to-delete action
  - Pull-to-refresh

- **Conversation Detail**
  - Full message history
  - Continue conversation
  - Delete conversation button

#### Local Storage
- Stored in **Core Data**
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
- Opens iOS share sheet with:
  - Message text
  - App link (optional)
  - Source citations

#### Share Formats
- **Plain Text**: For messages, notes, email
- **Formatted Text**: With markdown (if supported by destination)
- **Image**: Screenshot of message (future enhancement)

#### Implementation
```swift
import SwiftUI

struct MessageView: View {
    let message: Message

    var body: some View {
        Text(message.content)
            .contextMenu {
                Button(action: copyMessage) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                Button(action: shareMessage) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
    }

    private func copyMessage() {
        UIPasteboard.general.string = message.content
        // Show toast notification
    }

    private func shareMessage() {
        let activityVC = UIActivityViewController(
            activityItems: [message.content],
            applicationActivities: nil
        )
        // Present activity view controller
    }
}
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
- **Welcome screen** (optional, subtle)

#### Button Design
- Icon: Heart or donation symbol
- Text: "Support ShamelaGPT" or "Donate"
- Color: Accent color (stands out but not intrusive)

#### Action
- Opens Safari in-app browser
- URL: `https://www.paypal.com/donate/?hosted_button_id=MSBDG5ESU2AMU`
- Opens in `SFSafariViewController` for security

#### Implementation
```swift
import SafariServices

Button("Support ShamelaGPT") {
    let url = URL(string: "https://www.paypal.com/donate/?hosted_button_id=MSBDG5ESU2AMU")!
    let safariVC = SFSafariViewController(url: url)
    present(safariVC, animated: true)
}
```

---

### 2.8 Multi-Language Support
**Priority**: High
**Status**: Phase 1

#### Supported Languages (Phase 1)
- **Arabic** (ar)
- **English** (en)

#### Localization Files
- `ar.lproj/Localizable.strings`
- `en.lproj/Localizable.strings`

#### String Examples
```
// English
"welcome.title" = "Welcome to ShamelaGPT";
"chat.placeholder" = "Ask a question about Islam...";
"chat.send" = "Send";

// Arabic
"welcome.title" = "مرحبًا بك في شاملة GPT";
"chat.placeholder" = "اطرح سؤالًا عن الإسلام...";
"chat.send" = "إرسال";
```

#### Language Selection
- Auto-detect from device settings
- Manual override in Settings screen
- Persistent preference

#### RTL/LTR Support
- **SwiftUI automatically handles RTL**
- Use `.leading` and `.trailing` instead of `.left` and `.right`
- Test with Arabic language to ensure proper layout

```swift
@Environment(\.layoutDirection) var layoutDirection

var isRTL: Bool {
    layoutDirection == .rightToLeft
}
```

---

### 2.9 Splash Screen
**Priority**: Medium
**Status**: Phase 1

#### Description
A branded launch screen while the app initializes.

#### Design
- **Logo**: ShamelaGPT logo centered
- **Tagline**: "Authentic Islamic Knowledge" (localized)
- **Background**: Brand color gradient
- **Loading indicator**: Subtle spinner or progress bar

#### Duration
- Minimum: 1 second (brand visibility)
- Maximum: 3 seconds (or until app ready)

#### Implementation
- Use `LaunchScreen.storyboard` for initial splash
- Custom splash view for extended loading (if needed)

---

### 2.10 Loading States
**Priority**: High
**Status**: Phase 1

#### Components

##### Skeleton Screens
- Message bubbles loading state
- Conversation list loading state

##### Progress Indicators
- Circular spinner for short waits
- Linear progress bar for longer operations

##### Typing Indicator
- Three animated dots while AI is responding
- Appears in last message position

#### Implementation
```swift
struct TypingIndicatorView: View {
    @State private var dotScale: [CGFloat] = [1.0, 1.0, 1.0]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScale[index])
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: dotScale[index]
                    )
            }
        }
        .onAppear {
            dotScale = [1.3, 1.3, 1.3]
        }
    }
}
```

---

### 2.11 Navigation Structure
**Priority**: High
**Status**: Phase 1

#### Navigation Pattern: Bottom Tab Bar (iOS Standard)

##### Tabs
1. **Chat** (SF Symbol: `message.fill`)
   - New conversation
   - Quick access to chat

2. **History** (SF Symbol: `clock.fill`)
   - Conversation list
   - Resume past conversations

3. **Settings** (SF Symbol: `gearshape.fill`)
   - Language preferences
   - About
   - Donation link
   - App version

#### Navigation Hierarchy
```
Tab Bar
├── Chat Tab
│   ├── Chat View
│   └── (Modal) Voice Recording
│
├── History Tab
│   ├── Conversation List View
│   └── Conversation Detail View (Push)
│       └── Chat View (with history)
│
└── Settings Tab
    ├── Settings View
    ├── Language Settings (Push)
    ├── About (Push)
    └── Donation Link (Safari)
```

---

## 3. Future Phase Features

### 3.1 Authentication & Profile Management
**Priority**: High
**Status**: Phase 2

#### Features
- Email/password authentication
- Social login (Apple, Google)
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
- APNs integration
- Notification preferences in Settings

---

### 3.3 Share Extension
**Priority**: Medium
**Status**: Phase 2

#### Description
Allow users to share text from other apps directly to ShamelaGPT.

#### Implementation
- iOS Share Extension target
- Accepts text content
- Opens app with pre-filled question

---

### 3.4 Advanced Features
**Priority**: Low
**Status**: Phase 3+

- **Voice Responses**: AI responds with audio
- **Bookmarks**: Save favorite responses
- **Search**: Search within conversation history
- **Export**: Export conversations as PDF/text
- **Themes**: Custom color themes
- **Widgets**: iOS 14+ home screen widgets
- **Siri Integration**: "Hey Siri, ask ShamelaGPT..."
- **Today Extension**: Quick access from notification center
- **Apple Watch App**: Quick questions on watch

---

## 4. Feature Specifications

### 4.1 Message Rendering

#### Markdown Support
- **Headers**: # H1, ## H2, ### H3
- **Bold**: **text** or __text__
- **Italic**: *text* or _text_
- **Lists**: Ordered and unordered
- **Links**: [text](url)
- **Code**: `inline code` and ```code blocks```
- **Blockquotes**: > quote

#### Source Citations
- Rendered as tappable links
- Format: `book_name` - `source_url`
- Opens in Safari in-app browser

---

### 4.2 Conversation Management

#### Auto-Title Generation
```swift
func generateConversationTitle(from question: String) -> String {
    let maxLength = 50
    let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmed.count > maxLength {
        return String(trimmed.prefix(maxLength)) + "..."
    }

    return trimmed
}
```

#### Conversation Limits
- **Max conversations**: 100 (configurable)
- **Max messages per conversation**: Unlimited (but paginated)
- **Auto-archive**: Conversations older than 90 days

---

### 4.3 Accessibility

#### VoiceOver Support
- All buttons and controls labeled
- Message content readable
- Proper heading hierarchy

#### Dynamic Type
- Support all text sizes
- Scalable UI elements

#### Color Contrast
- WCAG AA compliance
- High contrast mode support

#### Keyboard Navigation
- Tab order for all interactive elements
- Return key sends message

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
  - View history
  - Access settings
```

### 5.3 Voice Input Flow
```
User taps microphone button
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
User taps camera/gallery button
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

### 6.1 VoiceOver
- All UI elements properly labeled
- Semantic headings for screen readers
- Descriptive hints for buttons
- Custom VoiceOver actions for complex interactions

### 6.2 Dynamic Type
- Support all text size categories
- Scalable UI that adapts to user preferences
- Test with largest text sizes

### 6.3 High Contrast Mode
- Respect user's high contrast preference
- Ensure sufficient color contrast ratios
- Test in both light and dark modes

### 6.4 Reduce Motion
- Disable animations when user prefers reduced motion
- Provide instant feedback instead of animated transitions

### 6.5 Keyboard Shortcuts (iPad)
- Cmd + N: New conversation
- Cmd + Return: Send message
- Cmd + F: Search (future feature)

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
| Share Extension | Medium | 2 | Medium | Low |
| Voice Responses | Low | 3 | High | Medium |
| Search | Low | 3 | Medium | Medium |

---

## Conclusion

This feature set provides a comprehensive ChatGPT-like experience for Islamic knowledge seekers, with authentic sources, multi-language support, and modern mobile app features. Phase 1 focuses on core functionality without requiring user authentication, allowing users to immediately start using the app. Future phases will add social features, cloud sync, and advanced capabilities.
