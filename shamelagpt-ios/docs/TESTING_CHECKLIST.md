# ShamelaGPT iOS - Testing Checklist

## Version: 1.0
## Target: iOS 15.0+

---

## 📋 Overview

Use this comprehensive checklist to validate that your ShamelaGPT iOS app meets all requirements and works correctly across different scenarios.

---

## ✅ Phase 1: Project Setup Testing

### Build & Configuration
- [ ] Project builds without errors (Cmd + B)
- [ ] Project builds without warnings
- [ ] App launches on iOS Simulator
- [ ] App launches on physical device (if available)
- [ ] App icon displays correctly
- [ ] Launch screen shows properly
- [ ] App name is "ShamelaGPT"

### Dependencies
- [ ] All Swift Package dependencies resolved
- [ ] Swinject dependency injection working
- [ ] No duplicate dependencies
- [ ] Build configuration correct (Debug/Release)

---

## ✅ Phase 2: Data Layer Testing

### Core Data
- [ ] Database initializes successfully
- [ ] Can create Conversation entities
- [ ] Can create Message entities
- [ ] Can save data to Core Data
- [ ] Can fetch data from Core Data
- [ ] Can update entities
- [ ] Can delete entities
- [ ] Relationships work (Conversation ↔ Messages)
- [ ] App doesn't crash on invalid data

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
- [ ] Network timeout handled gracefully

### Offline Support
- [ ] App works without internet connection
- [ ] Messages queued when offline
- [ ] Shows "No internet" indicator when offline
- [ ] Syncs data when back online
- [ ] Cached data loads instantly

---

## ✅ Phase 4: Chat Feature Testing

### Message Display
- [ ] User messages show on right side
- [ ] AI messages show on left side
- [ ] Messages display in correct order
- [ ] Timestamps show below each message
- [ ] Long messages wrap correctly
- [ ] Markdown renders properly (bold, italic, lists)
- [ ] Code blocks display correctly
- [ ] Links are tappable
- [ ] Source citations display and are clickable

### Message Input
- [ ] Text field accepts input
- [ ] Send button disabled when empty
- [ ] Send button enabled when text entered
- [ ] Sending message clears input field
- [ ] Can send multiple messages in sequence
- [ ] Typing in text field updates UI

### Message Interaction
- [ ] Long press shows context menu
- [ ] Can copy message text
- [ ] Can share message
- [ ] Copied text includes sources
- [ ] Share sheet opens correctly

### Conversation Flow
- [ ] Can start new conversation
- [ ] thread_id persists across messages
- [ ] Conversation continues correctly
- [ ] Scroll to bottom works
- [ ] Auto-scroll on new message works

### Loading States
- [ ] Typing indicator shows while loading
- [ ] Typing indicator animates
- [ ] Loading indicator disappears when response received
- [ ] Can't send new message while loading

---

## ✅ Phase 5: Voice & Image Input Testing

### Voice Input
- [ ] Microphone button shows
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

### Image Input (OCR)
- [ ] Camera/Gallery button shows
- [ ] Permission prompt appears (first time)
- [ ] Can take new photo
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
- [ ] Pull to refresh works
- [ ] Tap conversation navigates to chat

### Conversation Management
- [ ] Can create new conversation
- [ ] Can resume existing conversation
- [ ] Conversation title auto-generated from first question
- [ ] Long titles truncate correctly
- [ ] Swipe to delete works
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

### Settings Screen
- [ ] Settings tab accessible
- [ ] All sections display
- [ ] Language option shows current language
- [ ] Can navigate to language selection
- [ ] Donation button opens PayPal in Safari
- [ ] About button works
- [ ] Privacy Policy button works
- [ ] Terms of Service button works
- [ ] Version number displays

### Language Selection
- [ ] Shows English option
- [ ] Shows Arabic option
- [ ] Can select language
- [ ] Selection persists
- [ ] App strings update immediately

---

## ✅ Phase 8: Navigation Testing

### Bottom Tab Bar
- [ ] Three tabs show (Chat, History, Settings)
- [ ] Correct icons for each tab
- [ ] Correct labels for each tab
- [ ] Tab selection works
- [ ] Active tab highlighted
- [ ] Tab state persists when switching
- [ ] Deep linking works (if implemented)

### Screen Navigation
- [ ] Can navigate between all screens
- [ ] Back button works on all screens
- [ ] Navigation animations smooth
- [ ] No navigation bugs or glitches
- [ ] Modal presentations work
- [ ] Dismissals work correctly

---

## ✅ Phase 9: Polish & Testing

### UI/UX
- [ ] All animations smooth
- [ ] No layout glitches
- [ ] Proper spacing and padding
- [ ] Colors match design system
- [ ] Typography consistent
- [ ] Buttons have proper tap targets (44x44pt min)
- [ ] Loading states for all async operations
- [ ] Error states for all failure scenarios
- [ ] Empty states for all empty data scenarios

### Performance
- [ ] App launches in < 3 seconds
- [ ] Scrolling is smooth (60 FPS)
- [ ] No memory leaks
- [ ] Memory usage reasonable (< 150MB)
- [ ] Battery usage acceptable
- [ ] No excessive network calls

### Error Handling
- [ ] Network errors shown to user
- [ ] API errors shown with helpful messages
- [ ] Database errors handled gracefully
- [ ] Permission errors shown clearly
- [ ] App doesn't crash on any error

---

## ✅ Phase 10: Localization Testing

### English (en)
- [ ] All strings localized
- [ ] No hardcoded English strings
- [ ] Proper grammar and spelling
- [ ] Text fits in UI elements
- [ ] Left-to-right layout correct

### Arabic (ar)
- [ ] All strings translated
- [ ] RTL layout working
- [ ] Text aligned correctly (right-aligned)
- [ ] Tab bar labels in Arabic
- [ ] Navigation titles in Arabic
- [ ] Button labels in Arabic
- [ ] Proper Arabic typography
- [ ] No mixed LTR/RTL issues
- [ ] Numbers display correctly
- [ ] User messages align right in RTL
- [ ] AI messages align left in RTL

### Language Switching
- [ ] Can switch between languages
- [ ] UI updates immediately
- [ ] Preference persists
- [ ] No crashes when switching
- [ ] Layout adapts correctly

---

## 🎨 Visual Testing

### Light Mode
- [ ] All screens look good in light mode
- [ ] Proper contrast ratios
- [ ] Colors match design system
- [ ] No white-on-white text
- [ ] Images/icons visible

### Dark Mode
- [ ] All screens look good in dark mode
- [ ] Proper contrast ratios
- [ ] Colors invert correctly
- [ ] No black-on-black text
- [ ] Images/icons visible
- [ ] Automatic theme switching works

### Different Devices
Test on multiple simulators:
- [ ] iPhone SE (3rd gen) - 4.7" small screen
- [ ] iPhone 14 - 6.1" standard
- [ ] iPhone 14 Pro Max - 6.7" large screen
- [ ] iPhone 15 Pro - Dynamic Island
- [ ] iPad (if supporting)

---

## ♿ Accessibility Testing

### VoiceOver
- [ ] Enable VoiceOver
- [ ] All interactive elements have labels
- [ ] Navigation works with VoiceOver
- [ ] Message content readable
- [ ] Input field accessible
- [ ] Buttons describable
- [ ] Proper reading order

### Dynamic Type
- [ ] Text scales with system settings
- [ ] UI doesn't break at largest text size
- [ ] Minimum font size readable
- [ ] Labels don't truncate inappropriately

### Color & Contrast
- [ ] Sufficient contrast ratios (WCAG AA)
- [ ] Works with Increase Contrast enabled
- [ ] Works with Reduce Transparency enabled
- [ ] Color not sole indicator

### Motion
- [ ] Works with Reduce Motion enabled
- [ ] Animations still provide feedback
- [ ] No motion sickness triggers

---

## 📱 Device Testing (If Available)

### Physical Device
- [ ] Install on real iPhone/iPad
- [ ] All features work on device
- [ ] Performance acceptable
- [ ] Camera works (for OCR)
- [ ] Microphone works (for voice)
- [ ] Cellular data works
- [ ] WiFi works
- [ ] Airplane mode handled

### Different iOS Versions
- [ ] iOS 15.0 (minimum)
- [ ] iOS 16.0
- [ ] iOS 17.0 (latest)

---

## 🔒 Security & Privacy Testing

### Permissions
- [ ] Camera permission requested correctly
- [ ] Microphone permission requested correctly
- [ ] Photo library permission requested correctly
- [ ] Proper permission descriptions in Info.plist
- [ ] Handles permission denial gracefully

### Data Privacy
- [ ] No sensitive data logged
- [ ] API calls use HTTPS only
- [ ] User data stored securely (Keychain if needed)
- [ ] No data leaks in error messages

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
- [ ] App termination during API call

### Stress Testing
- [ ] 100+ conversations
- [ ] 1000+ messages total
- [ ] Large images for OCR
- [ ] Long voice recordings
- [ ] Slow network simulation
- [ ] Interrupted network simulation
- [ ] Low memory warning handling
- [ ] Low battery mode

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
8. [ ] View history
9. [ ] Resume conversation
10. [ ] Success! ✅

### Happy Path: Returning User
1. [ ] Launch app
2. [ ] Land on last conversation or new chat
3. [ ] Continue conversation
4. [ ] Switch to history
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
- [ ] Visual testing complete
- [ ] Accessibility testing complete
- [ ] Device testing complete
- [ ] Security testing complete
- [ ] Edge cases tested
- [ ] Critical paths verified

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
- Status: [ ] Open / [ ] Fixed / [ ] Won't Fix

Issue #2:
...
```

---

*Test thoroughly, ship confidently! 🚀*
