# iOS UI/UX Document - ShamelaGPT

## Version: 1.0
## Date: 2025-11-02
## Target Platform: iOS 15.0+
## Design Language: iOS Human Interface Guidelines

---

## Table of Contents
1. [Design Philosophy](#design-philosophy)
2. [Color System](#color-system)
3. [Typography](#typography)
4. [Navigation Structure](#navigation-structure)
5. [Screen Designs](#screen-designs)
6. [Component Library](#component-library)
7. [Multi-Language & RTL Support](#multi-language--rtl-support)
8. [Dark Mode](#dark-mode)
9. [Accessibility](#accessibility)
10. [Animations & Transitions](#animations--transitions)
11. [iOS-Specific Patterns](#ios-specific-patterns)

---

## 1. Design Philosophy

### Principles
- **Clarity**: Text is legible, icons are precise, content is easy to understand
- **Deference**: UI doesn't compete with content
- **Depth**: Visual layers and motion communicate hierarchy
- **Islamic Aesthetics**: Respectful, scholarly, and culturally appropriate
- **Simplicity**: Remove unnecessary elements

### Brand Values
- **Authenticity**: Trustworthy sources from Shamela.ws
- **Accessibility**: Knowledge for everyone
- **Respect**: Culturally sensitive Islamic content
- **Modern**: Contemporary interface with traditional values

---

## 2. Color System

### Primary Colors

```swift
extension Color {
    // Primary
    static let primary = Color(hex: "#10B981") // Emerald-500 (Islamic color)
    static let primaryLight = Color(hex: "#4C8C4A")
    static let primaryDark = Color(hex: "#003300")

    // Secondary
    static let secondary = Color(hex: "#424242") // Dark Gray
    static let secondaryLight = Color(hex: "#6D6D6D")

    // Accent
    static let accent = Color(hex: "#F59E0B") // Amber-500 (for highlights)
}
```

### Semantic Colors

```swift
extension Color {
    // Light Mode
    static let background = Color(uiColor: .systemBackground) // White
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground) // Light Gray
    static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)

    // Text
    static let textPrimary = Color(uiColor: .label) // Black in light, white in dark
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)

    // Messages
    static let userMessageBackground = Color(hex: "#007AFF") // iOS Blue
    static let aiMessageBackground = Color(uiColor: .secondarySystemBackground)
    static let userMessageText = Color.white
    static let aiMessageText = Color(uiColor: .label)

    // Status
    static let success = Color.green
    static let error = Color.red
    static let warning = Color.orange
}
```

### Color Usage

| Element | Light Mode | Dark Mode |
|---------|------------|-----------|
| Background | White (#FFFFFF) | Black (#000000) |
| User Message | iOS Blue (#007AFF) | iOS Blue (#0A84FF) |
| AI Message | Light Gray (#F2F2F7) | Dark Gray (#1C1C1E) |
| Primary Button | Deep Green (#1B5E20) | Deep Green (#4C8C4A) |
| Text | Black (#000000) | White (#FFFFFF) |
| Link | iOS Blue (#007AFF) | iOS Blue (#0A84FF) |

---

## 3. Typography

### System Fonts
Use **San Francisco (SF)** for Latin text and **SF Arabic** for Arabic text (iOS automatically selects).

### Text Styles

```swift
extension Font {
    // Headlines
    static let largeTitle = Font.largeTitle // 34pt, Bold
    static let title1 = Font.title // 28pt, Regular
    static let title2 = Font.title2 // 22pt, Regular
    static let title3 = Font.title3 // 20pt, Regular

    // Body
    static let body = Font.body // 17pt, Regular
    static let callout = Font.callout // 16pt, Regular
    static let subheadline = Font.subheadline // 15pt, Regular
    static let footnote = Font.footnote // 13pt, Regular
    static let caption1 = Font.caption // 12pt, Regular
    static let caption2 = Font.caption2 // 11pt, Regular
}
```

### Usage Guidelines

| Element | Font Style | Weight | Size |
|---------|-----------|--------|------|
| Screen Title | Large Title | Bold | 34pt |
| Welcome Message | Title 2 | Regular | 22pt |
| Message Content | Body | Regular | 17pt |
| Timestamps | Caption 1 | Regular | 12pt |
| Input Placeholder | Body | Regular | 17pt |
| Button Labels | Body | Semibold | 17pt |
| Tab Bar Labels | Caption 2 | Regular | 11pt |

### Dynamic Type Support
All text must support Dynamic Type (accessibility text sizes).

```swift
Text("Welcome")
    .font(.largeTitle)
    .dynamicTypeSize(.medium...DynamicTypeSize.xxxLarge)
```

---

## 4. Navigation Structure

### Navigation Pattern: Bottom Tab Bar (iOS Standard)

#### Tab Bar Configuration

```swift
TabView {
    ChatView()
        .tabItem {
            Label("Chat", systemImage: "message.fill")
        }
        .tag(0)

    HistoryView()
        .tabItem {
            Label("History", systemImage: "clock.fill")
        }
        .tag(1)

    SettingsView()
        .tabItem {
            Label("Settings", systemImage: "gearshape.fill")
        }
        .tag(2)
}
.accentColor(.primary)
```

#### Tab Icons & Labels

| Tab | Icon (SF Symbol) | Label (EN) | Label (AR) | Badge |
|-----|------------------|------------|------------|-------|
| Chat | `message.fill` | Chat | دردشة | - |
| History | `clock.fill` | History | السجل | Count (optional) |
| Settings | `gearshape.fill` | Settings | الإعدادات | - |

### Navigation Hierarchy

```
┌─────────────────────────────────────────┐
│           Tab Bar (Bottom)               │
└─────────────────────────────────────────┘
         │           │           │
         ▼           ▼           ▼
    ┌────────┐  ┌─────────┐  ┌──────────┐
    │  Chat  │  │ History │  │ Settings │
    └────────┘  └─────────┘  └──────────┘
         │           │           │
         ▼           ▼           ▼
    New Conv    Conv List    Settings
         │           │         Options
         ▼           ▼           │
    Chat View   Chat Detail     ▼
         │       (Resume)    Language
         │                      │
         ▼                      ▼
    Voice/Image              About
    Input                      │
                               ▼
                            Donation
```

### Navigation Gestures
- **Swipe Back**: Return to previous screen (iOS standard edge swipe)
- **Pull to Refresh**: Refresh conversation list
- **Swipe to Delete**: Delete conversations from list
- **Long Press**: Context menu for messages (copy, share)

---

## 5. Screen Designs

### 5.1 Splash Screen

#### Design
- **Background**: Gradient from `primaryDark` to `primary`
- **Logo**: Centered, white color
- **Tagline**: "Authentic Islamic Knowledge" (localized)
- **Loading Indicator**: Subtle circular progress indicator below logo

#### Implementation
```swift
struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.primaryDark, .primary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                Text("Authentic Islamic Knowledge")
                    .font(.title3)
                    .foregroundColor(.white)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
    }
}
```

---

### 5.2 Welcome Screen

#### Layout
```
┌─────────────────────────────────────┐
│                                     │
│        🌿 ShamelaGPT Logo          │
│                                     │
│  ┌───────────────────────────┐    │
│  │  Welcome Message          │    │
│  │  (Scrollable)             │    │
│  │                           │    │
│  │  Multi-paragraph text     │    │
│  │  with proper spacing      │    │
│  │                           │    │
│  └───────────────────────────┘    │
│                                     │
│  ┌───────────────────────────┐    │
│  │    Get Started  (Primary) │    │
│  └───────────────────────────┘    │
│                                     │
│     Skip to Chat (Text Button)     │
│                                     │
└─────────────────────────────────────┘
```

#### Design Specifications
- **Logo**: 80pt height, centered
- **Message Container**: Padding 20pt, scrollable
- **Get Started Button**:
  - Height: 50pt
  - Corner Radius: 12pt
  - Background: `primary` color
  - Text: White, Semibold, 17pt
  - Shadow: 0 2 4 rgba(0,0,0,0.1)
- **Skip Button**:
  - Text color: `textSecondary`
  - Font: Body, Regular

#### Implementation
```swift
struct WelcomeView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Logo
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 80)

            // Welcome Message
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("🌿 Welcome to ShamelaGPT")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(welcomeMessage)
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: 400)

            Spacer()

            // Buttons
            VStack(spacing: 16) {
                Button(action: getStarted) {
                    Text("Get Started")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primary)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                }

                Button(action: skipToChat) {
                    Text("Skip to Chat")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private func getStarted() {
        hasSeenWelcome = true
        coordinator.navigate(to: .chat(conversationId: nil))
    }

    private func skipToChat() {
        hasSeenWelcome = true
        coordinator.navigate(to: .chat(conversationId: nil))
    }
}
```

---

### 5.3 Chat Screen

#### Layout
```
┌─────────────────────────────────────┐
│  ← Back    [Conversation Title]  ⋯ │ Navigation Bar
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────┐             │ AI Message
│  │ Answer text...    │             │
│  │ with markdown     │             │
│  └───────────────────┘             │
│  Sources: [Link] [Link]            │
│  12:30 PM                          │
│                                     │
│             ┌───────────────────┐  │ User Message
│             │ Question text... │  │
│             └───────────────────┘  │
│                          12:29 PM  │
│                                     │
│  ┌───────────────────┐             │ AI Message
│  │ Previous answer   │             │
│  └───────────────────┘             │
│                                     │
├─────────────────────────────────────┤
│  [🖼️] [🎤] [Text Input...  ] [📤] │ Input Bar
└─────────────────────────────────────┘
```

#### Components

##### Navigation Bar
- **Title**: Conversation title (truncated to 1 line)
- **Back Button**: Standard iOS back chevron
- **Menu Button**: Three-dot menu (⋯) for actions:
  - New Conversation
  - Delete Conversation
  - Share Conversation

##### Message List
- **ScrollView** with **LazyVStack**
- **Reverse layout**: Newest at bottom
- **Auto-scroll** to bottom on new message
- **Pull to load more** (pagination)

##### User Message Bubble
- **Alignment**: Trailing (right in LTR, left in RTL)
- **Background**: `userMessageBackground` (iOS Blue)
- **Text Color**: White
- **Corner Radius**: 18pt
- **Padding**: 12pt horizontal, 8pt vertical
- **Max Width**: 70% of screen width
- **Tail**: Small triangle pointing to trailing edge

##### AI Message Bubble
- **Alignment**: Leading (left in LTR, right in RTL)
- **Background**: `aiMessageBackground` (Light Gray)
- **Text Color**: `textPrimary`
- **Corner Radius**: 18pt
- **Padding**: 12pt horizontal, 8pt vertical
- **Max Width**: 85% of screen width
- **Markdown Rendering**: Formatted text
- **Sources**: Tappable links below message
- **Tail**: Small triangle pointing to leading edge

##### Timestamp
- **Font**: Caption 1 (12pt)
- **Color**: `textTertiary`
- **Position**: Below message, aligned with bubble

##### Input Bar
- **Height**: 50pt (minimum), expands with text
- **Background**: `secondaryBackground`
- **Border**: 1pt separator line
- **Components**:
  - Image button (🖼️): Camera/Gallery
  - Microphone button (🎤): Voice input
  - Text field: Expandable, placeholder "Ask a question..."
  - Send button (📤): Disabled when empty, `primary` color when enabled

#### Implementation
```swift
struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            TypingIndicatorView()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                    }
                }
            }

            // Input Bar
            InputBarView(
                text: $viewModel.inputText,
                isLoading: viewModel.isLoading,
                onSend: viewModel.sendMessage,
                onVoiceInput: viewModel.startVoiceInput,
                onImageInput: viewModel.selectImage
            )
        }
        .navigationTitle(viewModel.conversationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("New Conversation", action: viewModel.startNewConversation)
                    Button("Delete", role: .destructive, action: viewModel.deleteConversation)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
```

---

### 5.4 Conversation History Screen

#### Layout
```
┌─────────────────────────────────────┐
│          History                    │ Navigation Bar
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ What is Islam?              │   │ Conversation Cell
│  │ Here's a comprehensive...   │   │
│  │ 2 hours ago              →  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Five Pillars explanation    │   │
│  │ Islam has five pillars...   │   │
│  │ Yesterday                →  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Prayer times               │   │
│  │ Prayer times vary by...     │   │
│  │ 3 days ago               →  │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

#### Conversation Cell Design
- **Height**: 80pt (minimum)
- **Padding**: 16pt
- **Background**: Card with subtle shadow
- **Title**: Bold, 17pt, 1 line (truncated)
- **Preview**: Regular, 15pt, 1-2 lines (truncated)
- **Timestamp**: Caption, 12pt, `textSecondary`
- **Chevron**: System `chevron.right`
- **Swipe Actions**:
  - Delete (red background)
  - Share (blue background)

#### Implementation
```swift
struct ConversationListView: View {
    @StateObject private var viewModel: ConversationListViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(destination: ChatView(conversationId: conversation.id)) {
                        ConversationCellView(conversation: conversation)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.delete(conversation)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            viewModel.share(conversation)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Chat") {
                        viewModel.createNewConversation()
                    }
                }
            }
            .overlay {
                if viewModel.conversations.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "No Conversations",
                        message: "Start a new chat to begin"
                    )
                }
            }
        }
    }
}
```

---

### 5.5 Settings Screen

#### Layout
```
┌─────────────────────────────────────┐
│          Settings                   │ Navigation Bar
├─────────────────────────────────────┤
│                                     │
│  GENERAL                           │ Section Header
│  ┌─────────────────────────────┐   │
│  │ Language            English → │   │
│  └─────────────────────────────┘   │
│                                     │
│  SUPPORT                           │
│  ┌─────────────────────────────┐   │
│  │ ❤️  Support ShamelaGPT    → │   │
│  └─────────────────────────────┘   │
│                                     │
│  ABOUT                             │
│  ┌─────────────────────────────┐   │
│  │ About ShamelaGPT         → │   │
│  │ Privacy Policy           → │   │
│  │ Terms of Service         → │   │
│  └─────────────────────────────┘   │
│                                     │
│  Version 1.0.0                     │ Footer
│                                     │
└─────────────────────────────────────┘
```

#### Implementation
```swift
struct SettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"

    var body: some View {
        NavigationView {
            Form {
                Section("GENERAL") {
                    NavigationLink {
                        LanguageSelectionView()
                    } label: {
                        HStack {
                            Text("Language")
                            Spacer()
                            Text(languageName(selectedLanguage))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }

                Section("SUPPORT") {
                    Link(destination: URL(string: "https://www.paypal.com/donate/?hosted_button_id=MSBDG5ESU2AMU")!) {
                        HStack {
                            Text("❤️ Support ShamelaGPT")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }

                Section("ABOUT") {
                    NavigationLink("About ShamelaGPT", destination: AboutView())
                    NavigationLink("Privacy Policy", destination: PrivacyView())
                    NavigationLink("Terms of Service", destination: TermsView())
                }

                Section {
                    HStack {
                        Spacer()
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func languageName(_ code: String) -> String {
        switch code {
        case "en": return "English"
        case "ar": return "العربية"
        default: return code
        }
    }
}
```

---

## 6. Component Library

### 6.1 Message Bubble

```swift
struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isUserMessage { Spacer() }

            VStack(alignment: message.isUserMessage ? .trailing : .leading, spacing: 4) {
                // Message Content
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isUserMessage ? .white : .textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.isUserMessage ? Color.userMessageBackground : Color.aiMessageBackground
                    )
                    .cornerRadius(18)
                    .textSelection(.enabled) // iOS 15+

                // Sources (if AI message)
                if !message.isUserMessage, let sources = message.sources, !sources.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(sources, id: \.sourceURL) { source in
                            Link(destination: URL(string: source.sourceURL)!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "book.closed")
                                        .font(.caption)
                                    Text(source.bookName)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }

            if !message.isUserMessage { Spacer() }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = message.content
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            Button {
                shareMessage(message.content)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }

    private func shareMessage(_ text: String) {
        // Share functionality
    }
}
```

### 6.2 Input Bar

```swift
struct InputBarView: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    let onVoiceInput: () -> Void
    let onImageInput: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Image Input Button
            Button(action: onImageInput) {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            .disabled(isLoading)

            // Voice Input Button
            Button(action: onVoiceInput) {
                Image(systemName: "mic")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            .disabled(isLoading)

            // Text Field
            TextField("Ask a question...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(20)
                .lineLimit(1...5)
                .disabled(isLoading)

            // Send Button
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(text.isEmpty ? .gray : .primary)
            }
            .disabled(text.isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
    }
}
```

### 6.3 Typing Indicator

```swift
struct TypingIndicatorView: View {
    @State private var animatingDots: [Bool] = [false, false, false]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatingDots[index] ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animatingDots[index]
                    )
            }
        }
        .padding(12)
        .background(Color.aiMessageBackground)
        .cornerRadius(18)
        .onAppear {
            animatingDots = [true, true, true]
        }
    }
}
```

### 6.4 Empty State

```swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.textTertiary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
```

---

## 7. Multi-Language & RTL Support

### Language Support
- **English** (en)
- **Arabic** (ar)

### RTL Layout Handling

#### Automatic Mirroring
SwiftUI automatically mirrors UI for RTL languages. Use semantic alignments:

```swift
// ✅ Correct
HStack(alignment: .leading) { ... }
Text("Hello").frame(maxWidth: .infinity, alignment: .leading)

// ❌ Avoid
HStack(alignment: .left) { ... }
```

#### Environment Detection

```swift
@Environment(\.layoutDirection) var layoutDirection

var isRTL: Bool {
    layoutDirection == .rightToLeft
}
```

#### Custom RTL Adjustments

```swift
struct MessageView: View {
    @Environment(\.layoutDirection) var layoutDirection
    let message: Message

    var body: some View {
        HStack {
            if shouldAlignTrailing {
                Spacer()
            }

            MessageBubble(message: message)

            if !shouldAlignTrailing {
                Spacer()
            }
        }
    }

    private var shouldAlignTrailing: Bool {
        if layoutDirection == .rightToLeft {
            return !message.isUserMessage // Opposite in RTL
        } else {
            return message.isUserMessage
        }
    }
}
```

### Text Bidirectional Support

```swift
Text(arabicText)
    .environment(\.layoutDirection, .rightToLeft) // Force RTL for Arabic text
```

### Image Mirroring

```swift
Image(systemName: "chevron.right")
    .flipsForRightToLeftLayoutDirection(true) // Auto-flip in RTL
```

---

## 8. Dark Mode

### Automatic Support
Use semantic colors for automatic dark mode support:

```swift
// ✅ Adapts to dark mode
Color(uiColor: .systemBackground)
Color(uiColor: .label)

// ❌ Fixed color
Color.white
Color.black
```

### Custom Dark Mode Colors

```swift
extension Color {
    static let customBackground: Color = {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(hex: "#1C1C1E") :  // Dark mode
                UIColor(hex: "#FFFFFF")    // Light mode
        })
    }()
}
```

### Color Scheme Testing

```swift
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChatView()
                .preferredColorScheme(.light)

            ChatView()
                .preferredColorScheme(.dark)
        }
    }
}
```

---

## 9. Accessibility

### VoiceOver Labels

```swift
Button(action: sendMessage) {
    Image(systemName: "arrow.up.circle.fill")
}
.accessibilityLabel("Send message")
.accessibilityHint("Sends your question to ShamelaGPT")
```

### Semantic Grouping

```swift
VStack {
    Text("What is Islam?")
    Text("2 hours ago")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("What is Islam? 2 hours ago")
```

### Dynamic Type

```swift
Text("Welcome")
    .font(.title)
    .minimumScaleFactor(0.5) // Scale down if needed
    .lineLimit(nil) // Allow multiple lines
```

### Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation {
    reduceMotion ? .none : .easeInOut
}
```

---

## 10. Animations & Transitions

### Message Appearance

```swift
ForEach(messages) { message in
    MessageView(message: message)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        ))
}
.animation(.easeOut(duration: 0.3), value: messages)
```

### Button Feedback

```swift
Button(action: send) {
    Text("Send")
}
.buttonStyle(ScaleButtonStyle())

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

### Loading State

```swift
if isLoading {
    ProgressView()
        .transition(.opacity)
}
```

---

## 11. iOS-Specific Patterns

### Context Menu (Long Press)

```swift
Text(message.content)
    .contextMenu {
        Button(action: copy) {
            Label("Copy", systemImage: "doc.on.doc")
        }
        Button(action: share) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
```

### Swipe Actions

```swift
List {
    ForEach(conversations) { conversation in
        ConversationRow(conversation: conversation)
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
        Button(role: .destructive, action: delete) {
            Label("Delete", systemImage: "trash")
        }
    }
}
```

### Pull to Refresh

```swift
List(conversations) { conversation in
    ConversationRow(conversation: conversation)
}
.refreshable {
    await viewModel.refresh()
}
```

### Alert & Confirmation

```swift
.alert("Delete Conversation", isPresented: $showDeleteAlert) {
    Button("Delete", role: .destructive, action: deleteConversation)
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This action cannot be undone.")
}
```

### Share Sheet

```swift
.sheet(isPresented: $showShareSheet) {
    ActivityViewController(activityItems: [messageText])
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
```

---

## Conclusion

This UI/UX design follows iOS Human Interface Guidelines while incorporating Islamic aesthetics through the color palette (deep green and gold accents). The interface is:

- **Native**: Uses iOS standard patterns (tab bar, swipe actions, context menus)
- **Accessible**: VoiceOver support, Dynamic Type, high contrast
- **Responsive**: Adapts to RTL languages, dark mode, and different screen sizes
- **Modern**: SwiftUI-based, clean, minimal design
- **Culturally Appropriate**: Respectful colors and design language for Islamic content

The design prioritizes content readability and ease of use, ensuring users can focus on learning about Islam through the authentic sources provided by Shamela.ws.
