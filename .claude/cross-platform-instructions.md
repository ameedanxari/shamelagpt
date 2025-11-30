# ShamelaGPT Cross-Platform Dev Instructions

## Critical: Apply Changes to BOTH Platforms
Dual-platform: `/shamelagpt-android` (Kotlin/Compose), `/shamelagpt-ios` (Swift/SwiftUI)

**Default:** Unless explicitly stated, ALL changes apply to BOTH platforms.

## Platform Mappings

| Android | iOS |
|---------|-----|
| `@Composable` | `View` |
| `Column/Row` | `VStack/HStack` |
| `ViewModel+StateFlow` | `ObservableObject+@Published` |
| `remember{}` | `@State` |
| `viewModel()` | `@StateObject` |
| `Retrofit/Ktor` | `URLSession` |
| `Gson/KotlinX` | `Codable` |

## Architecture: MVVM (Both Platforms)
**Android:** `ui/screens/` → `viewmodel/` → `repository/` → `network/`
**iOS:** `Views/` → `ViewModels/` → `Services/`

## Workflow for ANY Task

1. **Search First**: `Grep` for existing implementations
2. **Reuse**: Extend existing ViewModels/Services, don't duplicate
3. **Implement**: Apply to platform 1, then platform 2
4. **Test**: Both platforms, all scenarios (success/error/edge)

## Testing: MANDATORY (Both Platforms)

### Requirements
- ✅ Unit tests for new components
- ✅ ALL network calls mocked (no backend dependency)
- ✅ Error scenarios (network/HTTP/parsing)
- ✅ Edge cases (empty/long text/special chars)
- ❌ NEVER remove functionality to fix tests
- ❌ NEVER skip failing tests

### Mocking

**Android (MockK):**
```kotlin
val mockRepo = mockk<ChatRepository>()
coEvery { mockRepo.sendMessage(any()) } returns Result.success(response)
```

**iOS (Protocol Mocks):**
```swift
mockAPIClient.mockChatResponse = ChatResponse(answer: "Test", threadId: "thread_123")
```

### Mock Validation
- Thread IDs: `"thread_abc123"` (NOT `null` or `"123"`)
- API uses `snake_case`: `thread_id`, `book_name`
- Error codes: 400/404/500/503

### Test Commands
**Android:** `./gradlew test`
**iOS:** `xcodebuild test -scheme ShamelaGPT`

## Critical Rules

### ✅ DO
- Search for existing code before creating new
- Extend existing ViewModels if functionality related
- Centralize API calls in Service layer
- Keep UI/ViewModel/Service separation
- Match existing patterns and naming
- Test on BOTH platforms
- Implement feature completely before marking done

### ❌ DON'T
- Create duplicate ViewModels/Services
- Put API calls in UI layer
- Make real network calls in tests
- Remove features to fix tests
- Fix tests without understanding why they fail
- Use incorrect mock data (validate against API specs)
- Skip error scenario testing

## Common Patterns

**Reuse ViewModel:**
```kotlin
// GOOD: Extend existing
class BookViewModel : BaseViewModel()
```

**Centralized API:**
```kotlin
// GOOD: One service
class ShamelaApiService {
    suspend fun getBooks()
    suspend fun searchBooks(query: String) // Add to existing
}
```

**Mocked Tests:**
```kotlin
@Test
fun `test with mocks`() = runTest {
    coEvery { mockRepo.sendMessage(any()) } returns Result.success(data)
    // Test implementation
}
```

## Anti-Patterns

- ❌ `BookListViewModel`, `BookSearchViewModel`, `LibraryBooksViewModel` (duplicates!)
- ❌ API calls in `@Composable` or SwiftUI `View`
- ❌ Real network in tests: `URLSession.shared` or unmocked `apiService`
- ❌ Removing functionality: `// return null // Fix test`
- ❌ Wrong mocks: `threadId: null` or `threadId: "123"`

## File Structure
**Android:** `app/src/main/java/com/shamelagpt/`
**iOS:** `shamelagpt/`

## Build Commands
**Android:** `cd shamelagpt-android && ./gradlew build`
**iOS:** `cd shamelagpt-ios && xcodebuild -scheme ShamelaGPT build`

## Test-Driven Debugging
1. READ failure → 2. CHECK API specs → 3. VALIDATE test expectations → 4. FIX implementation OR test → 5. RUN full suite

## Key Principle
ONE project, TWO platforms. Keep synchronized. Default = apply to BOTH.
