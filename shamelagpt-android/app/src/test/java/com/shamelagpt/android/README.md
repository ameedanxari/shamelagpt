# ShamelaGPT Android - Unit Tests

This directory contains the unit test suite for the ShamelaGPT Android application. All tests are designed to run quickly without requiring the Android framework or emulator.

## 📊 Current Status

**Total Tests**: 110
**Success Rate**: 100% ✅
**Build Status**: SUCCESS ✅
**Execution Time**: ~10 seconds

## 🏗️ Directory Structure

```
app/src/test/java/com/shamelagpt/android/
├── core/
│   └── network/
│       ├── NetworkErrorTest.kt          (10 tests) - Error type tests
│       └── SafeApiCallTest.kt           (10 tests) - API wrapper tests
├── data/
│   ├── remote/
│   │   └── ResponseParserTest.kt        (18 tests) - Markdown parsing
│   └── repository/
│       ├── ChatRepositoryImplTest.kt    (11 tests) - API + Storage integration
│       └── ConversationRepositoryImplTest.kt (16 tests) - Database operations
├── domain/
│   └── usecase/
│       └── SendMessageUseCaseTest.kt    (17 tests) - Business logic
├── presentation/
│   └── chat/
│       └── ChatViewModelTest.kt         (27 tests) - UI state management
├── mock/
│   ├── TestData.kt                      - Test fixtures & factory methods
│   └── MockRepositories.kt              - In-memory repository implementations
└── util/
    └── MainCoroutineRule.kt             - Coroutine test helper
```

## 🧪 Test Categories

### Core Layer (20 tests)
- **NetworkErrorTest**: HTTP error types, network exceptions, error mapping
- **SafeApiCall**: API call wrapper, exception handling, success/failure flows

### Data Layer (45 tests)
- **ResponseParserTest**: Markdown parsing, source extraction, edge cases
- **ChatRepositoryImplTest**: API integration, message storage, error handling
- **ConversationRepositoryImplTest**: CRUD operations, Flow emissions, data persistence

### Domain Layer (17 tests)
- **SendMessageUseCaseTest**: Business logic, conversation management, validation

### Presentation Layer (27 tests)
- **ChatViewModelTest**: UI state, user input, message sending, voice input

## 🛠️ Testing Framework

### Core Dependencies
- **JUnit 4**: Test framework
- **MockK**: Kotlin-friendly mocking
- **Truth**: Fluent assertions (Google)
- **Turbine**: Flow testing
- **Coroutines Test**: Async testing

### Test Utilities
- **MainCoroutineRule**: Replaces Main dispatcher for coroutine tests
- **TestData**: Pre-configured test fixtures (conversations, messages, responses)
- **MockRepositories**: In-memory implementations with Flow support

## 📝 Writing Tests

### Test Structure
All tests follow the **Given-When-Then** (AAA) pattern:

```kotlin
@Test
fun testSendMessageSuccess() = runTest {
    // Given - Set up test data and mocks
    val question = "What is prayer?"
    val response = TestData.sampleChatResponse
    coEvery { mockApi.sendMessage(question, null) } returns Result.success(response)

    // When - Execute the action
    val result = repository.sendMessage(question, conversationId, null)

    // Then - Verify the outcome
    assertThat(result.isSuccess).isTrue()
    assertThat(result.getOrNull()).isEqualTo(response)
}
```

### Naming Conventions
- Test class: `{ClassName}Test.kt`
- Test method: `test{MethodName}{Scenario}`
- Examples:
  - `testSendMessageSuccess` - Happy path
  - `testSendMessageWithNetworkError` - Error scenario
  - `testSendMessageWithEmptyInput` - Edge case

### Common Patterns

#### Testing Coroutines
```kotlin
@get:Rule
val mainCoroutineRule = MainCoroutineRule()

@Test
fun testAsyncOperation() = runTest {
    // Use runTest for coroutine tests
    val result = suspendingFunction()
    assertThat(result).isNotNull()
}
```

#### Testing Flows
```kotlin
@Test
fun testFlowEmission() = runTest {
    repository.getConversations().test {
        val items = awaitItem()
        assertThat(items).hasSize(2)
        awaitComplete()
    }
}
```

#### Mocking with MockK
```kotlin
val mockRepository = mockk<ChatRepository>()

coEvery {
    mockRepository.sendMessage(any(), any(), any())
} returns Result.success(response)

// Verify calls
coVerify { mockRepository.sendMessage("test", "conv-123", null) }
```

#### Using Test Data
```kotlin
// Pre-configured fixtures
val conversation = TestData.sampleConversation
val message = TestData.sampleUserMessage
val response = TestData.sampleChatResponse

// Factory methods
val customMessage = TestData.createMessage(
    id = "msg-1",
    content = "Custom content",
    timestamp = System.currentTimeMillis()
)
```

## 🚀 Running Tests

### All Tests
```bash
./gradlew test
```

### Specific Test Class
```bash
./gradlew test --tests "ChatViewModelTest"
```

### Specific Test Method
```bash
./gradlew test --tests "ChatViewModelTest.testSendMessageSuccess"
```

### With Clean Build
```bash
./gradlew clean test
```

### View HTML Report
```bash
./gradlew test
open app/build/reports/tests/testDebugUnitTest/index.html
```

### Continuous Testing (watch mode)
```bash
./gradlew test --continuous
```

## 🔍 Debugging Failed Tests

### 1. Check Test Report
The HTML report shows detailed failure information:
```
app/build/reports/tests/testDebugUnitTest/index.html
```

### 2. Run Single Test
Isolate the failing test:
```bash
./gradlew test --tests "ClassName.testMethodName"
```

### 3. Add Logging
```kotlin
@Test
fun testDebug() = runTest {
    println("Debug: $value")
    assertThat(value).isEqualTo(expected)
}
```

### 4. Verify Mock Setup
Ensure all mocks are configured:
```kotlin
coEvery { mockApi.sendMessage(any(), any()) } returns Result.success(response)
// Missing configuration will cause "no answer found" errors
```

## 📚 Best Practices

### ✅ DO
- **Use descriptive test names** that explain what's being tested
- **Follow Given-When-Then** structure for clarity
- **Test one thing per test** (single responsibility)
- **Use TestData fixtures** for consistent test data
- **Clean up** in @After blocks (reset mocks)
- **Make tests independent** (no shared state)
- **Test error scenarios** (not just happy paths)
- **Verify both state and behavior** (assertions + verification)

### ❌ DON'T
- **Don't test implementation details** (test behavior, not internals)
- **Don't use real network calls** (always mock)
- **Don't rely on test execution order** (tests should be independent)
- **Don't share mutable state** between tests
- **Don't ignore flaky tests** (fix them or remove them)
- **Don't test Android framework** (use instrumented tests for that)
- **Don't hardcode timestamps** (use relative times or factories)

## 🐛 Common Issues

### "No answer found for: MockKStub"
**Cause**: Missing mock configuration
**Fix**: Add `coEvery {}` or `every {}` for the mocked method

### "Expected not to be: null"
**Cause**: Mock returned null when object was expected
**Fix**: Verify mock setup and ensure proper data creation

### "Tests run in wrong order"
**Cause**: Tests are interdependent
**Fix**: Make each test independent with its own setup

### "Flow never completes"
**Cause**: Flow not closed in test
**Fix**: Use `awaitComplete()` or set timeout

### "Coroutine not advancing"
**Cause**: Missing `testScheduler.advanceUntilIdle()`
**Fix**: Advance the test scheduler or use `runTest {}`

## 📈 Coverage Goals

### Current Coverage
- **Data Layer**: 95%+ ✅
- **Domain Layer**: 90%+ ✅
- **Presentation Layer**: 85%+ (partial)
- **Core Layer**: 100% ✅

### Target Coverage
- **Overall**: 80%+
- **P0 Critical Paths**: 90%+
- **Error Handling**: 100%

## 🔄 Continuous Integration

Tests run automatically on:
- Every commit (via pre-commit hook)
- Pull requests
- Main branch merges

**Failure = Build blocked** ❌

## 📖 Additional Resources

- [JUnit 4 Documentation](https://junit.org/junit4/)
- [MockK Guide](https://mockk.io/)
- [Turbine Documentation](https://github.com/cashapp/turbine)
- [Truth Assertions](https://truth.dev/)
- [Coroutines Testing](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-test/)

## 🎯 Next Steps

### To Add More Tests:
1. Identify the component to test
2. Create test class in appropriate package
3. Set up mocks and test data
4. Write tests following Given-When-Then
5. Run tests locally
6. Update this README if adding new patterns

### Priorities:
- ⏳ Integration Tests (end-to-end flows)
- ⏳ Complete ChatViewModel (15 tests remaining)
- ⏳ HistoryViewModel (20 tests)
- ⏳ UI Tests (Compose)

---

**Last Updated**: November 19, 2025
**Maintained By**: Development Team
**Questions?**: Check test documentation or ask in #android channel
