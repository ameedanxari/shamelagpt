# Architecture Overview

ShamelaGPT is built with a focus on **Platform Parity**, **Clean Architecture**, and **Testability**. Both iOS and Android versions share the same architectural principles and business logic structure.

## Architectural Pattern: MVVM + Repository

We use the Model-View-ViewModel (MVVM) pattern combined with a Repository layer to manage data flow.

### 1. View (Presentation Layer)
- **iOS**: SwiftUI Views that observe `@Published` properties in ViewModels.
- **Android**: Jetpack Compose functions that observe `StateFlow` from ViewModels.
- *Responsibility*: Display data to the user and forward user actions to the ViewModel.

### 2. ViewModel
- **iOS**: Classes conforming to `ObservableObject` and marked with `@MainActor`.
- **Android**: `androidx.lifecycle.ViewModel` classes.
- *Responsibility*: Maintain UI state, handle business logic by calling Use Cases, and transform data for display.

### 3. Domain Layer
- **Models**: Platform-agnostic data structures (`Conversation`, `Message`, `User`).
- **Use Cases**: Encapsulate specific business logic (e.g., `SendMessageUseCase`, `GetConversationsUseCase`).
- **Repository Interfaces**: Define contracts for data access.

### 4. Data Layer (Implementation)
- **Repositories**: Implementing domain interfaces. They decide whether to fetch data from the Network or Local DB.
- **Data Sources**:
    - **Remote**: API clients (Retrofit/URLSession).
    - **Local**: Local databases (Room/Core Data).
- **Mappers**: Convert between DTOs (Data Transfer Objects), Entity Models, and Domain Models.

## Data Flow Diagram (Typical Message Send)
1. **User** types a message and taps Send.
2. **View** calls `viewModel.sendMessage()`.
3. **ViewModel** calls `sendMessageUseCase.execute()`.
4. **Use Case** calls `repository.sendMessage()`.
5. **Repository** sends the message to **APIClient** (Networking).
6. **API Response** is received by **Repository**.
7. **Repository** saves the response to **LocalDB** and returns the Domain model.
8. **ViewModel** updates its `uiState`.
9. **View** reflects the new state (message appears in list).

## Platform Parity Checklist
Every new feature must follow this checklist:
- [ ] Feature defined in `USE_CASES.md`.
- [ ] Domain models updated on both platforms.
- [ ] Repository interfaces updated on both platforms.
- [ ] Unit tests covering the new logic on both platforms.
- [ ] UI/UX behavior matches between SwiftUI and Compose.
- [ ] Accessibility support added.
- [ ] Localization keys added to both localization files.

## Technical Decisions
For detailed reasoning behind specific technical choices, see the [Architecture Decision Records (ADRs)](decisions/README.md).
