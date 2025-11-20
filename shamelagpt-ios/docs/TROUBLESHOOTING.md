# ShamelaGPT iOS - Troubleshooting Guide

## Version: 1.0
## Target: iOS 15.0+

---

## 🔧 Common Issues & Solutions

---

## 📦 Project Setup Issues

### Issue: "Package.resolved" conflicts
**Error**: Git conflicts in Package.resolved file

**Solution**:
```bash
# Delete Package.resolved
rm -rf ShamelaGPT.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# In Xcode: File → Packages → Reset Package Caches
# Then: File → Packages → Resolve Package Versions
```

### Issue: SPM packages not resolving
**Error**: "Failed to resolve dependencies"

**Solution**:
1. Check internet connection
2. File → Packages → Reset Package Caches
3. Clean build folder (Shift + Cmd + K)
4. Restart Xcode
5. Try again

### Issue: Build fails with "Command PhaseScriptExecution failed"
**Error**: Script phase errors

**Solution**:
- Check all build phase scripts
- Ensure scripts have proper permissions
- Verify script paths are correct
- Remove unnecessary scripts

---

## 💾 Core Data Issues

### Issue: "Model file not found"
**Error**: Core Data model (.xcdatamodeld) not loading

**Solution**:
1. Verify file is in project navigator
2. Check file is included in target membership
3. Ensure correct bundle identifier
4. Clean and rebuild

### Issue: Core Data migration errors
**Error**: "The model used to open the store is incompatible"

**Solution**:
```swift
// Add this to Core Data stack
container.loadPersistentStores { description, error in
    if let error = error {
        // For development, delete and recreate
        try? FileManager.default.removeItem(at: storeURL)
        container.loadPersistentStores { _, _ in }
    }
}
```

**Warning**: This deletes all data. For production, implement proper migrations.

### Issue: Core Data crashes on background thread
**Error**: "NSManagedObjectContext concurrency violation"

**Solution**:
```swift
// Always use perform/performAndWait
context.perform {
    // Core Data operations here
}
```

---

## 🌐 Networking Issues

### Issue: API call returns 500 error
**Error**: "Internal Server Error"

**Context**: Conversation management endpoints don't work yet

**Solution**:
- Only use `/api/chat` endpoint
- Store conversations locally in Core Data
- Don't try to create/fetch conversations from API
- Wait for API to be fixed

### Issue: "The resource could not be loaded"
**Error**: Network request failed

**Solution**:
1. Check internet connection
2. Verify API URL is correct: `https://api.shamelagpt.com`
3. Check Info.plist allows arbitrary loads (development only)
4. Test API with curl:
```bash
curl https://api.shamelagpt.com/api/health
```

### Issue: Response parsing fails
**Error**: "The data couldn't be read because it isn't in the correct format"

**Solution**:
1. Print raw response data:
```swift
if let json = try? JSONSerialization.jsonObject(with: data) {
    print("Response:", json)
}
```
2. Verify Codable models match API response
3. Check for snake_case vs camelCase issues
4. Add proper `CodingKeys`

---

## 🎤 Voice Input Issues

### Issue: "Speech recognition unavailable"
**Error**: SFSpeechRecognizer returns nil

**Solution**:
1. Check device supports speech recognition
2. Verify locale is supported:
```swift
let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
if recognizer == nil {
    // Locale not supported
}
```
3. Try different locale
4. Check device settings → Siri & Search → Language

### Issue: Permission denied for microphone
**Error**: User denied microphone access

**Solution**:
1. Check Info.plist has `NSMicrophoneUsageDescription`
2. Prompt user to enable in Settings:
```swift
if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
    UIApplication.shared.open(settingsURL)
}
```

---

## 📷 Image/OCR Issues

### Issue: Vision framework not recognizing text
**Error**: OCR returns empty or incorrect text

**Solution**:
1. Ensure image quality is good (not blurry)
2. Try different recognition levels:
```swift
request.recognitionLevel = .accurate // vs .fast
```
3. Specify languages:
```swift
request.recognitionLanguages = ["en-US", "ar-SA"]
```
4. Check image orientation

### Issue: Camera permission denied
**Error**: Can't access camera

**Solution**:
1. Check Info.plist has `NSCameraUsageDescription`
2. Request permission before accessing:
```swift
AVCaptureDevice.requestAccess(for: .video) { granted in
    // Handle result
}
```

---

## 🎨 UI/UX Issues

### Issue: SwiftUI preview not working
**Error**: "Cannot preview in this file"

**Solution**:
1. Check all dependencies injected in preview
2. Use mock data/services in preview:
```swift
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(viewModel: MockChatViewModel())
    }
}
```
3. Clean build folder
4. Restart Xcode

### Issue: RTL layout not working
**Error**: Arabic text displays left-to-right

**Solution**:
1. Use `.leading` and `.trailing` instead of `.left`/`.right`
2. Set environment:
```swift
.environment(\.layoutDirection, .rightToLeft)
```
3. Test with Arabic language in simulator

### Issue: Dark mode colors wrong
**Error**: Poor contrast in dark mode

**Solution**:
Use semantic colors:
```swift
// ✅ Good
Color(uiColor: .systemBackground)
Color(uiColor: .label)

// ❌ Bad
Color.white
Color.black
```

---

## 📱 Navigation Issues

### Issue: Navigation stack crashes
**Error**: "Tried to pop to a view controller that doesn't exist"

**Solution**:
1. Verify navigation path is valid
2. Don't manually modify navigation stack
3. Use coordinator pattern properly
4. Check for retain cycles in coordinator

### Issue: Tab bar not showing
**Error**: Bottom tab bar missing

**Solution**:
1. Verify `TabView` is root view
2. Check `.tabItem` modifiers on all tabs
3. Ensure tab selection binding works
4. Try rebuilding project

---

## 🧪 Testing Issues

### Issue: Unit tests failing
**Error**: Various test failures

**Solution**:
1. Check test target has access to app code
2. Verify `@testable import ShamelaGPT`
3. Mock dependencies properly
4. Use `XCTUnwrap` for optionals
5. Add proper test data

### Issue: UI tests timing out
**Error**: "Failed to find element"

**Solution**:
1. Increase timeout:
```swift
element.waitForExistence(timeout: 10)
```
2. Add accessibility identifiers
3. Use `XCTAssert` properly
4. Check element hierarchy

---

## ⚡ Performance Issues

### Issue: Slow scrolling in message list
**Error**: LazyVStack laggy

**Solution**:
1. Use `LazyVStack` instead of `VStack`
2. Limit rendered messages (pagination)
3. Optimize message view:
```swift
// Add .id() for better diffing
MessageView(message: message)
    .id(message.id)
```
4. Profile with Instruments

### Issue: High memory usage
**Error**: App using > 200MB RAM

**Solution**:
1. Check for retain cycles
2. Clear message cache periodically
3. Use `weak self` in closures
4. Profile with Instruments Memory tool

### Issue: Slow app launch
**Error**: Takes > 5 seconds to launch

**Solution**:
1. Move heavy work off main thread
2. Lazy load dependencies
3. Optimize Core Data initial fetch
4. Use splash screen while loading

---

## 🔐 Security Issues

### Issue: SSL certificate error
**Error**: "The certificate for this server is invalid"

**Solution**:
1. Check API uses valid HTTPS certificate
2. Don't disable SSL validation in production
3. For development only:
```swift
// Don't use in production!
let session = URLSession(configuration: .ephemeral)
```

---

## 🌍 Localization Issues

### Issue: Strings not translating
**Error**: Text still in English when Arabic selected

**Solution**:
1. Verify `ar.lproj/Localizable.strings` exists
2. Check string keys match exactly
3. Use `NSLocalizedString`:
```swift
Text(NSLocalizedString("key", comment: ""))
// Or with String Catalog:
Text("key", bundle: .main)
```
4. Clean build folder

### Issue: String interpolation not working
**Error**: Localized string with variables not working

**Solution**:
```swift
// Use String(format:)
String(format: NSLocalizedString("greeting_%@", comment: ""), name)
```

---

## 🐛 Crash Issues

### Issue: App crashes on launch
**Error**: EXC_BAD_ACCESS or similar

**Solution**:
1. Check crash log in Xcode → Window → Organizer
2. Enable exception breakpoint
3. Check for force unwrapping:
```swift
// ❌ Bad
let value = optional!

// ✅ Good
guard let value = optional else { return }
```
4. Verify all outlets connected in storyboards (if using)

### Issue: Crash when accessing Combine publisher
**Error**: "Fatal error: Unexpectedly found nil"

**Solution**:
1. Store cancellables:
```swift
var cancellables = Set<AnyCancellable>()

publisher
    .sink { _ in }
    .store(in: &cancellables)
```
2. Don't let AnyCancellable be deallocated

---

## 🔄 Dependency Injection Issues

### Issue: Swinject can't resolve dependency
**Error**: "Fatal error: Unexpectedly found nil while unwrapping"

**Solution**:
1. Verify dependency registered:
```swift
container.register(ChatRepository.self) { resolver in
    ChatRepositoryImpl(...)
}
```
2. Check registration happens before resolution
3. Verify correct type being resolved
4. Check for circular dependencies

---

## 📊 Build & Archive Issues

### Issue: Archive fails with code signing error
**Error**: "Code signing error"

**Solution**:
1. Select correct team in Signing & Capabilities
2. Verify provisioning profile
3. Check bundle identifier matches
4. Try automatic signing first

### Issue: "Symbols not found" linker error
**Error**: Undefined symbol errors

**Solution**:
1. Clean build folder (Shift + Cmd + K)
2. Delete Derived Data:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```
3. Restart Xcode
4. Check all frameworks linked properly

---

## 🆘 When All Else Fails

### Nuclear Option: Complete Clean

```bash
# 1. Close Xcode

# 2. Clean everything
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ShamelaGPT.xcodeproj/project.xcworkspace/xcshareddata/swiftpm

# 3. Delete Package.resolved
rm -rf ShamelaGPT.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# 4. Restart Mac

# 5. Open Xcode
# 6. File → Packages → Reset Package Caches
# 7. Clean Build Folder (Shift + Cmd + K)
# 8. Build (Cmd + B)
```

---

## 📞 Getting More Help

### Resources
1. **Apple Developer Forums**: https://developer.apple.com/forums/
2. **Stack Overflow**: Tag questions with `ios`, `swift`, `swiftui`
3. **Swift Forums**: https://forums.swift.org/
4. **Ray Wenderlich**: https://www.kodeco.com/
5. **Hacking with Swift**: https://www.hackingwithswift.com/

### Debug Logging

Add comprehensive logging:

```swift
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let network = OSLog(subsystem: subsystem, category: "network")
    static let database = OSLog(subsystem: subsystem, category: "database")
    static let ui = OSLog(subsystem: subsystem, category: "ui")
}

// Usage
os_log("API call failed: %@", log: .network, type: .error, error.localizedDescription)
```

### Debugging Tips

1. **Enable Exception Breakpoint**:
   - Breakpoint Navigator → + → Exception Breakpoint

2. **Print View Hierarchy**:
```swift
po UIApplication.shared.windows.first?.rootViewController
```

3. **Check Memory Graph**:
   - Run app → Debug Memory Graph (icon in debug bar)

4. **Use Instruments**:
   - Profile → Instruments → Choose tool (Leaks, Time Profiler, etc.)

---

## 📝 Reporting Bugs

When reporting issues, include:

1. **Xcode Version**: (e.g., 15.2)
2. **iOS Version**: (e.g., iOS 17.2)
3. **Device**: (e.g., iPhone 15 Pro Simulator)
4. **Steps to Reproduce**: Clear numbered steps
5. **Expected Behavior**: What should happen
6. **Actual Behavior**: What actually happens
7. **Error Message**: Full error text
8. **Code**: Minimal reproducible example
9. **Screenshots**: If UI-related

---

*Remember: Every bug is an opportunity to learn! 🐛→🦋*
