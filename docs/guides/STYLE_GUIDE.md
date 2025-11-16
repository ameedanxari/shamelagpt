# Code Style Guide

This guide defines the coding standards and best practices for ShamelaGPT. Consistency is key to maintaining a high-quality codebase that is easy for both humans and AI agents to navigate.

## 1. General Principles
- **Clarity over Conciseness**: Write code that is easy to read and understand.
- **Fail Fast**: Use guards (Swift) or require/assert (Kotlin) to handle invalid states early.
- **Self-Documenting**: Choose descriptive names for variables, functions, and classes.
- **DRY (Don't Repeat Yourself)**: Extract shared logic into utilities or base classes.

## 2. Kotlin / Android Standards

### Naming
- Classes/Objects: `PascalCase`
- Functions/Variables: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Layouts/Resources: `snake_case`

### Patterns
- Use **Trailing Lambda** syntax wherever possible.
- Prefer **Immutable** collections (`List` instead of `MutableList`) where possible.
- Use **StateFlow** for ViewModel state and **SharedFlow** for one-time events.
- **Compose**: Prefix UI components with `Modifier` parameter.

### Example
```kotlin
@Composable
fun MessageList(
    messages: List<Message>,
    modifier: Modifier = Modifier
) {
    LazyColumn(modifier = modifier) {
        // ...
    }
}
```

## 3. Swift / iOS Standards

### Naming
- Classes/Structs/Enums: `PascalCase`
- Functions/Variables: `camelCase`
- Enum cases: `camelCase`

### Patterns
- Use **Swift Concurrency** (`async/await`) instead of completion handlers.
- Prefer **Structs** over Classes for models and stateless logic.
- Use `@MainActor` for all ViewModels to ensure UI updates on the main thread.
- **SwiftUI**: Use `ViewModifier` for reusable styling logic to keep views clean.

### Example
```swift
@MainActor
class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [Message] = []
    
    func sendMessage(_ text: String) async throws {
        // ...
    }
}
```

## 4. Documentation
- Use `///` for documentation comments in Swift.
- Use `/** ... */` for documentation comments in Kotlin.
- Document all public methods and complex logic.

## 5. Testing
- Every public function in a ViewModel or UseCase must have a corresponding unit test.
- Use descriptive test names: `test[Function]_[Condition]_[ExpectedOutcome]`.
- Mock all external dependencies (Network, Database, System Services).

## 6. Resources & Assets
- **Strings**: Never hardcode user-facing strings. Use `strings.xml` (Android) and `Localizable.strings` (iOS).
- **Icons**: Use Vector assets (`.xml` or `.symbol`) for resolution independence.
- **Colors**: Reference colors from the `Theme` or `Color` constants.
