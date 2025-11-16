# ShamelaGPT iOS v1.0 — Use Cases & Feature Checklist

Purpose: authoritative, exhaustive use-case list for iOS v1.0 to align unit/UI tests, mocks, SwiftUI previews, and Android parity. Treat every item as “must hold true” unless explicitly deferred.

## Global Behaviors
- Platforms: iOS/Android must match flows, copy, and UI states; MVVM separation enforced.
- Personas: authenticated user vs guest (local-only conversations, no cloud sync). Guest mode is enabled via Welcome “Skip” or Auth “Continue as guest.”
- State persistence: last tab and last conversation remembered; guest conversation id persisted separately; threadId persisted when provided.
- Localization: en + ar supported; RTL/LTR respected; language affects fonts in lists and message rendering.
- Accessibility: key controls labeled; chat/history/settings tabs accessible; VoiceOver and dynamic type should remain usable; alerts/sheets should be reachable.
- Networking: no live calls in tests; mock URLProtocol and env flags drive UI tests; offline mode keeps user messages locally.

## Use Cases

### App Launch & Welcome
- First launch when not authenticated shows Welcome with animated logo, mission text, Get Started, Skip to Chat.
- Get Started dismisses Welcome and shows Auth if not logged in; Skip enables guest mode and routes to Chat.
- Returning authenticated user skips Welcome and opens last tab/conversation (defaults to Chat).
- App resumes validates last conversation still exists; if missing, starts a new chat.
- Deep links (scheme `shamelagpt://chat|history|settings`) route to the correct tab/conversation.

#### Website & Universal Links
- The app supports universal links for `https://shamelagpt.com` and `https://www.shamelagpt.com`.
- URLs like `https://shamelagpt.com/chat?id=<conversationId>` must open the app and route to the specified conversation (or start a new chat if `id` is absent).
- The site must host an `apple-app-site-association` file at `/.well-known/apple-app-site-association` (or at the site root) with the correct `appID` and paths (`/chat` and `/chat/*`).

### Authentication (Email/Password + Guest)
- Toggle between Sign In and Sign Up; validation errors shown for empty credentials.
- Sign Up supports optional display name; errors surfaced from repository.
- Sign In stores session; successful auth hides Auth/Welcome and opens Chat.
- Continue as Guest marks guest session; later Logout exits guest/auth and re-enables Welcome.
- Logout clears tokens/guest flag, resets selected tab to Chat, and shows Welcome/Auth on next entry.

### Chat — Text & Core Flow
- Send enabled only when trimmed input is non-empty and not loading/recording/OCR.
- Whitespace-only input rejected with no side effects.
- On send: optimistic user bubble added immediately; input clears; error state reset.
- Guest vs Auth: guest conversations are local-only; auth may stream or use SendMessageUseCase depending on mode.
- Streaming SSE (guest/auth): handles metadata/threadId/sessionId; shows “thinking” bubble; typing indicator while loading; assembled assistant message updates in place; [DONE]/done event finalizes; persists threadId when received.
- Non-streaming (auth use case): save user message, call API, parse markdown, save assistant with sources, reload to replace optimistic.
- Error handling: network/API errors set errorMessage and requireAuth flag on 401/403; optimistic bubble removed; input restored; retry button re-sends.
- Scroll behavior: auto-scroll to latest (prefers last user message); typing/thinking anchored; tab bar hides/shows on tap.
- Message rendering: Markdown for assistant; source links open Safari; copy/share context menu includes sources; fact-check messages show image + detected language tag; timestamps shown.

### Voice Input
- Mic permission request: success starts recording; denial surfaces VoiceInputError alert.
- Recording state: pulsing mic, recording banner; can stop via button; partial results stream into input; send disabled while recording.
- Errors: recognizer unavailable, request creation failure, recognition failure—show alert and clear state; clear error action works.

### OCR / Fact-Check Flow
- Camera button opens source sheet; handles permission states (authorized/notDetermined/denied/restricted) with dedicated denied sheets and Settings link.
- Camera unavailable on simulator: log warning, bypass picker in UI tests, optionally inject test image.
- Photo Library selection mirrors permission logic.
- OCR processing: show spinner banner; Vision extracts text + detected language; compress image ≤200KB; populate confirmation sheet with editable text and preview image.
- Confirmation sheet: Done sends fact-check message with imageData + detectedLanguage metadata; Cancel clears OCR state.
- Errors: invalid image, no text, recognition failure set ocrError alert; clear error action works.

#### Share / Fact-Check Integration (Platform Parity)
- iOS: a Share extension (or Action extension) accepts images, text, and webpage URLs and forwards data to the main app (via pasteboard and a `shamelagpt://factcheck` deep link). The extension must be configured to appear in the system Share sheet for images, text, and webpage URLs.
- Android: the app receives `ACTION_SEND`/`ACTION_SEND_MULTIPLE` intents for `text/plain` and `image/*`. The shared payload (text or compressed image bytes) should be persisted (SharedPreferences or temp file) and consumed by the Chat screen to show the OCR confirmation and allow the user to submit a fact-check message.
- Both platforms: shared images should be compressed to <=200KB and provided to the app alongside detected language metadata when available.

### Conversation Management & History
- Auto-title from first user message (50-char truncation); “New Conversation” fallback.
- New conversation created lazily on first send; reuse if provided id; threadId persisted and reused.
- History list (auth): shows conversations sorted by updatedAt; displays title/preview/timestamp; badges fact-check and local-only; tap opens chat; pull-to-refresh syncs remote; includes conversations even if messages not yet hydrated. Fact-check badge requires `conversationType == factCheck`—set when first fact-check message is saved and backfill when fact-check messages already exist.
- History (guest): locked view with sign-in CTA; no list until authenticated.
- Delete single: swipe → confirmation dialog → removes conversation; errors surface inline.
- Delete all (auth): toolbar Clear All with confirmation; deletes local and remote when online.
- Share conversation: share sheet exports title, link, updated time, preview text.
- Start new chat from history or ellipsis menu: warning if current conversation has messages; clears lastConversationId and shows fresh chat.

### Settings & Preferences
- Language selection (en/ar) with language-specific fonts; selecting persists and pops view; restart note visible.
- AI Preferences (auth only): custom system prompt editor; response preferences length/style/focus selectable lists; refresh preferences action; errors shown inline.
- Guest view: preferences locked state with sign-in CTA.
- Support: Donate link opens PayPal in SafariView.
- About/Privacy/Terms pages navigable from list.
- Sign Out available when authenticated; disabled when guest.

### Error & Edge Handling
- Network errors mapped to user messages (no connection, timeout, 4xx/5xx, invalid URL/response, 429 Too Many Requests).
- Offline send: user message persisted locally (guest/local-only); API skipped without connectivity; retry when network restored (per repository logic).
- Missing conversation/threadId fallback uses conversationId for continuity and persists it.
- Hydration: when opening chat with existing conversation, loadMessages merges optimistic vs persisted and reapplies threadId; skip reload only when loading and optimistic is ahead of DB.
- Camera/Photo permission denial shows guidance sheet; settings deep link available.
- UI-test overrides: mock networking via UserDefaults/env, simulated permissions, simulated OCR success with injected text/lang.

### Accessibility & Localization Use Cases
- All primary controls (send, mic, camera, error banner buttons, tab items, welcome CTAs) have VoiceOver labels and hints; chat messages expose combined content + timestamp and include actions for copy/share/source links.
- VoiceOver reads source counts and timestamps; error and permission banners are reachable with actionable buttons.
- Dynamic type: chat, history, settings, and OCR confirmation scale across accessibility text sizes; verify XXL and above for truncation/overlap.
- Reduce Motion: message/typing/banner animations respect the reduced-motion environment toggle and fall back to instant state changes.
- RTL: chat bubbles align per sender; input, history rows, and settings respect leading/trailing; Arabic fonts applied where needed.
- Dark interface/high contrast: uses semantic colors; contrast is expected to meet WCAG but should be validated on custom tokens (emerald/amber).

### Preview Scenarios (SwiftUI)
- Chat: empty state with suggestions; loading/hydrating overlay; chat with user + assistant + sources; thinking/typing indicators; error banner; fact-check bubble with image/lang tag.
- Input bar: enabled/disabled, recording state, OCR processing state, multiline text.
- History: empty guest lock, empty auth, populated list with fact-check/local badges.
- Settings: authenticated vs guest, preferences filled vs empty, donate sheet.
- Welcome: first-launch animation; auth: sign-in vs sign-up mode with error.

## Parity Guidance
- Android must mirror these flows (state gating, errors, banners, permission UX, badges, and data fields: imageData, detectedLanguage, isLocalOnly, threadId handling, SSE thinking stream).
- Tests/mocks should cover success + error + edge cases for every use case above, using platform-appropriate mocking (MockURLProtocol vs MockK/Retrofit).

## Accessibility Phase 2 Backlog (extensible)
- VoiceOver rotor + granular labels for copy/share/source links, error banners, and OCR confirmation controls; add UITests in `shamelagpt-ios/shamelagptUITests/AccessibilityUITests.swift`.
- Voice Control readiness: ensure concise command-friendly labels/identifiers on send/mic start-stop/camera/retry; add a scripted Voice Control pass in UITests.
- Differentiate without color: add icons/text badges for fact-check/local/offline/error states in message bubbles and conversation cards so status isn’t color-only.
- Contrast audit: run Accessibility Inspector contrast checks on custom emerald/amber tokens; adjust any failing colors in theming docs/resources and add a checklist item to `shamelagpt-ios/docs/TESTING_CHECKLIST.md`.
- Dynamic Type hardening: validate XXL+ on Chat/History/Settings/OCR confirmation; fix any truncation/overlap and cover with UITests for large content sizes.
- Reduced Motion coverage: ensure message/typing/banner animations all short-circuit when `accessibilityReduceMotion` is on; add snapshot/UITest expectations for the no-animation path.
