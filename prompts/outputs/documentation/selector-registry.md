# Selector Registry Guidance

**Date**: 2026-02-17
**Stage/Task**: Execution `T01` selector contract

## Source of Truth
- iOS app selectors:
  - `shamelagpt-ios/shamelagpt/Presentation/Accessibility/AccessibilityID.swift`
- iOS UI test selectors:
  - `shamelagpt-ios/shamelagptUITests/Helpers/UITestIDs.swift`
- Android app/test selectors:
  - `shamelagpt-android/app/src/main/java/com/shamelagpt/android/presentation/common/TestTags.kt`

## Critical Domains
- `welcome`
- `auth`
- `chat`
- `history`
- `settings`

## Parity Mapping (Representative)
- Welcome:
  - iOS: `AccessibilityID.Welcome.getStartedButton`, `AccessibilityID.Welcome.skipToChatButton`
  - Android: `TestTags.Welcome.GetStartedButton`, `TestTags.Welcome.SkipButton`
- Auth:
  - iOS: `AccessibilityID.Auth.emailTextField`, `...signInButton`
  - Android: `TestTags.Auth.EmailField`, `...SignInButton`
- Chat:
  - iOS: `AccessibilityID.Chat.messageInputField`, `...sendButton`, `...messageBubble`
  - Android: `TestTags.Chat.MessageInputField`, `...SendButton`, `...MessageBubble`
- History:
  - iOS: `AccessibilityID.History.conversationCard(_:)`
  - Android: `TestTags.History.conversationCard(...)`
- Settings:
  - iOS: `AccessibilityID.Settings.languageRow`, `languageOption(_:)`, `languageCheckmark(_:)`
  - Android: `TestTags.Settings.LanguageItem`, `languageOption(code)`, `languageSelectedCheckmark(code)`

## Usage Rules
- Never introduce inline selector string literals in critical UI tests.
- UI code must attach identifiers/tags via registry constants only.
- Any rename requires same-PR updates in:
  1. registry constants
  2. affected tests
  3. this registry document
