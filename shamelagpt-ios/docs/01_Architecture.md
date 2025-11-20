# iOS Architecture Document - ShamelaGPT

## Version: 1.0
## Date: 2025-11-02
## Target Platform: iOS 15.0+

---

## Table of Contents
1. [Architectural Pattern](#architectural-pattern)
2. [Project Structure](#project-structure)
3. [Dependency Injection](#dependency-injection)
4. [State Management](#state-management)
5. [Navigation Architecture](#navigation-architecture)
6. [Data Layer](#data-layer)
7. [Networking Layer](#networking-layer)
8. [Error Handling](#error-handling)
9. [Testing Strategy](#testing-strategy)
10. [Third-Party Dependencies](#third-party-dependencies)

---

## 1. Architectural Pattern

### MVVM + Coordinator Pattern

The app follows the **MVVM (Model-View-ViewModel)** architectural pattern combined with the **Coordinator Pattern** for navigation.

#### Rationale
- **SwiftUI Native**: MVVM works naturally with SwiftUI's ObservableObject protocol
- **Separation of Concerns**: Clear separation between UI, business logic, and data
- **Testability**: ViewModels can be tested independently of views
- **Coordinator Pattern**: Decouples navigation logic from ViewModels and Views
- **Reactive Programming**: Leverages Combine framework for reactive data flow

#### Architecture Layers

```
┌─────────────────────────────────────────┐
│           View Layer (SwiftUI)           │
│  - Views, Screens, UI Components        │
└──────────────┬──────────────────────────┘
               │ ObservedObject
               ▼
┌─────────────────────────────────────────┐
│      ViewModel Layer (Business Logic)    │
│  - View State Management                │
│  - User Interaction Handling            │
│  - Combine Publishers                   │
└──────────────┬──────────────────────────┘
               │ Uses
               ▼
┌─────────────────────────────────────────┐
│       Model Layer (Data & Domain)        │
│  - Data Models                          │
│  - Use Cases / Interactors              │
│  - Repository Protocols                 │
└──────────────┬──────────────────────────┘
               │ Implements
               ▼
┌─────────────────────────────────────────┐
│         Data Layer (Infrastructure)      │
│  - API Client                           │
│  - Core Data Stack                      │
│  - Local Storage                        │
└─────────────────────────────────────────┘

         Navigation Flow:
┌─────────────────────────────────────────┐
│       Coordinator (Navigation)           │
│  - App-level navigation                 │
│  - Deep linking                         │
│  - Flow coordination                    │
└─────────────────────────────────────────┘
```

---

## 2. Project Structure

```
ShamelaGPT/
├── App/
│   ├── ShamelaGPTApp.swift          # App entry point
│   ├── AppDelegate.swift            # App lifecycle
│   ├── SceneDelegate.swift          # Scene lifecycle (if needed)
│   └── AppCoordinator.swift         # Root coordinator
│
├── Core/
│   ├── Dependency Injection/
│   │   ├── DependencyContainer.swift
│   │   └── ServiceFactory.swift
│   ├── Networking/
│   │   ├── APIClient.swift
│   │   ├── Endpoint.swift
│   │   ├── NetworkError.swift
│   │   └── RequestBuilder.swift
│   ├── Storage/
│   │   ├── CoreDataStack.swift
│   │   ├── UserDefaultsManager.swift
│   │   └── KeychainManager.swift
│   └── Utilities/
│       ├── Logger.swift
│       ├── Constants.swift
│       └── Extensions/
│
├── Domain/
│   ├── Models/
│   │   ├── Message.swift
│   │   ├── Conversation.swift
│   │   └── User.swift
│   ├── UseCases/
│   │   ├── SendMessageUseCase.swift
│   │   ├── GetConversationsUseCase.swift
│   │   └── DeleteConversationUseCase.swift
│   └── Repositories/
│       ├── ChatRepository.swift (protocol)
│       └── ConversationRepository.swift (protocol)
│
├── Data/
│   ├── Repositories/
│   │   ├── ChatRepositoryImpl.swift
│   │   └── ConversationRepositoryImpl.swift
│   ├── DataSources/
│   │   ├── Remote/
│   │   │   ├── ChatRemoteDataSource.swift
│   │   │   └── ConversationRemoteDataSource.swift
│   │   └── Local/
│   │       ├── ChatLocalDataSource.swift
│   │       └── ConversationLocalDataSource.swift
│   └── CoreData/
│       ├── ShamelaGPT.xcdatamodeld
│       ├── Entities/
│       │   ├── ConversationEntity+CoreDataClass.swift
│       │   └── MessageEntity+CoreDataClass.swift
│       └── Mappers/
│           ├── ConversationMapper.swift
│           └── MessageMapper.swift
│
├── Presentation/
│   ├── Coordinators/
│   │   ├── Coordinator.swift (protocol)
│   │   ├── ChatCoordinator.swift
│   │   └── SettingsCoordinator.swift
│   ├── Scenes/
│   │   ├── Welcome/
│   │   │   ├── WelcomeView.swift
│   │   │   └── WelcomeViewModel.swift
│   │   ├── Chat/
│   │   │   ├── ChatView.swift
│   │   │   ├── ChatViewModel.swift
│   │   │   └── Components/
│   │   │       ├── MessageBubbleView.swift
│   │   │       ├── InputBarView.swift
│   │   │       └── TypingIndicatorView.swift
│   │   ├── ConversationList/
│   │   │   ├── ConversationListView.swift
│   │   │   └── ConversationListViewModel.swift
│   │   └── Settings/
│   │       ├── SettingsView.swift
│   │       └── SettingsViewModel.swift
│   └── Common/
│       ├── Components/
│       │   ├── LoadingView.swift
│       │   ├── ErrorView.swift
│       │   └── EmptyStateView.swift
│       └── Modifiers/
│           └── ViewModifiers.swift
│
├── Resources/
│   ├── Localization/
│   │   ├── en.lproj/
│   │   │   └── Localizable.strings
│   │   └── ar.lproj/
│   │       └── Localizable.strings
│   ├── Assets.xcassets/
│   ├── Fonts/
│   └── Info.plist
│
└── Supporting Files/
    ├── Configuration/
    │   ├── Debug.xcconfig
    │   ├── Release.xcconfig
    │   └── Secrets.xcconfig
    └── LaunchScreen.storyboard
```

---

## 3. Dependency Injection

### Framework: Swinject

**Version**: 2.10.0+

#### Implementation

```swift
// DependencyContainer.swift
import Swinject

final class DependencyContainer {
    static let shared = DependencyContainer()
    private let container = Container()

    private init() {
        registerDependencies()
    }

    private func registerDependencies() {
        // Networking
        container.register(APIClient.self) { _ in
            APIClient(baseURL: Configuration.apiBaseURL)
        }.inObjectScope(.container)

        // Core Data
        container.register(CoreDataStack.self) { _ in
            CoreDataStack.shared
        }.inObjectScope(.container)

        // Repositories
        container.register(ChatRepository.self) { resolver in
            ChatRepositoryImpl(
                remoteDataSource: resolver.resolve(ChatRemoteDataSource.self)!,
                localDataSource: resolver.resolve(ChatLocalDataSource.self)!
            )
        }

        container.register(ConversationRepository.self) { resolver in
            ConversationRepositoryImpl(
                remoteDataSource: resolver.resolve(ConversationRemoteDataSource.self)!,
                localDataSource: resolver.resolve(ConversationLocalDataSource.self)!
            )
        }

        // Data Sources
        container.register(ChatRemoteDataSource.self) { resolver in
            ChatRemoteDataSource(apiClient: resolver.resolve(APIClient.self)!)
        }

        container.register(ChatLocalDataSource.self) { resolver in
            ChatLocalDataSource(coreDataStack: resolver.resolve(CoreDataStack.self)!)
        }

        // Use Cases
        container.register(SendMessageUseCase.self) { resolver in
            SendMessageUseCase(repository: resolver.resolve(ChatRepository.self)!)
        }

        // ViewModels (transient scope - new instance each time)
        container.register(ChatViewModel.self) { resolver in
            ChatViewModel(
                sendMessageUseCase: resolver.resolve(SendMessageUseCase.self)!
            )
        }
    }

    func resolve<T>(_ type: T.Type) -> T {
        container.resolve(type)!
    }
}
```

#### Usage in SwiftUI

```swift
struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel

    init() {
        _viewModel = StateObject(wrappedValue: DependencyContainer.shared.resolve(ChatViewModel.self))
    }

    var body: some View {
        // View implementation
    }
}
```

---

## 4. State Management

### Combine Framework

#### ViewModel Pattern

```swift
import Combine

final class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var conversationId: String?

    // MARK: - Private Properties
    private let sendMessageUseCase: SendMessageUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(sendMessageUseCase: SendMessageUseCase) {
        self.sendMessageUseCase = sendMessageUseCase
        setupBindings()
    }

    // MARK: - Private Methods
    private func setupBindings() {
        // Observe input text changes
        $inputText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                // Handle text changes
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods
    func sendMessage() {
        guard !inputText.isEmpty else { return }

        isLoading = true

        sendMessageUseCase.execute(
            question: inputText,
            threadId: conversationId
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                }
            },
            receiveValue: { [weak self] response in
                self?.messages.append(response.message)
                self?.conversationId = response.threadId
                self?.inputText = ""
            }
        )
        .store(in: &cancellables)
    }
}
```

#### State Container for App-Wide State

```swift
final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUserId: String?
    @Published var selectedLanguage: Language = .english
    @Published var isRTL: Bool = false
    @Published var currentTheme: Theme = .light

    static let shared = AppState()
    private init() {}
}
```

---

## 5. Navigation Architecture

### Coordinator Pattern

#### Protocol Definition

```swift
protocol Coordinator: AnyObject {
    var navigationPath: NavigationPath { get set }
    func start()
    func navigate(to destination: Destination)
    func pop()
    func popToRoot()
}

protocol Destination: Hashable {}
```

#### App Coordinator

```swift
final class AppCoordinator: ObservableObject, Coordinator {
    @Published var navigationPath = NavigationPath()

    enum Route: Destination {
        case welcome
        case chat(conversationId: String?)
        case conversationList
        case settings
    }

    func start() {
        navigate(to: Route.welcome)
    }

    func navigate(to destination: Destination) {
        guard let route = destination as? Route else { return }
        navigationPath.append(route)
    }

    func pop() {
        navigationPath.removeLast()
    }

    func popToRoot() {
        navigationPath = NavigationPath()
    }
}
```

#### Integration with SwiftUI

```swift
@main
struct ShamelaGPTApp: App {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.navigationPath) {
                WelcomeView()
                    .navigationDestination(for: AppCoordinator.Route.self) { route in
                        switch route {
                        case .welcome:
                            WelcomeView()
                        case .chat(let conversationId):
                            ChatView(conversationId: conversationId)
                        case .conversationList:
                            ConversationListView()
                        case .settings:
                            SettingsView()
                        }
                    }
            }
            .environmentObject(coordinator)
            .environmentObject(appState)
        }
    }
}
```

---

## 6. Data Layer

### Core Data Implementation

#### Data Model

```
Entities:
- ConversationEntity
  - id: String (UUID)
  - title: String?
  - createdAt: Date
  - updatedAt: Date
  - messages: [MessageEntity] (one-to-many)

- MessageEntity
  - id: String (UUID)
  - content: String
  - isUserMessage: Bool
  - timestamp: Date
  - conversation: ConversationEntity (many-to-one)
  - sources: String? (JSON array)
```

#### Core Data Stack

```swift
final class CoreDataStack {
    static let shared = CoreDataStack()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ShamelaGPT")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
```

#### Repository Pattern

```swift
protocol ChatRepository {
    func sendMessage(question: String, threadId: String?) -> AnyPublisher<ChatResponse, Error>
    func getMessages(for conversationId: String) -> AnyPublisher<[Message], Error>
    func saveMessage(_ message: Message, conversationId: String) -> AnyPublisher<Void, Error>
}

final class ChatRepositoryImpl: ChatRepository {
    private let remoteDataSource: ChatRemoteDataSource
    private let localDataSource: ChatLocalDataSource

    init(remoteDataSource: ChatRemoteDataSource, localDataSource: ChatLocalDataSource) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }

    func sendMessage(question: String, threadId: String?) -> AnyPublisher<ChatResponse, Error> {
        remoteDataSource.sendMessage(question: question, threadId: threadId)
            .flatMap { [weak self] response -> AnyPublisher<ChatResponse, Error> in
                guard let self = self else {
                    return Fail(error: RepositoryError.unknown).eraseToAnyPublisher()
                }

                // Save to local database
                return self.localDataSource.saveMessage(
                    content: response.answer,
                    conversationId: response.threadId,
                    isUserMessage: false
                )
                .map { response }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func getMessages(for conversationId: String) -> AnyPublisher<[Message], Error> {
        localDataSource.fetchMessages(for: conversationId)
    }

    func saveMessage(_ message: Message, conversationId: String) -> AnyPublisher<Void, Error> {
        localDataSource.saveMessage(
            content: message.content,
            conversationId: conversationId,
            isUserMessage: message.isUserMessage
        )
    }
}
```

---

## 7. Networking Layer

### URLSession-based API Client

```swift
final class APIClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func request<T: Decodable>(
        endpoint: Endpoint,
        responseType: T.Type
    ) -> AnyPublisher<T, Error> {
        guard let request = buildRequest(for: endpoint) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.httpError(statusCode: httpResponse.statusCode)
                }

                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                }
                return NetworkError.decodingError(error)
            }
            .eraseToAnyPublisher()
    }

    private func buildRequest(for endpoint: Endpoint) -> URLRequest? {
        guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers

        if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        return request
    }
}

// Endpoint Protocol
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: [String: Any]? { get }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
}
```

---

## 8. Error Handling

### Error Types

```swift
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case noConnection
    case timeout
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("error.invalidURL", comment: "")
        case .invalidResponse:
            return NSLocalizedString("error.invalidResponse", comment: "")
        case .httpError(let statusCode):
            return NSLocalizedString("error.httpError.\(statusCode)", comment: "")
        case .decodingError:
            return NSLocalizedString("error.decodingError", comment: "")
        case .noConnection:
            return NSLocalizedString("error.noConnection", comment: "")
        case .timeout:
            return NSLocalizedString("error.timeout", comment: "")
        case .unknown:
            return NSLocalizedString("error.unknown", comment: "")
        }
    }
}

enum RepositoryError: LocalizedError {
    case saveFailed
    case fetchFailed
    case deleteFailed
    case unknown
}
```

### Error Handling in ViewModels

```swift
final class ChatViewModel: ObservableObject {
    @Published var error: AppError?
    @Published var showError: Bool = false

    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            self.error = .network(networkError)
        } else if let repositoryError = error as? RepositoryError {
            self.error = .repository(repositoryError)
        } else {
            self.error = .unknown(error)
        }
        showError = true
    }
}
```

---

## 9. Testing Strategy

### Unit Testing

#### ViewModel Tests

```swift
import XCTest
import Combine
@testable import ShamelaGPT

final class ChatViewModelTests: XCTestCase {
    private var sut: ChatViewModel!
    private var mockSendMessageUseCase: MockSendMessageUseCase!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockSendMessageUseCase = MockSendMessageUseCase()
        sut = ChatViewModel(sendMessageUseCase: mockSendMessageUseCase)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockSendMessageUseCase = nil
        cancellables = nil
        super.tearDown()
    }

    func testSendMessage_Success() {
        // Given
        let expectation = XCTestExpectation(description: "Message sent successfully")
        let mockResponse = ChatResponse(answer: "Test answer", threadId: "123")
        mockSendMessageUseCase.result = .success(mockResponse)
        sut.inputText = "Test question"

        // When
        sut.sendMessage()

        // Then
        sut.$messages
            .dropFirst()
            .sink { messages in
                XCTAssertEqual(messages.count, 1)
                XCTAssertEqual(messages.first?.content, "Test answer")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }
}
```

#### Repository Tests

```swift
final class ChatRepositoryTests: XCTestCase {
    private var sut: ChatRepositoryImpl!
    private var mockRemoteDataSource: MockChatRemoteDataSource!
    private var mockLocalDataSource: MockChatLocalDataSource!

    override func setUp() {
        super.setUp()
        mockRemoteDataSource = MockChatRemoteDataSource()
        mockLocalDataSource = MockChatLocalDataSource()
        sut = ChatRepositoryImpl(
            remoteDataSource: mockRemoteDataSource,
            localDataSource: mockLocalDataSource
        )
    }

    // Test cases...
}
```

### UI Testing

```swift
final class ShamelaGPTUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }

    func testChatFlow() {
        // Test chat interaction
        let inputField = app.textFields["chatInput"]
        XCTAssertTrue(inputField.exists)

        inputField.tap()
        inputField.typeText("What is Islam?")

        let sendButton = app.buttons["sendButton"]
        sendButton.tap()

        // Wait for response
        let messageCell = app.staticTexts["messageCell"]
        XCTAssertTrue(messageCell.waitForExistence(timeout: 5))
    }
}
```

### Snapshot Testing

```swift
import SnapshotTesting

final class ChatViewSnapshotTests: XCTestCase {
    func testChatViewSnapshot() {
        let viewModel = ChatViewModel(
            sendMessageUseCase: MockSendMessageUseCase()
        )
        let view = ChatView(viewModel: viewModel)

        assertSnapshot(matching: view, as: .image)
    }
}
```

---

## 10. Third-Party Dependencies

### Swift Package Manager (SPM)

```swift
// Package.swift dependencies
dependencies: [
    // Dependency Injection
    .package(url: "https://github.com/Swinject/Swinject.git", from: "2.10.0"),

    // Chat UI (Optional)
    .package(url: "https://github.com/GetStream/stream-chat-swift.git", from: "5.0.0"),

    // Markdown Rendering
    .package(url: "https://github.com/gonzalezreal/swift-markdown-ui.git", from: "2.0.0"),

    // Testing
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.12.0"),
]
```

### Required Frameworks

- **SwiftUI**: UI framework
- **Combine**: Reactive programming
- **Core Data**: Local persistence
- **Foundation**: Networking (URLSession)
- **Speech**: Voice-to-text conversion
- **Vision**: OCR for images
- **AVFoundation**: Audio recording
- **UserNotifications**: Push notifications (future)

---

## Architecture Benefits

### ✅ Pros
1. **Testability**: Each layer can be tested independently
2. **Maintainability**: Clear separation of concerns
3. **Scalability**: Easy to add new features
4. **Reusability**: Components can be reused across screens
5. **SwiftUI Integration**: Native support for reactive programming
6. **Dependency Management**: Explicit dependencies via DI
7. **Navigation Control**: Centralized navigation logic

### ⚠️ Considerations
1. **Initial Setup**: More boilerplate code upfront
2. **Learning Curve**: Team needs to understand MVVM + Coordinator
3. **Swinject Overhead**: Small runtime overhead for DI resolution

---

## Future Enhancements

1. **Modularization**: Split into feature modules using Swift Packages
2. **Combine → Async/Await**: Migrate to modern concurrency (iOS 15+)
3. **SwiftData**: Replace Core Data with SwiftData (iOS 17+)
4. **TCA (The Composable Architecture)**: Consider for complex state management
5. **GraphQL**: If API evolves to GraphQL
6. **CloudKit Sync**: Sync conversations across devices

---

## Conclusion

This architecture provides a solid foundation for the ShamelaGPT iOS app, ensuring:
- Clean separation of concerns
- Testable code
- Maintainable and scalable codebase
- Native iOS patterns and best practices
- Ready for future feature additions

The MVVM + Coordinator pattern, combined with Core Data and Combine, creates a robust, production-ready architecture that follows Apple's recommended practices and modern iOS development standards.
