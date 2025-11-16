# ShamelaGPT Cross-Platform Development Instructions

## Project Overview
This is a **dual-platform project** with both Android and iOS native applications:
- **Android**: `/shamelagpt-android` (Kotlin, Jetpack Compose)
- **iOS**: `/shamelagpt-ios` (Swift, SwiftUI)

## CRITICAL RULE: Always Apply Changes to BOTH Platforms

When implementing features, fixing bugs, or making any code changes, **YOU MUST apply the equivalent changes to BOTH Android and iOS apps** unless explicitly told otherwise.

### Cross-Platform Workflow

1. **Before starting any task**, determine if it affects:
   - UI/UX → Affects BOTH platforms
   - Features → Affects BOTH platforms
   - API integration → Affects BOTH platforms
   - Platform-specific code (Gradle/Podfile) → Single platform only
   - Build configurations → May affect both

2. **Implementation sequence**:
   - Implement the change in the FIRST platform
   - Immediately implement the equivalent in the SECOND platform
   - Test/verify both implementations
   - Document platform-specific differences if any

3. **Never assume** a change only affects one platform - always ask yourself: "Does this need to be in both apps?"

## Platform Equivalents Guide

### File Structure Mapping
| Component | Android | iOS |
|-----------|---------|-----|
| Main App | `app/src/main/java/com/shamelagpt/` | `shamelagpt/` |
| UI Screens | `ui/screens/` | `Views/` |
| ViewModels | `viewmodel/` | `ViewModels/` |
| Models | `model/` | `Models/` |
| API Client | `network/` | `Services/` |
| Resources | `res/` | `Assets.xcassets/` |
| Config | `build.gradle.kts` | `Info.plist` |
| Dependencies | `build.gradle.kts` | `Package.swift` or Podfile |

### UI Framework Equivalents
| Android (Compose) | iOS (SwiftUI) |
|-------------------|---------------|
| `@Composable` | `View` protocol |
| `Column` | `VStack` |
| `Row` | `HStack` |
| `LazyColumn` | `List` or `LazyVStack` |
| `Text` | `Text` |
| `Button` | `Button` |
| `TextField` | `TextField` |
| `Modifier` | View modifiers (`.modifier()`) |
| `remember` | `@State` |
| `viewModel()` | `@StateObject` |
| `collectAsState()` | `@Published` + `@ObservedObject` |

### State Management
| Android | iOS |
|---------|-----|
| `ViewModel` + `StateFlow` | `ObservableObject` + `@Published` |
| `MutableStateFlow` | `@Published var` |
| `collectAsState()` | `@ObservedObject` or `@StateObject` |
| `remember { }` | `@State` |

### Navigation
| Android | iOS |
|---------|-----|
| Jetpack Navigation | NavigationStack/NavigationLink |
| `NavController` | NavigationPath |
| `composable()` | NavigationLink destination |

### Networking
| Android | iOS |
|---------|-----|
| Retrofit / Ktor | URLSession / Alamofire |
| OkHttp | URLSession |
| Gson / Kotlinx Serialization | Codable |

## Best Practices

### 1. Architecture Maintenance (CRITICAL)

**BEFORE implementing ANY feature or fix:**

1. **Explore Existing Code First**
   - Use `Grep` or `Task` tool to search for similar implementations
   - Check existing ViewModels, Services, and UI components
   - Look for reusable patterns and utilities
   - Never assume something doesn't exist - always search first!

2. **Understand Current Architecture**
   - **Android**: MVVM pattern with:
     - `ui/screens/` - Composable UI screens
     - `viewmodel/` - Business logic and state management
     - `model/` - Data classes and models
     - `network/` - API client and service interfaces
     - `repository/` (if exists) - Data layer abstraction
   - **iOS**: MVVM pattern with:
     - `Views/` - SwiftUI view components
     - `ViewModels/` - ObservableObject classes for state
     - `Models/` - Codable data structures
     - `Services/` - API and business logic services

3. **Reuse Before Creating**
   - ✅ **DO**: Extend existing ViewModels if adding related functionality
   - ✅ **DO**: Reuse existing API service methods
   - ✅ **DO**: Leverage existing UI components and styles
   - ✅ **DO**: Use existing models and extend them if needed
   - ❌ **DON'T**: Create duplicate ViewModels for similar screens
   - ❌ **DON'T**: Duplicate API calls - centralize in service layer
   - ❌ **DON'T**: Create new components when existing ones can be reused
   - ❌ **DON'T**: Break established architectural patterns

4. **Maintain Separation of Concerns**
   - **UI Layer**: Only UI logic, no business logic or API calls
   - **ViewModel Layer**: Business logic, state management, coordinate data flow
   - **Service/Repository Layer**: API calls, data fetching, caching
   - **Model Layer**: Data structures only, no logic

5. **Follow Existing Patterns**
   - If the app uses dependency injection, continue using it
   - If there's a base ViewModel class, extend it
   - If there's a networking wrapper, use it
   - Match existing error handling patterns
   - Follow existing navigation patterns

### 2. Code Discovery Workflow

**Step-by-step process for any new task:**

```
1. SEARCH for existing implementations
   Android: Grep for class names, function names, similar features
   iOS: Grep for similar View/ViewModel names

2. READ related files
   - Find the closest existing feature
   - Study how it's implemented
   - Note the patterns used

3. IDENTIFY reusable components
   - List ViewModels that can be extended
   - List Services that can be reused
   - List UI components that match your needs

4. PLAN the implementation
   - Decide: Reuse vs. Create new
   - Document what you'll extend vs. create
   - Ensure consistency with existing code

5. IMPLEMENT following established patterns
   - Mirror the structure of similar features
   - Reuse utilities and helpers
   - Maintain naming conventions
```

**Example Search Commands:**
```bash
# Find ViewModels in Android
Grep pattern: "class.*ViewModel" glob: "*.kt"

# Find API service methods in iOS
Grep pattern: "func.*async throws" glob: "Services/*.swift"

# Find similar UI screens
Grep pattern: "@Composable.*Screen" glob: "*.kt"
Grep pattern: "struct.*View.*:" glob: "Views/*.swift"
```

### 3. Code Style
- **Android**: Follow Kotlin conventions, use Jetpack Compose best practices
- **iOS**: Follow Swift conventions, use SwiftUI best practices
- Keep business logic platform-agnostic where possible
- Use native patterns for each platform (don't force Android patterns into iOS or vice versa)
- **Match existing naming conventions** in the codebase
- **Follow existing file organization** patterns

### 4. API Integration
- Both apps should use the **same API endpoints**
- Both apps should handle the **same data models** (structure may differ by language)
- Error handling should be **consistent** across platforms
- Authentication/token management should work **identically**
- **Reuse existing API service classes** - don't create new ones for similar operations
- Check for existing endpoint methods before adding new ones

### 5. UI/UX Consistency
- Colors, fonts, spacing should match across platforms
- User flows should be identical
- Feature parity must be maintained
- Respect platform-specific design guidelines (Material Design vs Human Interface Guidelines)
- **Reuse existing composables/views** for consistent UI elements
- Check for existing theme colors, text styles, and spacing values

### 6. Feature Implementation Checklist
When implementing a feature, ensure:
- [ ] **Searched for existing similar implementations**
- [ ] **Identified reusable components and patterns**
- [ ] Feature implemented in Android (following existing architecture)
- [ ] Feature implemented in iOS (following existing architecture)
- [ ] UI/UX is consistent across both platforms
- [ ] API integration works on both platforms (reusing existing services)
- [ ] Error handling is consistent
- [ ] Loading states are handled on both platforms
- [ ] Edge cases handled on both platforms
- [ ] No code duplication - reused existing utilities
- [ ] Documentation updated for both platforms

### 7. Testing
- Test features on **both platforms** before marking complete
- Verify API responses work correctly on both
- Check error scenarios on both platforms
- Validate UI responsiveness on both platforms
- Ensure reused components still work correctly with new changes

### 8. Dependencies
- **Check if functionality already exists** before adding new dependencies
- When adding a library to one platform, add the equivalent to the other:
  - Android: Update `build.gradle.kts`
  - iOS: Update `Package.swift` or Podfile
- Document why a dependency is needed
- Keep dependencies minimal and security-conscious
- Verify dependency doesn't conflict with existing ones

### 9. Version Control
- Commit changes for both platforms together when implementing shared features
- Use descriptive commit messages that mention both platforms when applicable
- Example: "Add book search feature to Android and iOS apps"

### 10. Documentation
- Update README files in both project folders
- Keep architecture docs in sync
- Document platform-specific quirks or differences

## Common Pitfalls to Avoid

### Cross-Platform Pitfalls
1. ❌ Implementing a feature in only one platform
2. ❌ Forgetting to update API models in both platforms
3. ❌ Using different color values or themes between platforms
4. ❌ Inconsistent error messages or handling
5. ❌ Different navigation flows between platforms
6. ❌ Forgetting to test on both platforms
7. ❌ Platform-specific bugs due to different implementations

### Architecture Pitfalls
8. ❌ **Creating new components without checking for existing ones**
9. ❌ **Duplicating ViewModels instead of extending/reusing**
10. ❌ **Making API calls directly in UI components**
11. ❌ **Breaking MVVM pattern (e.g., business logic in Views)**
12. ❌ **Creating duplicate API service methods**
13. ❌ **Ignoring existing utilities and helper functions**
14. ❌ **Not following existing naming conventions**
15. ❌ **Creating inconsistent file structures**
16. ❌ **Mixing different architectural patterns**
17. ❌ **Adding unnecessary dependencies**

## Architectural Patterns & Anti-Patterns

### ✅ GOOD Patterns

#### 1. Reusing Existing ViewModels
```kotlin
// Android - GOOD: Extend existing ViewModel
class BookDetailsViewModel : BaseViewModel() {
    // Reuses base functionality like error handling
}

// OR add functionality to existing ViewModel if related
class LibraryViewModel : ViewModel() {
    // Already handles book lists
    fun searchBooks(query: String) { /* new feature */ }
}
```

```swift
// iOS - GOOD: Extend existing ViewModel
class BookDetailsViewModel: BaseViewModel {
    // Reuses base functionality
}

// OR extend existing related ViewModel
class LibraryViewModel: ObservableObject {
    // Already manages library state
    func searchBooks(query: String) { /* new feature */ }
}
```

#### 2. Centralized API Service
```kotlin
// Android - GOOD: Reuse existing service
class ShamelaApiService {
    suspend fun getBooks(): List<Book>
    suspend fun searchBooks(query: String): List<Book> // New method in existing service
}
```

```swift
// iOS - GOOD: Extend existing service
class ShamelaAPIService {
    func getBooks() async throws -> [Book]
    func searchBooks(query: String) async throws -> [Book] // New method
}
```

#### 3. Reusable UI Components
```kotlin
// Android - GOOD: Create reusable components
@Composable
fun BookCard(book: Book, onClick: () -> Unit) {
    // Reusable across multiple screens
}

@Composable
fun BookListScreen() {
    LazyColumn {
        items(books) { book ->
            BookCard(book) { /* ... */ } // Reuse!
        }
    }
}
```

```swift
// iOS - GOOD: Reusable SwiftUI views
struct BookCard: View {
    let book: Book
    let onTap: () -> Void
    // Reusable component
}

struct BookListView: View {
    var body: some View {
        List(books) { book in
            BookCard(book: book) { /* ... */ } // Reuse!
        }
    }
}
```

#### 4. Proper Separation of Concerns
```kotlin
// Android - GOOD: Clear separation
// UI Layer
@Composable
fun BookScreen(viewModel: BookViewModel = viewModel()) {
    val uiState by viewModel.uiState.collectAsState()
    // Only UI logic here
}

// ViewModel Layer
class BookViewModel : ViewModel() {
    private val repository = BookRepository()
    // Business logic and state management
}

// Repository Layer
class BookRepository {
    private val apiService = ShamelaApiService()
    // Data operations
}
```

### ❌ BAD Anti-Patterns

#### 1. Duplicate ViewModels
```kotlin
// Android - BAD: Creating duplicate ViewModels
class BookListViewModel { /* ... */ }
class BookSearchViewModel { /* ... */ } // Duplicate! Should extend BookListViewModel
class LibraryBooksViewModel { /* ... */ } // Another duplicate!
```

#### 2. API Calls in UI Layer
```kotlin
// Android - BAD: API call in Composable
@Composable
fun BookScreen() {
    LaunchedEffect(Unit) {
        val books = apiService.getBooks() // ❌ NO! Violates MVVM
        // ...
    }
}

// GOOD: API call in ViewModel
class BookViewModel : ViewModel() {
    fun loadBooks() {
        viewModelScope.launch {
            val books = repository.getBooks() // ✅ YES!
        }
    }
}
```

#### 3. Duplicate API Methods
```kotlin
// Android - BAD: Duplicate methods in different files
// File 1
class BookApiService {
    suspend fun getBooks(): List<Book>
}

// File 2
class LibraryApiService {
    suspend fun fetchBooks(): List<Book> // ❌ Duplicate!
}

// GOOD: One centralized service
class ShamelaApiService {
    suspend fun getBooks(): List<Book> // ✅ Single source
}
```

#### 4. Business Logic in Views
```swift
// iOS - BAD: Business logic in SwiftUI View
struct BookListView: View {
    @State private var books: [Book] = []

    var body: some View {
        List(books) { book in
            Text(book.title)
        }
        .onAppear {
            // ❌ BAD: API call and business logic in View
            Task {
                let response = try await URLSession.shared.data(...)
                books = decode(response)
            }
        }
    }
}

// GOOD: Business logic in ViewModel
class BookListViewModel: ObservableObject {
    @Published var books: [Book] = []
    private let apiService = ShamelaAPIService()

    func loadBooks() async {
        // ✅ GOOD: Logic in ViewModel
        books = try await apiService.getBooks()
    }
}
```

## Code Reusability Checklist

Before creating ANY new file, ask yourself:

- [ ] **Does a similar component already exist?**
  - Search with Grep for similar class names
  - Look in equivalent directories (ui/screens, ViewModels, etc.)

- [ ] **Can I extend an existing class?**
  - Check for base classes or parent ViewModels
  - See if related functionality exists that can be enhanced

- [ ] **Can I add to an existing file?**
  - If functionality is related, add to existing class
  - Don't create new files unnecessarily

- [ ] **Am I following the existing pattern?**
  - Study similar implementations
  - Match naming conventions
  - Follow same architectural approach

- [ ] **Is this the right layer?**
  - UI logic → View/Composable
  - Business logic → ViewModel
  - Data operations → Service/Repository
  - Data structures → Model

## Quick Reference Commands

### Android
```bash
# Build Android app
cd shamelagpt-android && ./gradlew build

# Run Android tests
cd shamelagpt-android && ./gradlew test

# Assemble debug APK
cd shamelagpt-android && ./gradlew assembleDebug
```

### iOS
```bash
# Build iOS app
cd shamelagpt-ios && xcodebuild -scheme ShamelaGPT -configuration Debug build

# Run iOS tests
cd shamelagpt-ios && xcodebuild test -scheme ShamelaGPT

# Open in Xcode
open shamelagpt-ios/ShamelaGPT.xcodeproj
```

## When to Ask for Clarification

If a request is ambiguous about which platform(s) it applies to:
1. **Default assumption**: Apply to BOTH platforms
2. **Ask if uncertain**: "Should this apply to both Android and iOS apps, or just one platform?"
3. **Confirm scope**: Large changes should confirm platform scope before starting

## Project-Specific Notes

### Current State
- ✅ Both Android and iOS apps are complete and functional
- ✅ Both apps share the same backend API
- ✅ Both apps have similar feature sets
- ✅ Both apps follow their respective platform design guidelines

### Technology Stack
**Android:**
- Language: Kotlin
- UI: Jetpack Compose
- Architecture: MVVM
- HTTP Client: Retrofit/OkHttp
- Dependency Injection: Hilt (if used)
- Build: Gradle (KTS)

**iOS:**
- Language: Swift
- UI: SwiftUI
- Architecture: MVVM
- HTTP Client: URLSession
- Build: Xcode

### API Endpoints (Shared)
Both apps connect to the same backend endpoints. When updating API integration:
- Update models in both `Android/model/` and `iOS/Models/`
- Update network calls in both `Android/network/` and `iOS/Services/`
- Ensure error handling is consistent

## Response Template for Cross-Platform Changes

When making changes that affect both platforms, structure your response like:

```
I'll implement [feature/fix] for both Android and iOS apps.

**Android Changes:**
1. [List changes]
2. [File paths]

**iOS Changes:**
1. [List changes]
2. [File paths]

Let me start with Android...
[Implement Android changes]

Now applying equivalent changes to iOS...
[Implement iOS changes]
```

---

**Remember**: This is ONE project with TWO platforms. Keep them in sync!
