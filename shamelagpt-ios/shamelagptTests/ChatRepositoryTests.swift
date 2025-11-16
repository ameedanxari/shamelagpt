//
//  ChatRepositoryTests.swift
//  shamelagptTests
//
//  Tests for ChatRepository with in-memory Core Data
//

import XCTest
import CoreData
import Combine
@testable import ShamelaGPT

final class ChatRepositoryTests: XCTestCase {

    var sut: ChatRepositoryImpl!
    var testCoreDataStack: TestCoreDataStack!
    var conversationDAO: ConversationDAO!
    var messageDAO: MessageDAO!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        // Create in-memory Core Data stack for testing
        testCoreDataStack = TestCoreDataStack()
        conversationDAO = ConversationDAO()
        messageDAO = MessageDAO()

        // Create repository with test Core Data stack
        sut = ChatRepositoryImpl(
            coreDataStack: testCoreDataStack,
            conversationDAO: conversationDAO,
            messageDAO: messageDAO,
            apiClient: nil,
            networkMonitor: nil
        )

        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        cancellables = nil
        sut = nil
        messageDAO = nil
        conversationDAO = nil
        testCoreDataStack = nil
    }

    // MARK: - Conversation CRUD Tests

    func testCreateConversation() async throws {
        // When
        let conversation = try await sut.createConversation(title: "Test Conversation")

        // Then
        XCTAssertFalse(conversation.id.isEmpty, "Conversation should have an ID")
        XCTAssertEqual(conversation.title, "Test Conversation")
        XCTAssertNil(conversation.threadId, "New conversation should not have thread ID")
        XCTAssertTrue(conversation.messages.isEmpty, "New conversation should have no messages")
    }

    func testFetchConversationById() async throws {
        // Given
        let created = try await sut.createConversation(title: "Test")

        // When
        let fetched = try await sut.fetchConversation(byId: created.id)

        // Then
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, created.id)
        XCTAssertEqual(fetched?.title, "Test")
    }

    func testFetchConversationByThreadId() async throws {
        // Given
        let created = try await sut.createConversation(title: "Test")
        try await sut.updateConversationThreadId(id: created.id, threadId: "thread-123")

        // When
        let fetched = try await sut.fetchConversation(byThreadId: "thread-123")

        // Then
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, created.id)
        XCTAssertEqual(fetched?.threadId, "thread-123")
    }

    func testFetchAllConversations() async throws {
        // Given
        _ = try await sut.createConversation(title: "Conv 1")
        _ = try await sut.createConversation(title: "Conv 2")
        _ = try await sut.createConversation(title: "Conv 3")

        // When
        let conversations = try await sut.fetchAllConversations()

        // Then
        XCTAssertEqual(conversations.count, 3)
        XCTAssertTrue(conversations.contains(where: { $0.title == "Conv 1" }))
        XCTAssertTrue(conversations.contains(where: { $0.title == "Conv 2" }))
        XCTAssertTrue(conversations.contains(where: { $0.title == "Conv 3" }))
    }

    func testFetchMostRecentEmptyConversation() async throws {
        // Given - Create conversations with delays to ensure ordering
        _ = try await sut.createConversation(title: "Old Empty")
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        let conv2 = try await sut.createConversation(title: "Recent Empty")
        try await Task.sleep(nanoseconds: 100_000_000)

        let conv3 = try await sut.createConversation(title: "With Message")
        _ = try await sut.addMessage(
            toConversation: conv3.id,
            content: "Message",
            isUserMessage: true,
            sources: []
        )

        // When
        let mostRecent = try await sut.fetchMostRecentEmptyConversation()

        // Then
        XCTAssertNotNil(mostRecent)
        XCTAssertEqual(mostRecent?.id, conv2.id, "Should fetch most recent empty conversation")
    }

    func testUpdateConversationTitle() async throws {
        // Given
        let conversation = try await sut.createConversation(title: "Original Title")

        // When
        try await sut.updateConversationTitle(id: conversation.id, title: "Updated Title")

        // Then
        let fetched = try await sut.fetchConversation(byId: conversation.id)
        XCTAssertEqual(fetched?.title, "Updated Title")
    }

    func testCreateConversationPersistsRemoteTimestampsWithFractionalSeconds() async throws {
        // Given
        let apiClient = MockAPIClient()
        apiClient.mockCreateConversationResponse = ConversationResponse(
            id: "remote-id",
            threadId: "remote-thread",
            title: "Remote Title",
            createdAt: "2025-12-07T22:11:33.525593+00:00",
            updatedAt: "2025-12-07T22:15:33.125593+00:00"
        )
        let networkMonitor = MockNetworkMonitor()
        let repository = ChatRepositoryImpl(
            coreDataStack: testCoreDataStack,
            conversationDAO: conversationDAO,
            messageDAO: messageDAO,
            apiClient: apiClient,
            networkMonitor: networkMonitor
        )
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // When
        let conversation = try await repository.createConversation(title: "Ignored Local Title")
        let fetched = try await repository.fetchConversation(byId: conversation.id)

        // Then
        XCTAssertEqual(conversation.id, "remote-id")
        XCTAssertEqual(fetched?.createdAt, formatter.date(from: "2025-12-07T22:11:33.525593+00:00"))
        XCTAssertEqual(fetched?.updatedAt, formatter.date(from: "2025-12-07T22:15:33.125593+00:00"))
    }

    func testUpdateConversationThreadId() async throws {
        // Given
        let conversation = try await sut.createConversation(title: "Test")

        // When
        try await sut.updateConversationThreadId(id: conversation.id, threadId: "thread-456")

        // Then
        let fetched = try await sut.fetchConversation(byId: conversation.id)
        XCTAssertEqual(fetched?.threadId, "thread-456")
    }

    func testDeleteConversation() async throws {
        // Given
        let conversation = try await sut.createConversation(title: "To Delete")

        // When
        try await sut.deleteConversation(id: conversation.id)

        // Then
        let fetched = try await sut.fetchConversation(byId: conversation.id)
        XCTAssertNil(fetched, "Deleted conversation should not be found")
    }

    func testDeleteAllConversations() async throws {
        // Given
        _ = try await sut.createConversation(title: "Conv 1")
        _ = try await sut.createConversation(title: "Conv 2")
        _ = try await sut.createConversation(title: "Conv 3")

        // When
        try await sut.deleteAllConversations()

        // Then
        let conversations = try await sut.fetchAllConversations()
        XCTAssertTrue(conversations.isEmpty, "All conversations should be deleted")
    }

    // MARK: - Message CRUD Tests

    func testAddMessageToConversation() async throws {
        // Given
        let conversation = try await sut.createConversation(title: "Test")

        // When
        let message = try await sut.addMessage(
            toConversation: conversation.id,
            content: "Hello, world!",
            isUserMessage: true,
            sources: []
        )

        // Then
        XCTAssertFalse(message.id.isEmpty)
        XCTAssertEqual(message.content, "Hello, world!")
        XCTAssertTrue(message.isUserMessage)
        XCTAssertTrue(message.sources.isEmpty)
        XCTAssertNotNil(message.timestamp)
    }

    func testAddFactCheckMessage() async throws {
        // Given
        let conversation = try await sut.createConversation(title: "Test")
        let imageData = "test image data".data(using: .utf8)
        let source = Source(
            bookTitle: "Test Book",
            volumeNumber: 1,
            pageNumber: 10,
            text: "Sample text",
            sourceUrl: "https://example.com"
        )

        // When
        let message = try await sut.addFactCheckMessage(
            toConversation: conversation.id,
            content: "Fact-check this",
            isUserMessage: true,
            sources: [source],
            imageData: imageData,
            detectedLanguage: "ar",
            isFactCheckMessage: true
        )

        // Then
        XCTAssertEqual(message.content, "Fact-check this")
        XCTAssertTrue(message.isUserMessage)
        XCTAssertEqual(message.sources.count, 1)
        XCTAssertNotNil(message.imageData)
        XCTAssertEqual(message.detectedLanguage, "ar")
        XCTAssertTrue(message.isFactCheckMessage)
    }

    func testFetchMessagesForConversation() async throws {
        // Given
        let conversation = try await sut.createConversation(title: "Test")
        _ = try await sut.addMessage(
            toConversation: conversation.id,
            content: "Message 1",
            isUserMessage: true,
            sources: []
        )
        _ = try await sut.addMessage(
            toConversation: conversation.id,
            content: "Message 2",
            isUserMessage: false,
            sources: []
        )

        // When
        let messages = try await sut.fetchMessages(forConversation: conversation.id)

        // Then
        XCTAssertEqual(messages.count, 2)
        XCTAssertTrue(messages.contains(where: { $0.content == "Message 1" }))
        XCTAssertTrue(messages.contains(where: { $0.content == "Message 2" }))
    }

    func testFetchMessagesOrderedByTimestamp() async throws {
        // Given
        let conversation = try await sut.createConversation(title: "Test")

        let msg1 = try await sut.addMessage(
            toConversation: conversation.id,
            content: "First",
            isUserMessage: true,
            sources: []
        )

        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay

        let msg2 = try await sut.addMessage(
            toConversation: conversation.id,
            content: "Second",
            isUserMessage: false,
            sources: []
        )

        // When
        let messages = try await sut.fetchMessages(forConversation: conversation.id)

        // Then
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].id, msg1.id, "First message should be first")
        XCTAssertEqual(messages[1].id, msg2.id, "Second message should be second")
        XCTAssertTrue(messages[0].timestamp <= messages[1].timestamp, "Messages should be ordered by timestamp")
    }

    func testUpdateMessageContent() async throws {
        // Given
        let conversation = try await sut.createConversation(title: "Test")
        let message = try await sut.addMessage(
            toConversation: conversation.id,
            content: "Original content",
            isUserMessage: true,
            sources: []
        )

        // When
        try await sut.updateMessageContent(id: message.id, content: "Updated content")

        // Then
        let messages = try await sut.fetchMessages(forConversation: conversation.id)
        XCTAssertEqual(messages.first?.content, "Updated content")
    }

    func testDeleteMessage() async throws {
        // Given
        let conversation = try await sut.createConversation(title: "Test")
        let message = try await sut.addMessage(
            toConversation: conversation.id,
            content: "To delete",
            isUserMessage: true,
            sources: []
        )

        // When
        try await sut.deleteMessage(id: message.id)

        // Then
        let messages = try await sut.fetchMessages(forConversation: conversation.id)
        XCTAssertTrue(messages.isEmpty, "Message should be deleted")
    }

    func testDeleteMessageCascadesFromConversation() async throws {
        // Given
        let conversation = try await sut.createConversation(title: "Test")
        _ = try await sut.addMessage(
            toConversation: conversation.id,
            content: "Message 1",
            isUserMessage: true,
            sources: []
        )
        _ = try await sut.addMessage(
            toConversation: conversation.id,
            content: "Message 2",
            isUserMessage: false,
            sources: []
        )

        // When - Delete the conversation
        try await sut.deleteConversation(id: conversation.id)

        // Then - Messages should be deleted too (cascade delete)
        let messages = try await sut.fetchMessages(forConversation: conversation.id)
        XCTAssertTrue(messages.isEmpty, "Messages should be cascade deleted with conversation")
    }

    // MARK: - Publisher Tests

    func testConversationsPublisherEmitsUpdates() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Publisher emits update")
        var receivedConversations: [[Conversation]] = []

        sut.conversationsPublisher
            .dropFirst() // Skip initial empty state
            .sink { conversations in
                receivedConversations.append(conversations)
                if !conversations.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        _ = try await sut.createConversation(title: "New Conversation")

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(receivedConversations.isEmpty, "Publisher should emit updates")
        XCTAssertEqual(receivedConversations.last?.count, 1)
    }

    func testConversationsPublisherOnCreate() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Publisher emits on create")

        sut.conversationsPublisher
            .dropFirst()
            .sink { conversations in
                if conversations.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        _ = try await sut.createConversation(title: "Test")

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testConversationsPublisherOnDelete() async throws {
        // Given
        let conversation = try await sut.createConversation(title: "To Delete")

        let expectation = XCTestExpectation(description: "Publisher emits on delete")

        sut.conversationsPublisher
            .dropFirst() // Skip initial state
            .sink { conversations in
                if conversations.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        try await sut.deleteConversation(id: conversation.id)

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testConversationsPublisherOnUpdate() async throws {
        // Given
        let conversation = try await sut.createConversation(title: "Original")

        let expectation = XCTestExpectation(description: "Publisher emits on update")

        sut.conversationsPublisher
            .dropFirst() // Skip initial state
            .sink { conversations in
                if let updated = conversations.first, updated.title == "Updated" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        try await sut.updateConversationTitle(id: conversation.id, title: "Updated")

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Error Cases

    func testFetchConversationNotFound() async throws {
        // When
        let conversation = try await sut.fetchConversation(byId: "non-existent-id")

        // Then
        XCTAssertNil(conversation, "Should return nil for non-existent conversation")
    }

    func testUpdateNonExistentConversation() async throws {
        // When/Then
        do {
            try await sut.updateConversationTitle(id: "non-existent", title: "Updated")
            XCTFail("Should throw error when updating non-existent conversation")
        } catch let error as CoreDataError {
            XCTAssertEqual(error, CoreDataError.notFound)
        } catch {
            XCTFail("Should throw CoreDataError.notFound, got: \(error)")
        }
    }

    func testDeleteNonExistentConversation() async throws {
        // When/Then
        do {
            try await sut.deleteConversation(id: "non-existent")
            XCTFail("Should throw CoreDataError.notFound when deleting non-existent conversation")
        } catch let error as CoreDataError {
            XCTAssertEqual(error, CoreDataError.notFound)
        } catch {
            XCTFail("Should throw CoreDataError.notFound, got: \(error)")
        }
    }

    func testAddMessageToNonExistentConversation() async throws {
        // When/Then
        do {
            _ = try await sut.addMessage(
                toConversation: "non-existent",
                content: "Test",
                isUserMessage: true,
                sources: []
            )
            XCTFail("Should throw error when adding message to non-existent conversation")
        } catch let error as CoreDataError {
            XCTAssertEqual(error, CoreDataError.notFound)
        } catch {
            XCTFail("Should throw CoreDataError.notFound, got: \(error)")
        }
    }
}

// MARK: - Test Core Data Stack

/// In-memory Core Data stack for testing
final class TestCoreDataStack: @unchecked Sendable, CoreDataStackProtocol {

    private let inMemoryContainer: NSPersistentContainer

    init() {
        let container = NSPersistentContainer(name: "ShamelaGPT")

        // Use in-memory store for testing
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Failed to load in-memory store: \(error)")
            }

            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }

        self.inMemoryContainer = container
    }

    var viewContext: NSManagedObjectContext {
        return inMemoryContainer.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = inMemoryContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        inMemoryContainer.performBackgroundTask(block)
    }
    
    func saveContext() throws {
        try save(context: viewContext)
    }
    
    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed(error)
        }
    }
    
    func deleteAllData() throws {
        let entities = inMemoryContainer.managedObjectModel.entities
        
        for entity in entities {
            guard let entityName = entity.name else { continue }
            
            do {
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
                let objects = try viewContext.fetch(fetchRequest)
                objects.forEach { viewContext.delete($0) }
                try saveContext()
            } catch {
                throw CoreDataError.deleteFailed(error)
            }
        }
    }
}
