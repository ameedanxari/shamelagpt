//
//  HistoryViewModelTests.swift
//  shamelagptTests
//
//  Tests for HistoryViewModel
//

import XCTest
import Combine
@testable import ShamelaGPT

@MainActor
final class HistoryViewModelTests: XCTestCase {

    var viewModel: HistoryViewModel!
    var mockGetConversationsUseCase: MockGetConversationsUseCase!
    var mockDeleteConversationUseCase: MockDeleteConversationUseCase!
    var mockChatRepository: MockChatRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        mockGetConversationsUseCase = MockGetConversationsUseCase()
        mockDeleteConversationUseCase = MockDeleteConversationUseCase()
        mockChatRepository = MockChatRepository()
        cancellables = Set<AnyCancellable>()

        viewModel = HistoryViewModel(
            getConversationsUseCase: mockGetConversationsUseCase,
            deleteConversationUseCase: mockDeleteConversationUseCase,
            chatRepository: mockChatRepository
        )
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockGetConversationsUseCase = nil
        mockDeleteConversationUseCase = nil
        mockChatRepository = nil
        cancellables = nil
    }

    // MARK: - Conversation Loading Tests

    func testLoadConversationsSuccess() async throws {
        // Given
        let conv1 = Conversation(
            id: "1",
            title: "First Conversation",
            updatedAt: Date().addingTimeInterval(-3600), // 1 hour ago
            messages: [Message.preview]
        )
        let conv2 = Conversation(
            id: "2",
            title: "Second Conversation",
            updatedAt: Date(), // now
            messages: [Message.previewAssistant]
        )
        mockGetConversationsUseCase.mockConversations = [conv1, conv2]

        // When
        viewModel.loadConversations()

        // Give time for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        XCTAssertEqual(viewModel.conversations.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(mockGetConversationsUseCase.executeCallCount, 1)
    }

    func testLoadConversationsIncludesEmptyConversations() async throws {
        // Given
        let conv1 = Conversation(
            id: "1",
            title: "Conversation with messages",
            messages: [Message.preview]
        )
        let localEmpty = Conversation(
            id: "2",
            title: "Empty Local Conversation",
            messages: [],
            isLocalOnly: true
        )
        let conv3 = Conversation(
            id: "3",
            title: "Another with messages",
            messages: [Message.previewAssistant]
        )
        mockGetConversationsUseCase.mockConversations = [conv1, localEmpty, conv3]

        // When
        viewModel.loadConversations()

        // Give time for async operation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - empty conversations should remain (includeLocalOnly defaults to true)
        XCTAssertEqual(viewModel.conversations.count, 3, "Empty conversations should not be filtered out")
        XCTAssertTrue(viewModel.conversations.contains { $0.id == "2" }, "Empty conversation should be present")
    }

    func testLoadConversationsWithError() async throws {
        // Given
        mockGetConversationsUseCase.shouldThrowError = true
        mockGetConversationsUseCase.errorToThrow = NSError(
            domain: "test",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Database error"]
        )

        // When
        viewModel.loadConversations()

        // Give time for async operation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, NSLocalizedString(LocalizationKeys.historyLoadFailed, comment: ""))
    }

    func testLoadConversationsOrderedByUpdatedAt() async throws {
        // Given - Create conversations with different timestamps
        let oldDate = Date().addingTimeInterval(-86400) // 1 day ago
        let middleDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let recentDate = Date() // now

        let conv1 = Conversation(
            id: "1",
            title: "Old",
            updatedAt: oldDate,
            messages: [Message.preview]
        )
        let conv2 = Conversation(
            id: "2",
            title: "Recent",
            updatedAt: recentDate,
            messages: [Message.preview]
        )
        let conv3 = Conversation(
            id: "3",
            title: "Middle",
            updatedAt: middleDate,
            messages: [Message.preview]
        )

        mockGetConversationsUseCase.mockConversations = [conv1, conv2, conv3]

        // When
        viewModel.loadConversations()

        // Give time for async operation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then - should be sorted by most recent first
        XCTAssertEqual(viewModel.conversations.count, 3)
        XCTAssertEqual(viewModel.conversations[0].id, "2") // Most recent
        XCTAssertEqual(viewModel.conversations[1].id, "3") // Middle
        XCTAssertEqual(viewModel.conversations[2].id, "1") // Oldest
    }

    func testConversationObserverUpdatesInRealTime() async throws {
        // Given - Setup initial conversations
        let conv1 = Conversation(
            id: "1",
            title: "First",
            messages: [Message.preview]
        )
        mockGetConversationsUseCase.mockConversations = [conv1]

        // When - ViewModel is initialized (setupConversationObserver is called)
        // The observer should be called during initialization
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockGetConversationsUseCase.observeConversationsCallCount, 1)
        // Note: The actual update happens through the publisher
        // which is configured in setupConversationObserver
    }

    // MARK: - Conversation Deletion Tests

    func testRequestDeleteShowsConfirmation() throws {
        // Given
        let conversation = Conversation(
            id: "1",
            title: "Test",
            messages: [Message.preview]
        )

        // When
        viewModel.requestDelete(conversation)

        // Then
        XCTAssertTrue(viewModel.showDeleteConfirmation)
        XCTAssertEqual(viewModel.conversationToDelete?.id, conversation.id)
    }

    func testConfirmDeleteRemovesConversation() async throws {
        // Given
        let conversation = Conversation(
            id: "test-id",
            title: "Test",
            messages: [Message.preview]
        )
        viewModel.conversationToDelete = conversation
        viewModel.showDeleteConfirmation = true

        // When
        viewModel.confirmDelete()

        // Give time for async operation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockDeleteConversationUseCase.executeCallCount, 1)
        XCTAssertEqual(mockDeleteConversationUseCase.lastDeletedId, "test-id")
        XCTAssertFalse(viewModel.showDeleteConfirmation)
        XCTAssertNil(viewModel.conversationToDelete)
        XCTAssertNil(viewModel.error)
    }

    func testCancelDeleteClearsState() throws {
        // Given
        let conversation = Conversation(
            id: "1",
            title: "Test",
            messages: [Message.preview]
        )
        viewModel.conversationToDelete = conversation
        viewModel.showDeleteConfirmation = true

        // When
        viewModel.cancelDelete()

        // Then
        XCTAssertFalse(viewModel.showDeleteConfirmation)
        XCTAssertNil(viewModel.conversationToDelete)
        XCTAssertEqual(mockDeleteConversationUseCase.executeCallCount, 0)
    }

    func testDeleteConversationWithError() async throws {
        // Given
        let conversation = Conversation(
            id: "test-id",
            title: "Test",
            messages: [Message.preview]
        )
        viewModel.conversationToDelete = conversation
        viewModel.showDeleteConfirmation = true

        mockDeleteConversationUseCase.shouldThrowError = true
        mockDeleteConversationUseCase.errorToThrow = NSError(
            domain: "test",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Delete failed"]
        )

        // When
        viewModel.confirmDelete()

        // Give time for async operation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, NSLocalizedString(LocalizationKeys.historyDeleteFailed, comment: ""))
        XCTAssertFalse(viewModel.showDeleteConfirmation)
        XCTAssertNil(viewModel.conversationToDelete)
    }

    func testDeleteAllConversationsSuccess() async throws {
        // Given
        mockDeleteConversationUseCase.shouldThrowError = false

        // When
        viewModel.deleteAllConversations()

        // Give time for async operation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockDeleteConversationUseCase.executeDeleteAllCallCount, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testDeleteAllConversationsWithError() async throws {
        // Given
        mockDeleteConversationUseCase.shouldThrowError = true
        mockDeleteConversationUseCase.errorToThrow = NSError(
            domain: "test",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Delete all failed"]
        )

        // When
        viewModel.deleteAllConversations()

        // Give time for async operation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, NSLocalizedString(LocalizationKeys.historyDeleteAllFailed, comment: ""))
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Display Logic Tests

    func testDisplayTitleForConversationWithTitle() throws {
        // Given
        let conversation = Conversation(
            id: "1",
            title: "Custom Title",
            messages: [Message.preview]
        )

        // When
        let displayTitle = viewModel.displayTitle(for: conversation)

        // Then
        XCTAssertEqual(displayTitle, "Custom Title")
    }

    func testDisplayTitleForEmptyTitle() throws {
        // Given
        let userMessage = Message(
            id: "1",
            conversationId: "conv-1",
            content: "What is the meaning of life?",
            isUserMessage: true,
            timestamp: Date(),
            sources: []
        )
        let conversation = Conversation(
            id: "1",
            title: "",
            messages: [userMessage]
        )

        // When
        let displayTitle = viewModel.displayTitle(for: conversation)

        // Then - should generate title from first user message
        XCTAssertEqual(displayTitle, "What is the meaning of life?")
    }

    func testDisplayTitleGeneratedFromFirstMessage() throws {
        // Given
        let userMessage = Message(
            id: "1",
            conversationId: "conv-1",
            content: "This is a very long message that should be truncated because it exceeds fifty characters limit",
            isUserMessage: true,
            timestamp: Date(),
            sources: []
        )
        let conversation = Conversation(
            id: "1",
            title: "New Conversation",
            messages: [userMessage]
        )

        // When
        let displayTitle = viewModel.displayTitle(for: conversation)

        // Then - should be truncated to 50 characters + "..." = 53 total
        XCTAssertEqual(displayTitle.count, 53)
        XCTAssertTrue(displayTitle.starts(with: "This is a very long message"))
    }

    func testMessagePreviewForConversationWithMessages() throws {
        // Given
        let message = Message(
            id: "1",
            conversationId: "conv-1",
            content: "Last message content",
            isUserMessage: true,
            timestamp: Date(),
            sources: []
        )
        let conversation = Conversation(
            id: "1",
            title: "Test",
            messages: [Message.preview, message]
        )

        // When
        let preview = viewModel.messagePreview(for: conversation)

        // Then - should return preview from conversation (last message)
        XCTAssertEqual(preview, "Last message content")
    }

    func testMessagePreviewForEmptyConversation() throws {
        // Given
        let conversation = Conversation(
            id: "1",
            title: "Test",
            messages: []
        )

        // When
        let preview = viewModel.messagePreview(for: conversation)

        // Then
        XCTAssertEqual(preview, "No messages")
    }

    func testRelativeTimeForRecentConversation() throws {
        // Given
        let conversation = Conversation(
            id: "1",
            title: "Test",
            updatedAt: Date(), // now
            messages: [Message.preview]
        )

        // When
        let relativeTime = viewModel.relativeTime(for: conversation)

        // Then - should show as recent (just now, or similar)
        XCTAssertFalse(relativeTime.isEmpty)
        // Note: Exact string depends on Date extension implementation
    }

    func testRelativeTimeForOldConversation() throws {
        // Given
        let oldDate = Date().addingTimeInterval(-86400 * 7) // 1 week ago
        let conversation = Conversation(
            id: "1",
            title: "Test",
            updatedAt: oldDate,
            messages: [Message.preview]
        )

        // When
        let relativeTime = viewModel.relativeTime(for: conversation)

        // Then - should show appropriate time string
        XCTAssertFalse(relativeTime.isEmpty)
    }

    // MARK: - Export Tests

    func testExportConversationFormatting() throws {
        // Given
        let userMsg = Message(
            id: "1",
            conversationId: "conv-1",
            content: "User question",
            isUserMessage: true,
            timestamp: Date(),
            sources: []
        )
        let assistantMsg = Message(
            id: "2",
            conversationId: "conv-1",
            content: "Assistant answer",
            isUserMessage: false,
            timestamp: Date(),
            sources: []
        )
        let conversation = Conversation(
            id: "1",
            title: "Export Test",
            messages: [userMsg, assistantMsg]
        )

        // When
        let exportedText = viewModel.exportConversation(conversation)

        // Then
        XCTAssertTrue(exportedText.contains("ShamelaGPT Chat: Export Test"))
        XCTAssertTrue(exportedText.contains("Link:"))
        XCTAssertTrue(exportedText.contains("Last updated:"))
        XCTAssertTrue(exportedText.contains("Preview:"))
        XCTAssertTrue(exportedText.contains("Assistant answer"))
    }

    func testExportConversationWithSources() throws {
        // Given
        let source = Source(
            bookTitle: "Test Book",
            author: "Test Author",
            volumeNumber: 1,
            pageNumber: 10,
            text: "Test text",
            sourceUrl: "https://example.com"
        )
        let assistantMsg = Message(
            id: "1",
            conversationId: "conv-1",
            content: "Answer with source",
            isUserMessage: false,
            timestamp: Date(),
            sources: [source]
        )
        let conversation = Conversation(
            id: "1",
            title: "Export Test",
            messages: [assistantMsg]
        )

        // When
        let exportedText = viewModel.exportConversation(conversation)

        // Then
        XCTAssertTrue(exportedText.contains("ShamelaGPT Chat: Export Test"))
        XCTAssertTrue(exportedText.contains("Answer with source"))
    }

    func testExportEmptyConversation() throws {
        // Given
        let conversation = Conversation(
            id: "1",
            title: "Empty Conversation",
            messages: []
        )

        // When
        let exportedText = viewModel.exportConversation(conversation)

        // Then
        XCTAssertTrue(exportedText.contains("ShamelaGPT Chat: Empty Conversation"))
        XCTAssertTrue(exportedText.contains("Link:"))
        XCTAssertTrue(exportedText.contains("Last updated:"))
        XCTAssertTrue(exportedText.contains("Preview:"))
        XCTAssertTrue(exportedText.contains("No messages"))
    }

    // MARK: - Helper Method Tests

    func testGenerateTitleFromMessage() throws {
        // Given
        let message = "What is the ruling on fasting?"

        // When
        let title = viewModel.generateTitle(from: message)

        // Then
        XCTAssertEqual(title, "What is the ruling on fasting?")
    }

    func testGenerateTitleTruncatesLongMessage() throws {
        // Given
        let longMessage = String(repeating: "a", count: 100)

        // When
        let title = viewModel.generateTitle(from: longMessage)

        // Then
        XCTAssertEqual(title.count, 53)
    }

    func testGenerateTitleFromEmptyMessage() throws {
        // Given
        let emptyMessage = "   "

        // When
        let title = viewModel.generateTitle(from: emptyMessage)

        // Then
        XCTAssertEqual(title, "New Conversation")
    }
}
