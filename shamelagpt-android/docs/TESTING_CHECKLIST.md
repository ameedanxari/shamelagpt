# ShamelaGPT Android - Testing Checklist

## Version: 1.0
## Target: Android API 26+

---

## 📋 Overview

Use this comprehensive checklist to validate that your ShamelaGPT Android app meets all requirements and works correctly across different scenarios.

---

## ✅ Phase 1: Project Setup Testing

### Build & Configuration
- [ ] Project builds without errors (Build → Make Project)
- [ ] Project builds without warnings
- [ ] App launches on Android Emulator
- [ ] App launches on physical device (if available)
- [ ] App icon displays correctly
- [ ] Splash screen shows properly (Android 12+ SplashScreen API)
- [ ] App name is "ShamelaGPT"
- [ ] Package name is correct (com.shamelagpt)

### Dependencies
- [ ] All Gradle dependencies resolved
- [ ] Koin dependency injection working
- [ ] No duplicate dependencies
- [ ] Build variants configured (Debug/Release)
- [ ] ProGuard rules set for Release

---

## ✅ Phase 2: Data Layer Testing

### Room Database
- [ ] Database initializes successfully
- [ ] Can create Conversation entities
- [ ] Can create Message entities
- [ ] Can save data to Room
- [ ] Can fetch data from Room
- [ ] Can update entities
- [ ] Can delete entities
- [ ] Relationships work (Conversation ↔ Messages)
- [ ] App doesn't crash on invalid data
- [ ] Database migrations work (if applicable)

### Repository Pattern
- [ ] ChatRepository saves messages locally
- [ ] ConversationRepository creates conversations
- [ ] Data persists after app restart
- [ ] Offline data access works

---

## ✅ Phase 3: Networking Layer Testing

### API Integration
- [ ] Health check endpoint works (`/api/health`)
- [ ] Chat endpoint works (`/api/chat`)
- [ ] Can send message with question only
- [ ] Can send message with thread_id
- [ ] Response parsing works correctly
- [ ] Error handling works for 4xx errors
- [ ] Error handling works for 5xx errors
- [ ] Network timeout handled gracefully (30s)

### Offline Support
- [ ] App works without internet connection
- [ ] Messages queued when offline
- [ ] Shows "No internet" indicator when offline
- [ ] Syncs data when back online
- [ ] Cached data loads instantly

---

## ✅ Phase 4: Chat Feature Testing

### Message Display
- [ ] User messages align to end (LTR) / start (RTL)
- [ ] AI messages align to start (LTR) / end (RTL)
- [ ] Messages display in correct order
- [ ] Timestamps show below each message
- [ ] Long messages wrap correctly
- [ ] Markdown renders properly (using compose-richtext)
- [ ] Code blocks display correctly
- [ ] Links are clickable
- [ ] Source citations display and are clickable

### Message Input
- [ ] TextField accepts input
- [ ] Send button disabled when empty
- [ ] Send button enabled when text entered
- [ ] Sending message clears input field
- [ ] Can send multiple messages in sequence
- [ ] Typing in text field updates UI
- [ ] Keyboard shows/hides properly

### Message Interaction
- [ ] Long press shows context menu (or similar Android pattern)
- [ ] Can copy message text
- [ ] Can share message via share sheet
- [ ] Copied text includes sources
- [ ] Share intent opens correctly

### Conversation Flow
- [ ] Can start new conversation
- [ ] thread_id persists across messages
- [ ] Conversation continues correctly
- [ ] Scroll to bottom works
- [ ] Auto-scroll on new message works
- [ ] LazyColumn performs well with many messages

### Loading States
- [ ] Typing indicator shows while loading
- [ ] Typing indicator animates smoothly
- [ ] Loading indicator disappears when response received
- [ ] Can't send new message while loading

---

## ✅ Phase 5: Voice & Image Input Testing

### Voice Input (SpeechRecognizer)
- [ ] Microphone button/FAB shows
- [ ] Permission prompt appears (first time)
- [ ] Recording starts when tapped
- [ ] Visual indicator shows during recording
- [ ] Can stop recording
- [ ] Auto-stops after silence
- [ ] Transcribed text appears in input field
- [ ] Can edit transcribed text
- [ ] Works in English
- [ ] Works in Arabic
- [ ] Error handling for no permission
- [ ] Error handling for recognition failure
- [ ] Works on API 26+

### Image Input (ML Kit OCR)
- [ ] Camera/Gallery button/FAB shows
- [ ] Permission prompt appears (first time)
- [ ] Can take new photo with CameraX
- [ ] Can select from gallery
- [ ] OCR processes image
- [ ] Loading indicator shows during OCR
- [ ] Extracted text appears in input field
- [ ] Can edit extracted text
- [ ] Works with printed Arabic text
- [ ] Works with printed English text
- [ ] Error handling for no permission
- [ ] Error handling for OCR failure
- [ ] Error handling for no text found

---

## ✅ Phase 6: History Feature Testing

### Conversation List
- [ ] Shows all saved conversations
- [ ] Sorted by most recent first
- [ ] Shows conversation title
- [ ] Shows last message preview
- [ ] Shows timestamp
- [ ] Empty state shows when no conversations
- [ ] Pull-to-refresh works (SwipeRefresh)
- [ ] Tap conversation navigates to chat

### Conversation Management
- [ ] Can create new conversation
- [ ] Can resume existing conversation
- [ ] Conversation title auto-generated from first question
- [ ] Long titles truncate correctly
- [ ] Swipe-to-dismiss works (or delete button)
- [ ] Delete confirmation appears
- [ ] Deleted conversation removed from list
- [ ] Deleted conversation removed from database

---

## ✅ Phase 7: Settings & Welcome Testing

### Welcome Screen
- [ ] Shows on first launch only
- [ ] Logo displays correctly
- [ ] Welcome message displays fully
- [ ] Can scroll message if long
- [ ] "Get Started" button works
- [ ] "Skip to Chat" button works
- [ ] Doesn't show on subsequent launches
- [ ] SharedPreferences tracks first launch

### Settings Screen
- [ ] Settings tab/screen accessible
- [ ] All sections display
- [ ] Language option shows current language
- [ ] Can navigate to language selection
- [ ] Donation button opens PayPal in Chrome Custom Tabs
- [ ] About button works
- [ ] Privacy Policy button works
- [ ] Terms of Service button works
- [ ] Version number displays

### Language Selection
- [ ] Shows English option
- [ ] Shows Arabic option
- [ ] Can select language
- [ ] Selection persists (SharedPreferences)
- [ ] App strings update immediately
- [ ] Locale changes applied

---

## ✅ Phase 8: Navigation Testing

### Bottom Navigation Bar
- [ ] Three nav items show (Chat, History, Settings)
- [ ] Correct icons for each item (Material Icons)
- [ ] Correct labels for each item
- [ ] Nav item selection works
- [ ] Active item highlighted
- [ ] Navigation state persists when switching
- [ ] Deep linking works (if implemented)

### Screen Navigation
- [ ] Can navigate between all screens
- [ ] Back button works on all screens
- [ ] Navigation animations smooth
- [ ] No navigation bugs or glitches
- [ ] Bottom sheets work correctly
- [ ] Dismissals work correctly
- [ ] Up navigation in TopAppBar works

---

## ✅ Phase 9: Polish & Testing

### UI/UX
- [ ] All animations smooth (60 FPS)
- [ ] No layout glitches or jank
- [ ] Proper spacing and padding (Material Design 3)
- [ ] Colors match design system (emerald/teal theme)
- [ ] Typography consistent (Roboto/system fonts)
- [ ] Buttons have proper tap targets (48dp min)
- [ ] Loading states for all async operations
- [ ] Error states for all failure scenarios
- [ ] Empty states for all empty data scenarios
- [ ] Material You dynamic colors work (Android 12+)

### Performance
- [ ] App launches in < 3 seconds
- [ ] Scrolling is smooth (60 FPS minimum)
- [ ] No memory leaks (use LeakCanary)
- [ ] Memory usage reasonable (< 150MB)
- [ ] Battery usage acceptable
- [ ] No excessive network calls
- [ ] Room queries optimized

### Error Handling
- [ ] Network errors shown to user
- [ ] API errors shown with helpful messages
- [ ] Database errors handled gracefully
- [ ] Permission errors shown clearly
- [ ] App doesn't crash on any error
- [ ] Proper logging for debugging

---

## ✅ Phase 10: Localization Testing

### English (en)
- [ ] All strings localized in strings.xml
- [ ] No hardcoded English strings in code
- [ ] Proper grammar and spelling
- [ ] Text fits in UI elements
- [ ] Left-to-right layout correct

### Arabic (ar)
- [ ] All strings translated in values-ar/strings.xml
- [ ] RTL layout working (`android:supportsRtl="true"`)
- [ ] Text aligned correctly (right-aligned)
- [ ] Navigation items in Arabic
- [ ] Screen titles in Arabic
- [ ] Button labels in Arabic
- [ ] Proper Arabic typography
- [ ] No mixed LTR/RTL issues
- [ ] Numbers display correctly
- [ ] User messages align correctly in RTL
- [ ] AI messages align correctly in RTL
- [ ] Icons mirror properly in RTL

### Language Switching
- [ ] Can switch between languages
- [ ] UI updates immediately (recreate activity or live update)
- [ ] Preference persists
- [ ] No crashes when switching
- [ ] Layout adapts correctly
- [ ] `LocaleListCompat` applied correctly

---

## 🎨 Visual Testing

### Light Theme
- [ ] All screens look good in light theme
- [ ] Proper contrast ratios (WCAG AA)
- [ ] Colors match Material Design 3 light scheme
- [ ] No white-on-white text
- [ ] Images/icons visible
- [ ] Emerald/teal colors prominent

### Dark Theme
- [ ] All screens look good in dark theme
- [ ] Proper contrast ratios
- [ ] Colors match Material Design 3 dark scheme
- [ ] Dark backgrounds are #0f0f0f and #171717 (per theming guide)
- [ ] No black-on-black text
- [ ] Images/icons visible
- [ ] Automatic theme switching works
- [ ] Respects system theme preference

### Different Devices
Test on multiple emulators/devices:
- [ ] Small phone (5" - 1080p)
- [ ] Standard phone (6.1" - 1080p)
- [ ] Large phone (6.7" - 1440p)
- [ ] Foldable (if applicable)
- [ ] Tablet 7" (if supporting tablets)
- [ ] Tablet 10" (if supporting tablets)

---

## ♿ Accessibility Testing

### TalkBack
- [ ] Enable TalkBack
- [ ] All interactive elements have contentDescription
- [ ] Navigation works with TalkBack
- [ ] Message content readable
- [ ] Input field accessible
- [ ] Buttons describable
- [ ] Proper focus order
- [ ] Semantic properties set correctly

### Font Scaling
- [ ] Text scales with system font size settings
- [ ] UI doesn't break at largest font size (200%)
- [ ] Minimum font size readable
- [ ] Labels don't truncate inappropriately
- [ ] Use `sp` units for text sizes

### Color & Contrast
- [ ] Sufficient contrast ratios (WCAG AA: 4.5:1 for normal text)
- [ ] Color not sole indicator of information
- [ ] Emerald (#10B981) provides sufficient contrast on dark backgrounds

### Touch Targets
- [ ] All interactive elements minimum 48dp
- [ ] Proper spacing between tappable areas
- [ ] Works well with motor impairments

---

## 📱 Device Testing (If Available)

### Physical Device
- [ ] Install on real Android phone/tablet
- [ ] All features work on device
- [ ] Performance acceptable
- [ ] Camera works (for OCR)
- [ ] Microphone works (for voice)
- [ ] Mobile data works
- [ ] WiFi works
- [ ] Airplane mode handled
- [ ] Battery usage reasonable

### Different Android Versions
- [ ] Android 8.0 (API 26) - minimum version
- [ ] Android 10 (API 29)
- [ ] Android 12 (API 31) - Splash Screen API, Material You
- [ ] Android 14 (API 34) - latest

### Different Manufacturers
- [ ] Samsung (One UI)
- [ ] Google Pixel (stock Android)
- [ ] Xiaomi (MIUI)
- [ ] OnePlus (OxygenOS)

---

## 🔒 Security & Privacy Testing

### Permissions
- [ ] Camera permission requested correctly
- [ ] Microphone permission requested correctly
- [ ] Read external storage permission requested (API < 33)
- [ ] Read media images permission requested (API 33+)
- [ ] Proper permission rationale shown
- [ ] Handles permission denial gracefully
- [ ] Permission descriptions in AndroidManifest.xml clear

### Data Privacy
- [ ] No sensitive data logged to Logcat
- [ ] API calls use HTTPS only (network_security_config.xml)
- [ ] User data stored securely (EncryptedSharedPreferences if needed)
- [ ] No data leaks in error messages
- [ ] Room database encrypted (if needed)

---

## 🐛 Edge Cases & Stress Testing

### Edge Cases
- [ ] Empty conversation list
- [ ] Very long message (> 1000 chars)
- [ ] Very long conversation (> 100 messages)
- [ ] Special characters in message
- [ ] Emoji in message
- [ ] Arabic + English mixed message
- [ ] Message with only spaces
- [ ] Rapid message sending
- [ ] App backgrounding during API call
- [ ] App process killed during API call
- [ ] Low storage space
- [ ] No storage permission

### Stress Testing
- [ ] 100+ conversations
- [ ] 1000+ messages total
- [ ] Large images for OCR
- [ ] Long voice recordings
- [ ] Slow network simulation
- [ ] Interrupted network simulation
- [ ] Low memory handling
- [ ] Battery saver mode
- [ ] Data saver mode
- [ ] Doze mode behavior

---

## 🚨 Critical Path Testing

### Happy Path: New User
1. [ ] Install app
2. [ ] See welcome screen
3. [ ] Tap "Get Started"
4. [ ] Land on chat screen
5. [ ] Type a question
6. [ ] Receive answer
7. [ ] See sources
8. [ ] Navigate to history
9. [ ] Resume conversation
10. [ ] Success! ✅

### Happy Path: Returning User
1. [ ] Launch app
2. [ ] Land on last conversation or new chat
3. [ ] Continue conversation
4. [ ] Switch to history via bottom nav
5. [ ] Open previous conversation
6. [ ] Send new message
7. [ ] Success! ✅

---

## 📊 Testing Completion Checklist

- [ ] All Phase 1 tests passed
- [ ] All Phase 2 tests passed
- [ ] All Phase 3 tests passed
- [ ] All Phase 4 tests passed
- [ ] All Phase 5 tests passed
- [ ] All Phase 6 tests passed
- [ ] All Phase 7 tests passed
- [ ] All Phase 8 tests passed
- [ ] All Phase 9 tests passed
- [ ] All Phase 10 tests passed
- [ ] Visual testing complete (light/dark themes)
- [ ] Accessibility testing complete
- [ ] Device testing complete (if applicable)
- [ ] Security testing complete
- [ ] Edge cases tested
- [ ] Critical paths verified
- [ ] APK builds successfully
- [ ] Release build tested

---

## 🔧 Android-Specific Tests

### Compose Testing
- [ ] Compose UI tests pass
- [ ] `@Preview` functions render correctly
- [ ] Semantics properties set for testing
- [ ] `composeTestRule` tests all pass

### Configuration Changes
- [ ] Rotation works (portrait ↔ landscape)
- [ ] UI state preserved on rotation
- [ ] No crashes on rotation
- [ ] Multi-window mode works (Android 7+)
- [ ] Picture-in-Picture mode (if applicable)

### App Lifecycle
- [ ] App handles `onPause` correctly
- [ ] App handles `onResume` correctly
- [ ] App handles `onStop` correctly
- [ ] App handles process death/recreation
- [ ] SavedStateHandle preserves UI state
- [ ] ViewModel survives configuration changes

### Gradle & Build
- [ ] Clean build succeeds
- [ ] `./gradlew assembleDebug` succeeds
- [ ] `./gradlew assembleRelease` succeeds
- [ ] ProGuard/R8 doesn't break app
- [ ] APK size reasonable (< 50MB ideally)
- [ ] App bundle (.aab) builds correctly

---

## ✅ **App is Ready for Production When ALL Boxes Checked!**

---

## 📝 Notes Section

Use this space to track issues found during testing:

```
Issue #1:
- Description:
- Steps to reproduce:
- Expected behavior:
- Actual behavior:
- Device/Android version:
- Status: [ ] Open / [ ] Fixed / [ ] Won't Fix

Issue #2:
...
```

---

*Test thoroughly, ship confidently! 🚀*
