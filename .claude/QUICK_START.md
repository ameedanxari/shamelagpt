# Quick Start Guide for Claude Code

> **TL;DR**: This is a dual-platform project (Android + iOS). Always apply changes to BOTH apps. Always search for existing code before creating new code.

## 🚨 Critical Rules

1. **BOTH PLATFORMS**: Unless explicitly stated, all features/fixes go to both Android AND iOS
2. **SEARCH FIRST**: Before creating anything, search for existing implementations
3. **REUSE CODE**: Extend existing classes, don't duplicate
4. **FOLLOW MVVM**: Maintain the architectural pattern
5. **TEST BOTH**: Verify changes work on both platforms

## 📚 Documentation Files

### Primary Reference
- **[cross-platform-instructions.md](./cross-platform-instructions.md)** - Comprehensive guide for maintaining both platforms
  - Platform equivalents (Kotlin ↔ Swift, Compose ↔ SwiftUI)
  - Architecture patterns
  - Best practices and anti-patterns
  - Common pitfalls

### Implementation Help
- **[IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)** - Decision trees and real examples
  - "Should I create a new file?" decision tree
  - "Where does this code belong?" decision tree
  - Real-world examples (good vs bad)
  - Common scenarios and solutions

### Feature Tracking
- **[FEATURE_CHECKLIST.md](./FEATURE_CHECKLIST.md)** - Template for implementing features
  - Pre-implementation checks
  - Android implementation steps
  - iOS implementation steps
  - Cross-platform validation
  - Testing checklist

## ⚡ Quick Decision Guide

### "I need to implement [something]"

```
1. STOP and SEARCH
   → Grep for: class names, similar features, keywords
   → Check: ViewModels, Services, UI components

2. FOUND something similar?
   YES → Extend/modify existing code
   NO  → Create new, but check examples first

3. Which layer?
   - UI rendering → View/Composable
   - Business logic → ViewModel
   - API calls → Service/Repository
   - Data structure → Model

4. Both platforms?
   YES (default) → Implement in Android + iOS
   NO → Confirm with user first

5. VERIFY
   → Follows MVVM pattern?
   → No code duplication?
   → Matches existing style?
```

## 🔍 Essential Search Patterns

### Find ViewModels
```bash
# Android
Grep pattern: "class.*ViewModel" glob: "*.kt"

# iOS
Grep pattern: "class.*ViewModel.*ObservableObject" glob: "*.swift"
```

### Find API Services
```bash
# Android
Grep pattern: "suspend fun.*:" glob: "*Service*.kt"

# iOS
Grep pattern: "func.*async throws" glob: "*Service*.swift"
```

### Find UI Screens
```bash
# Android
Grep pattern: "@Composable.*Screen" glob: "*.kt"

# iOS
Grep pattern: "struct.*View:" glob: "Views/*.swift"
```

### Find Similar Features
```bash
# Use keywords from the feature
Grep pattern: "search|filter|favorite" -i glob: "*.kt"
Grep pattern: "search|filter|favorite" -i glob: "*.swift"
```

## 📁 Project Structure

### Android: `/shamelagpt-android`
```
app/src/main/java/com/shamelagpt/
├── ui/screens/          # Composable screens
├── ui/components/       # Reusable UI components
├── viewmodel/           # ViewModels (business logic)
├── model/              # Data classes
├── network/            # API service
└── repository/         # Data layer (if exists)
```

### iOS: `/shamelagpt-ios`
```
shamelagpt/
├── Views/              # SwiftUI views
├── ViewModels/         # ObservableObject classes
├── Models/             # Codable structures
└── Services/           # API and business services
```

## ✅ Before You Code Checklist

- [ ] Read the relevant section in [cross-platform-instructions.md](./cross-platform-instructions.md)
- [ ] Searched for existing implementations
- [ ] Identified what can be reused
- [ ] Determined correct architectural layer
- [ ] Confirmed if both platforms need changes
- [ ] Reviewed similar code for patterns

## 🎯 Common Tasks

### Adding a New Feature
1. Search for similar features
2. Plan implementation for both platforms
3. Implement in Android (follow existing patterns)
4. Implement in iOS (equivalent implementation)
5. Test both platforms
6. Verify UI/UX consistency

### Fixing a Bug
1. Identify if bug exists in both platforms
2. Find the relevant code (ViewModel/Service/View)
3. Fix in Android
4. Apply equivalent fix in iOS
5. Test both platforms

### Adding an API Endpoint
1. Check existing API service class
2. Add method to existing service (don't create new service)
3. Update both Android and iOS services
4. Update data models if needed (both platforms)
5. Test API calls on both platforms

### Creating a UI Component
1. Search for similar components
2. Check if you can reuse/extend existing component
3. If new component needed, create in both platforms:
   - Android: `@Composable` function
   - iOS: `struct` conforming to `View`
4. Make it reusable with parameters
5. Use consistent styling (colors, fonts, spacing)

## 🚫 What NOT to Do

- ❌ Create new ViewModels without checking for existing ones
- ❌ Duplicate API service methods
- ❌ Make API calls directly in UI components
- ❌ Break MVVM pattern (business logic in Views)
- ❌ Implement feature in only one platform
- ❌ Use different colors/styles between platforms
- ❌ Create new files without searching for existing code
- ❌ Ignore existing naming conventions

## 💡 Pro Tips

1. **Use the Task tool with Explore agent** for complex searches
2. **Read similar implementations** to understand patterns
3. **Copy the structure** of existing features
4. **Keep ViewModels thin** - delegate to services/repositories
5. **Make UI components reusable** - use parameters
6. **Centralize common logic** - use base classes or extensions
7. **Test as you go** - don't wait until the end
8. **When in doubt, ask** - clarify before implementing

## 🔗 Quick Links

- [Comprehensive Best Practices](./cross-platform-instructions.md)
- [Implementation Examples & Decision Trees](./IMPLEMENTATION_GUIDE.md)
- [Feature Implementation Checklist](./FEATURE_CHECKLIST.md)
- [Android Project](../shamelagpt-android/)
- [iOS Project](../shamelagpt-ios/)

## 📞 Need Help?

1. **Search the codebase** - Use Grep to find examples
2. **Check the docs** - Review the reference files in `.claude/`
3. **Ask for clarification** - If requirements are unclear
4. **Study existing code** - Copy proven patterns

---

**Remember**: This is ONE project with TWO platforms. Search, Reuse, Maintain patterns, Apply to both!
