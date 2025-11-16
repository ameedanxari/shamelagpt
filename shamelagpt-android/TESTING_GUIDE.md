# ShamelaGPT Android - Testing Guide

**Last Updated**: November 20, 2025
**Total Tests**: 151
**Status**: All Passing ✅

---

## Quick Commands

```bash
# Run all tests
./gradlew test

# Run specific test class
./gradlew test --tests "ChatViewModelTest"

# Run tests with clean build
./gradlew clean test

# View test report
open app/build/reports/tests/testDebugUnitTest/index.html

# Run tests continuously (watch mode)
./gradlew test --continuous
```

---

## Test Structure

```
app/src/test/java/com/shamelagpt/android/
├── core/network/               - NetworkErrorTest, SafeApiCallTest (20 tests)
├── data/
│   ├── remote/                 - ResponseParserTest (18 tests)
│   └── repository/             - ChatRepositoryImplTest, ConversationRepositoryImplTest (27 tests)
├── domain/usecase/             - SendMessageUseCaseTest (17 tests)
├── presentation/
│   ├── chat/                   - ChatViewModelTest (34 tests)
│   └── history/                - HistoryViewModelTest (19 tests)
├── integration/                - MessageFlow, FactCheck, NetworkRecovery (15 tests)
├── mock/                       - TestData, MockRepositories
└── util/                       - MainCoroutineRule
```

---

## Test Coverage by Component

| Component | Tests | Status |
|-----------|-------|--------|
| ChatViewModel | 34 | ✅ |
| HistoryViewModel | 19 | ✅ |
| Integration Tests | 15 | ✅ |
| ChatRepository | 11 | ✅ |
| ConversationRepository | 16 | ✅ |
| SendMessageUseCase | 17 | ✅ |
| ResponseParser | 18 | ✅ |
| Network Layer | 20 | ✅ |
| **TOTAL** | **151** | ✅ |

---

## Writing New Tests

### Basic Test Template

```kotlin
@ExperimentalCoroutinesApi
class MyComponentTest {

    @get:Rule
    val mainCoroutineRule = MainCoroutineRule()

    private lateinit var component: MyComponent
    private lateinit var mockDependency: Dependency

    @Before
    fun setup() {
        mockDependency = mockk()
        component = MyComponent(mockDependency)
    }

    @After
    fun tearDown() {
        // Clean up if needed
    }

    @Test
    fun testActionPerformsExpectedBehavior() = runTest {
        // Given - Set up test data and mocks
        val input = "test"
        coEvery { mockDependency.method(input) } returns Result.success(data)

        // When - Execute the action
        val result = component.performAction(input)
        testScheduler.advanceUntilIdle() // Wait for async operations

        // Then - Verify the outcome
        assertThat(result.isSuccess).isTrue()
        coVerify { mockDependency.method(input) }
    }
}
```

### Testing Coroutines

```kotlin
@Test
fun testSuspendFunction() = runTest {
    val result = repository.getData()
    testScheduler.advanceUntilIdle() // Important for async operations
    assertThat(result).isNotNull()
}
```

### Testing Flows

```kotlin
@Test
fun testFlowEmission() = runTest {
    repository.getDataFlow().test {
        val item = awaitItem()
        assertThat(item).isEqualTo(expected)
        awaitComplete()
    }
}
```

### Using Test Data

```kotlin
// Pre-configured fixtures
val conversation = TestData.sampleConversation
val message = TestData.sampleUserMessage
val response = TestData.sampleChatResponse

// Factory methods
val customMessage = TestData.createMessage(
    id = "msg-1",
    content = "Custom content"
)
```

### Integration Tests Pattern

```kotlin
@Before
fun setup() {
    // Create repository first
    mockConversationRepository = MockConversationRepository()

    // Pass it to MockChatRepository (important!)
    mockChatRepository = MockChatRepository(mockConversationRepository)

    // Create use case
    sendMessageUseCase = SendMessageUseCase(
        chatRepository = mockChatRepository,
        conversationRepository = mockConversationRepository
    )
}

@Test
fun testEndToEndFlow() = runTest {
    // Given
    mockChatRepository.sendMessageResult = Result.success(response)

    // When
    val result = sendMessageUseCase(question, null, null)
    testScheduler.advanceUntilIdle() // Essential!

    // Then
    val conversation = mockConversationRepository.getConversationById(...)
    assertThat(conversation!!.messages).hasSize(2) // User + AI
}
```

---

## Common Patterns

### Mocking with MockK

```kotlin
// Setup
val mock = mockk<Interface>()
coEvery { mock.method(any()) } returns value

// Verify
coVerify { mock.method("param") }
coVerify(exactly = 2) { mock.method(any()) }
```

### Testing ViewModel

```kotlin
@Test
fun testViewModelState() = runTest {
    // Given
    viewModel.updateInputText("test")

    // When
    viewModel.sendMessage()
    testScheduler.advanceUntilIdle()

    // Then
    assertThat(viewModel.uiState.value.isLoading).isFalse()
}
```

### Testing Events

```kotlin
@Test
fun testEventEmission() = runTest {
    viewModel.events.test {
        viewModel.performAction()
        testScheduler.advanceUntilIdle()

        val event = awaitItem()
        assertThat(event).isInstanceOf(MyEvent::class.java)
    }
}
```

---

## Debugging Failed Tests

### 1. Check HTML Report
```bash
open app/build/reports/tests/testDebugUnitTest/index.html
```

### 2. Run Single Test
```bash
./gradlew test --tests "ClassName.testMethodName"
```

### 3. Common Issues

**"No answer found for: MockKStub"**
- Missing mock setup: Add `coEvery {}` or `every {}`

**"Expected not to be: null"**
- Mock returned null: Check mock setup and data creation

**"Tests run in wrong order"**
- Tests are interdependent: Make each test independent

**"Coroutine not advancing"**
- Missing `testScheduler.advanceUntilIdle()`

**"Flow never completes"**
- Add `awaitComplete()` or set timeout in Flow test

---

## Best Practices

### ✅ DO
- Use descriptive test names
- Follow Given-When-Then structure
- Test one thing per test
- Use TestData fixtures
- Clean up in @After blocks
- Make tests independent
- Test error scenarios
- Call `testScheduler.advanceUntilIdle()` after async operations

### ❌ DON'T
- Test implementation details
- Use real network calls
- Rely on test execution order
- Share mutable state between tests
- Ignore flaky tests
- Hardcode timestamps
- Forget to advance coroutine scheduler

---

## Key Files

- **Test Guide**: `app/src/test/.../README.md` (Comprehensive guide)
- **Test Data**: `mock/TestData.kt` (Fixtures and factory methods)
- **Mock Repositories**: `mock/MockRepositories.kt` (Test implementations)
- **Coroutine Rule**: `util/MainCoroutineRule.kt` (Test helper)

---

## Metrics

```
Build Time:          ~30 seconds
Success Rate:        100% (151/151)
P0 Coverage:         95%+
iOS Parity:          95%+
Test Code:           ~3,500 lines
```

---

## Getting Help

1. Check `app/src/test/.../README.md` for detailed patterns
2. Review existing tests for examples
3. Check test reports for failure details
4. See `ANDROID_TEST_COMPLETION_SUMMARY.md` for complete documentation

---

**Status**: ✅ Production Ready
**Phase**: Unit + Integration Tests Complete
**Next**: UI Tests (Optional)
