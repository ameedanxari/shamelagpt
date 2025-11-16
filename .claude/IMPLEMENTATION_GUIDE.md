# Implementation Guide: Decision Trees & Real Examples

This guide provides decision trees and real-world examples for common implementation scenarios in the ShamelaGPT dual-platform project.

## Decision Tree: Should I Create a New File?

```
START: I need to implement [feature/fix]
│
├─ Does similar functionality exist?
│  │
│  ├─ YES → Can I extend/modify existing code?
│  │  │
│  │  ├─ YES → ✅ EXTEND existing file
│  │  │         - Add method to existing ViewModel
│  │  │         - Add function to existing Service
│  │  │         - Extend existing UI component
│  │  │
│  │  └─ NO → Is it in the same domain/feature?
│  │     │
│  │     ├─ YES → ✅ ADD to existing file
│  │     │         - Keep related code together
│  │     │
│  │     └─ NO → ✅ CREATE new file
│  │               - Follow existing naming conventions
│  │               - Match directory structure
│  │
│  └─ NO → Is this a completely new feature area?
│     │
│     ├─ YES → ✅ CREATE new files
│     │         - Model + ViewModel + View + Service
│     │         - Follow MVVM pattern
│     │         - Create equivalent on both platforms
│     │
│     └─ UNSURE → 🔍 SEARCH AGAIN more thoroughly
│                   - Use different search terms
│                   - Check related features
│                   - Review architecture docs
```

## Decision Tree: Where Does This Code Belong?

```
I need to add code that [does something]
│
├─ Does it fetch/send data to API?
│  └─ YES → 📁 Service/Repository Layer
│            Android: network/ or repository/
│            iOS: Services/
│
├─ Does it manage state or business logic?
│  └─ YES → 📁 ViewModel Layer
│            Android: viewmodel/
│            iOS: ViewModels/
│
├─ Does it define data structure?
│  └─ YES → 📁 Model Layer
│            Android: model/
│            iOS: Models/
│
├─ Does it render UI or handle user interaction?
│  └─ YES → 📁 View Layer
│            Android: ui/screens/ or ui/components/
│            iOS: Views/
│
└─ Is it a utility/helper function?
   └─ YES → 📁 Utils/Helpers
            Android: utils/
            iOS: Utilities/ or Extensions/
```

## Real-World Implementation Examples

### Example 1: Adding Book Favoriting Feature

#### ❌ WRONG Approach
```kotlin
// Android - Creating entirely new files

// NEW FILE: FavoriteViewModel.kt
class FavoriteViewModel : ViewModel() {
    suspend fun addToFavorites(bookId: String) { /* ... */ }
}

// NEW FILE: FavoriteApiService.kt
class FavoriteApiService {
    suspend fun favoriteBook(bookId: String) { /* ... */ }
}
```

**Problems:**
- Duplicates existing book management logic
- Creates scattered code
- Harder to maintain

#### ✅ CORRECT Approach
```kotlin
// Android - Extend existing files

// EXISTING FILE: BookViewModel.kt
class BookViewModel : ViewModel() {
    // ... existing book logic ...

    // ADD new method to existing ViewModel
    fun toggleFavorite(bookId: String) {
        viewModelScope.launch {
            repository.toggleFavorite(bookId)
        }
    }
}

// EXISTING FILE: ShamelaApiService.kt
class ShamelaApiService {
    // ... existing methods ...

    // ADD new endpoint to existing service
    suspend fun toggleBookFavorite(bookId: String): Result<Boolean>
}
```

**Benefits:**
- Keeps related code together
- Reuses existing infrastructure
- Easier to maintain and test

### Example 2: Adding a Search Filter

#### Discovery Phase
```bash
# 1. Search for existing search functionality
Grep pattern: "search" -i glob: "*.kt"

# 2. Found: SearchViewModel.kt exists!
# Read it to understand the pattern

# 3. Check what filters already exist
Grep pattern: "filter" -i glob: "*.kt"
```

#### Implementation
```kotlin
// EXISTING FILE: SearchViewModel.kt
class SearchViewModel : ViewModel() {
    // Existing code
    private val _searchQuery = MutableStateFlow("")
    private val _results = MutableStateFlow<List<Book>>(emptyList())

    // ADD new filter functionality to existing ViewModel
    private val _selectedCategory = MutableStateFlow<Category?>(null)

    fun applyFilter(category: Category) {
        _selectedCategory.value = category
        performSearch() // Reuse existing search method
    }

    private fun performSearch() {
        // Enhanced existing method to include filter
        viewModelScope.launch {
            val results = repository.search(
                query = _searchQuery.value,
                category = _selectedCategory.value
            )
            _results.value = results
        }
    }
}
```

### Example 3: Creating a New Settings Screen

#### When to Create New Files
This is a NEW feature area (Settings), so new files are justified.

#### Android Structure
```
app/src/main/java/com/shamelagpt/
├── ui/screens/
│   └── settings/
│       ├── SettingsScreen.kt          ✅ NEW (UI)
│       └── components/
│           └── SettingItem.kt         ✅ NEW (Reusable component)
├── viewmodel/
│   └── SettingsViewModel.kt           ✅ NEW (Business logic)
└── model/
    └── UserSettings.kt                ✅ NEW (Data model)
```

#### iOS Equivalent Structure
```
shamelagpt/
├── Views/
│   └── Settings/
│       ├── SettingsView.swift         ✅ NEW (UI)
│       └── Components/
│           └── SettingItem.swift      ✅ NEW (Reusable)
├── ViewModels/
│   └── SettingsViewModel.swift        ✅ NEW (Business logic)
└── Models/
    └── UserSettings.swift             ✅ NEW (Data model)
```

**Why new files are OK here:**
- Completely new feature area
- No existing settings management
- Creates reusable components for future settings

### Example 4: Adding Error Handling

#### ❌ WRONG: Creating new error handling
```kotlin
// NEW FILE: ErrorHandler.kt
class ErrorHandler {
    fun handleError(error: Exception) { /* ... */ }
}
```

#### ✅ CORRECT: Check for existing error handling first
```bash
# Search for existing error handling
Grep pattern: "error|exception" -i glob: "*.kt"

# Found: BaseViewModel.kt has error handling!
```

```kotlin
// EXISTING FILE: BaseViewModel.kt
open class BaseViewModel : ViewModel() {
    protected val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error

    protected fun handleError(exception: Exception) {
        _error.value = exception.message
    }
}

// YOUR NEW ViewModel - REUSE the base class
class MyNewViewModel : BaseViewModel() {
    fun doSomething() {
        viewModelScope.launch {
            try {
                // ... operation ...
            } catch (e: Exception) {
                handleError(e) // ✅ Reuse base functionality
            }
        }
    }
}
```

## Common Scenarios & Solutions

### Scenario: "I need to add a loading indicator"

**Before creating new code:**
```bash
# Search for existing loading state management
Grep pattern: "loading|isLoading" -i glob: "*.kt"
```

**Likely find:**
```kotlin
// Existing pattern in BaseViewModel or other ViewModels
private val _isLoading = MutableStateFlow(false)
val isLoading: StateFlow<Boolean> = _isLoading
```

**Solution:** Reuse the existing pattern!

### Scenario: "I need to make a new API call"

**Decision tree:**
1. Does the endpoint fit in an existing Service? → Add method to existing service
2. Is it a completely different API domain? → Create new service (and equivalent in iOS)

**Example:**
```kotlin
// If adding book-related endpoint:
// ✅ ADD to existing ShamelaApiService

// If integrating with a new external API (e.g., translation service):
// ✅ CREATE new TranslationApiService
```

### Scenario: "I need to show a dialog/modal"

**Before creating:**
```bash
# Search for existing dialogs
Grep pattern: "Dialog|AlertDialog|Sheet" glob: "*.kt"
Grep pattern: "Alert|Sheet" glob: "*.swift"
```

**Check if:**
- Generic dialog component exists → Reuse it
- Similar dialog exists → Copy pattern
- No dialog infrastructure → Create reusable dialog component

### Scenario: "I need to format a date/string"

**Before creating utility:**
```bash
# Search for existing utilities
Grep pattern: "extension String|fun String" glob: "*.kt"
Grep pattern: "extension String" glob: "*.swift"
```

**Likely find existing extensions/utilities:**
```kotlin
// Android - Existing extensions
fun String.toFormattedDate(): String { /* ... */ }

// ADD your new extension to same file
fun String.toReadableTime(): String { /* ... */ }
```

## Implementation Workflow Template

### For ANY new feature/fix:

```markdown
## Feature: [Name]

### 1. Discovery Phase
- [ ] Searched for similar implementations
  - Search terms used: _______________
  - Files found: _______________
- [ ] Identified existing patterns
  - Pattern: _______________
  - Location: _______________
- [ ] Determined reusability
  - Can reuse: _______________
  - Must create: _______________

### 2. Planning Phase
- [ ] Decided on approach:
  - [ ] Extend existing code
  - [ ] Create new code (justified because: _______________)
- [ ] Identified files to modify/create:
  - Android: _______________
  - iOS: _______________
- [ ] Verified architecture layer is correct:
  - Layer: _______________ (View/ViewModel/Service/Model)

### 3. Implementation Phase
- [ ] Android implementation complete
- [ ] iOS implementation complete
- [ ] Both follow existing patterns
- [ ] No code duplication
- [ ] Tested on both platforms

### 4. Review Phase
- [ ] Code follows MVVM
- [ ] Reused existing components
- [ ] Maintained consistency
- [ ] No anti-patterns introduced
```

## Quick Reference: When to Reuse vs. Create

| Scenario | Reuse | Create New |
|----------|-------|------------|
| Similar ViewModel exists | ✅ Extend it | ❌ |
| Related API endpoint | ✅ Add to existing service | ❌ |
| UI component exists | ✅ Reuse it | ❌ |
| Completely new feature domain | ❌ | ✅ Both platforms |
| Utility function exists | ✅ Use it | ❌ |
| Different architectural layer needed | N/A | ✅ Follow pattern |
| Existing code does 80% of what you need | ✅ Extend it | ❌ |
| Existing code unrelated | ❌ | ✅ Create similar structure |

## Remember

1. **Always search first** - Use Grep liberally
2. **Study before coding** - Read similar implementations
3. **Reuse when possible** - Don't reinvent the wheel
4. **Match patterns** - Consistency is key
5. **Both platforms** - Android + iOS always
6. **MVVM always** - Never break the architecture

---

**The Golden Rule**: If in doubt, search for it. It probably already exists!
