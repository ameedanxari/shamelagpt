//
//  ModelTests.swift
//  shamelagptTests
//
//  Tests for domain models: Message, Conversation, Source
//

import XCTest
@testable import ShamelaGPT

final class ModelTests: XCTestCase {

    // MARK: - Message Model Tests

    func testMessageEquality() throws {
        // Given
        let timestamp = Date()

        let message1 = Message(
            id: "msg-1",
            conversationId: "conv-1",
            content: "Hello",
            isUserMessage: true,
            timestamp: timestamp
        )

        let message2 = Message(
            id: "msg-1",
            conversationId: "conv-1",
            content: "Hello",
            isUserMessage: true,
            timestamp: timestamp
        )

        let message3 = Message(
            id: "msg-2",
            conversationId: "conv-1",
            content: "Hello",
            isUserMessage: true,
            timestamp: timestamp
        )

        // Then
        XCTAssertEqual(message1, message2, "Messages with same properties should be equal")
        XCTAssertNotEqual(message1, message3, "Messages with different IDs should not be equal")
    }

    func testMessageIsAssistantMessage() throws {
        // Given
        let userMessage = Message(
            conversationId: "conv-1",
            content: "Question",
            isUserMessage: true
        )

        let assistantMessage = Message(
            conversationId: "conv-1",
            content: "Answer",
            isUserMessage: false
        )

        // Then
        XCTAssertFalse(userMessage.isAssistantMessage, "User message should return false")
        XCTAssertTrue(assistantMessage.isAssistantMessage, "Assistant message should return true")
    }

    func testMessageHasSources() throws {
        // Given
        let messageWithoutSources = Message(
            conversationId: "conv-1",
            content: "No sources",
            isUserMessage: false,
            sources: []
        )

        let messageWithSources = Message(
            conversationId: "conv-1",
            content: "With sources",
            isUserMessage: false,
            sources: [Source.preview]
        )

        // Then
        XCTAssertFalse(messageWithoutSources.hasSources, "Should return false when no sources")
        XCTAssertTrue(messageWithSources.hasSources, "Should return true when sources present")
    }

    func testMessageLanguageDisplayName() throws {
        // Given
        let messageWithArabic = Message(
            conversationId: "conv-1",
            content: "Test",
            isUserMessage: true,
            detectedLanguage: "ar"
        )

        let messageWithEnglish = Message(
            conversationId: "conv-1",
            content: "Test",
            isUserMessage: true,
            detectedLanguage: "en"
        )

        let messageWithoutLanguage = Message(
            conversationId: "conv-1",
            content: "Test",
            isUserMessage: true,
            detectedLanguage: nil
        )

        // Then
        XCTAssertNotNil(messageWithArabic.languageDisplayName)
        XCTAssertNotNil(messageWithEnglish.languageDisplayName)
        XCTAssertNil(messageWithoutLanguage.languageDisplayName, "Should return nil when no language detected")
    }

    func testMessageInitWithDefaults() throws {
        // When
        let message = Message(
            conversationId: "conv-1",
            content: "Test message",
            isUserMessage: true
        )

        // Then
        XCTAssertFalse(message.id.isEmpty, "Should generate UUID for ID")
        XCTAssertEqual(message.conversationId, "conv-1")
        XCTAssertEqual(message.content, "Test message")
        XCTAssertTrue(message.isUserMessage)
        XCTAssertNotNil(message.timestamp, "Should have default timestamp")
        XCTAssertTrue(message.sources.isEmpty, "Should have empty sources by default")
        XCTAssertNil(message.imageData, "Should have nil imageData by default")
        XCTAssertNil(message.detectedLanguage, "Should have nil detectedLanguage by default")
        XCTAssertFalse(message.isFactCheckMessage, "Should be false by default")
    }

    func testMessageFactCheckProperties() throws {
        // Given
        let imageData = "test image".data(using: .utf8)

        // When
        let factCheckMessage = Message(
            conversationId: "conv-1",
            content: "Fact check this",
            isUserMessage: true,
            imageData: imageData,
            detectedLanguage: "ar",
            isFactCheckMessage: true
        )

        // Then
        XCTAssertEqual(factCheckMessage.imageData, imageData)
        XCTAssertEqual(factCheckMessage.detectedLanguage, "ar")
        XCTAssertTrue(factCheckMessage.isFactCheckMessage)
    }

    // MARK: - Conversation Model Tests

    func testConversationLastMessage() throws {
        // Given
        let msg1 = Message(conversationId: "conv-1", content: "First", isUserMessage: true)
        let msg2 = Message(conversationId: "conv-1", content: "Second", isUserMessage: false)

        let conversation = Conversation(
            title: "Test",
            messages: [msg1, msg2]
        )

        let emptyConversation = Conversation(
            title: "Empty",
            messages: []
        )

        // Then
        XCTAssertEqual(conversation.lastMessage?.content, "Second", "Should return last message")
        XCTAssertNil(emptyConversation.lastMessage, "Should return nil for empty conversation")
    }

    func testConversationMessageCount() throws {
        // Given
        let messages = [
            Message(conversationId: "conv-1", content: "1", isUserMessage: true),
            Message(conversationId: "conv-1", content: "2", isUserMessage: false),
            Message(conversationId: "conv-1", content: "3", isUserMessage: true)
        ]

        let conversation = Conversation(title: "Test", messages: messages)
        let emptyConversation = Conversation(title: "Empty", messages: [])

        // Then
        XCTAssertEqual(conversation.messageCount, 3)
        XCTAssertEqual(emptyConversation.messageCount, 0)
    }

    func testConversationHasMessages() throws {
        // Given
        let withMessages = Conversation(
            title: "Test",
            messages: [Message(conversationId: "conv-1", content: "Hello", isUserMessage: true)]
        )

        let withoutMessages = Conversation(
            title: "Empty",
            messages: []
        )

        // Then
        XCTAssertTrue(withMessages.hasMessages)
        XCTAssertFalse(withoutMessages.hasMessages)
    }

    func testConversationPreview() throws {
        // Given
        let shortMessage = Message(
            conversationId: "conv-1",
            content: "Short message",
            isUserMessage: true
        )

        let longMessage = Message(
            conversationId: "conv-1",
            content: String(repeating: "a", count: 150),
            isUserMessage: true
        )

        let convWithShort = Conversation(title: "Test", messages: [shortMessage])
        let convWithLong = Conversation(title: "Test", messages: [longMessage])
        let convEmpty = Conversation(title: "Test", messages: [])

        // Then
        XCTAssertEqual(convWithShort.previewText, "Short message", "Should return full content when short")
        XCTAssertTrue(convWithLong.previewText.hasSuffix("..."), "Should truncate long messages")
        XCTAssertEqual(convWithLong.previewText.count, 103, "Should truncate to 100 chars + '...'")
        XCTAssertEqual(convEmpty.previewText, "No messages", "Should return default for empty conversation")
    }

    func testConversationWithMessages() throws {
        // Given
        let originalMessages = [
            Message(conversationId: "conv-1", content: "Original", isUserMessage: true)
        ]

        let newMessages = [
            Message(conversationId: "conv-1", content: "New 1", isUserMessage: true),
            Message(conversationId: "conv-1", content: "New 2", isUserMessage: false)
        ]

        let conversation = Conversation(
            id: "conv-1",
            threadId: "thread-1",
            title: "Test",
            messages: originalMessages
        )

        // When
        let updated = conversation.withMessages(newMessages)

        // Then
        XCTAssertEqual(updated.id, conversation.id, "Should preserve ID")
        XCTAssertEqual(updated.threadId, conversation.threadId, "Should preserve thread ID")
        XCTAssertEqual(updated.title, conversation.title, "Should preserve title")
        XCTAssertEqual(updated.messages.count, 2, "Should have new messages")
        XCTAssertEqual(updated.messages[0].content, "New 1")
        XCTAssertEqual(updated.messages[1].content, "New 2")
    }

    func testConversationWithTitle() throws {
        // Given
        let conversation = Conversation(
            id: "conv-1",
            threadId: "thread-1",
            title: "Original Title",
            messages: []
        )

        // When
        let updated = conversation.withTitle("New Title")

        // Then
        XCTAssertEqual(updated.id, conversation.id, "Should preserve ID")
        XCTAssertEqual(updated.threadId, conversation.threadId, "Should preserve thread ID")
        XCTAssertEqual(updated.title, "New Title", "Should have new title")
        XCTAssertEqual(updated.messages, conversation.messages, "Should preserve messages")
    }

    func testConversationWithConversationType() throws {
        // Given
        let conversation = Conversation(
            id: "conv-1",
            title: "Test",
            conversationType: .regular
        )

        // When
        let updated = conversation.withConversationType(.factCheck)

        // Then
        XCTAssertEqual(updated.id, conversation.id, "Should preserve ID")
        XCTAssertEqual(updated.title, conversation.title, "Should preserve title")
        XCTAssertEqual(updated.conversationType, .factCheck, "Should have new conversation type")
    }

    func testConversationTypeEquality() throws {
        // Then
        XCTAssertEqual(ConversationType.regular, ConversationType.regular)
        XCTAssertEqual(ConversationType.factCheck, ConversationType.factCheck)
        XCTAssertNotEqual(ConversationType.regular, ConversationType.factCheck)
    }

    func testConversationInitWithDefaults() throws {
        // When
        let conversation = Conversation(title: "Test")

        // Then
        XCTAssertFalse(conversation.id.isEmpty, "Should generate UUID for ID")
        XCTAssertNil(conversation.threadId, "Should have nil threadId by default")
        XCTAssertEqual(conversation.title, "Test")
        XCTAssertNotNil(conversation.createdAt, "Should have default createdAt")
        XCTAssertNotNil(conversation.updatedAt, "Should have default updatedAt")
        XCTAssertTrue(conversation.messages.isEmpty, "Should have empty messages by default")
        XCTAssertEqual(conversation.conversationType, .regular, "Should be regular type by default")
    }

    // MARK: - Source Model Tests

    func testSourceCitationFormatting() throws {
        // Given
        let source = Source(
            bookTitle: "صحيح البخاري",
            author: "محمد بن إسماعيل البخاري",
            volumeNumber: 1,
            pageNumber: 52,
            text: "Sample text"
        )

        // When
        let citation = source.citation

        // Then
        XCTAssertTrue(citation.contains("صحيح البخاري"), "Should contain book title")
        XCTAssertTrue(citation.contains("محمد بن إسماعيل البخاري"), "Should contain author")
        XCTAssertTrue(citation.contains("1/52"), "Should contain volume/page in format 'volume/page'")
    }

    func testSourceCitationWithoutAuthor() throws {
        // Given
        let source = Source(
            bookTitle: "Book Title",
            author: nil,
            volumeNumber: 2,
            pageNumber: 100,
            text: "Sample text"
        )

        // When
        let citation = source.citation

        // Then
        XCTAssertTrue(citation.contains("Book Title"), "Should contain book title")
        XCTAssertFalse(citation.contains("nil"), "Should not contain 'nil' string")
        XCTAssertTrue(citation.contains("2/100"), "Should contain volume/page")
    }

    func testSourceCitationWithPageOnly() throws {
        // Given
        let source = Source(
            bookTitle: "Book Title",
            author: "Author Name",
            volumeNumber: nil,
            pageNumber: 42,
            text: "Sample text"
        )

        // When
        let citation = source.citation

        // Then
        XCTAssertTrue(citation.contains("Book Title"), "Should contain book title")
        XCTAssertTrue(citation.contains("Author Name"), "Should contain author")
        XCTAssertTrue(citation.contains("p. 42"), "Should format page as 'p. 42'")
    }

    func testSourceCitationWithVolumeAndPage() throws {
        // Given
        let source = Source(
            bookTitle: "Multi-Volume Work",
            author: "Scholar Name",
            volumeNumber: 3,
            pageNumber: 215,
            text: "Sample text"
        )

        // When
        let citation = source.citation

        // Then
        XCTAssertTrue(citation.contains("Multi-Volume Work"), "Should contain book title")
        XCTAssertTrue(citation.contains("Scholar Name"), "Should contain author")
        XCTAssertTrue(citation.contains("3/215"), "Should format as 'volume/page'")
    }

    func testSourceCitationWithNoVolumeOrPage() throws {
        // Given
        let source = Source(
            bookTitle: "Book Title",
            author: "Author Name",
            volumeNumber: nil,
            pageNumber: nil,
            text: "Sample text"
        )

        // When
        let citation = source.citation

        // Then
        XCTAssertTrue(citation.contains("Book Title"), "Should contain book title")
        XCTAssertTrue(citation.contains("Author Name"), "Should contain author")
        XCTAssertFalse(citation.contains("p."), "Should not contain page prefix")
        XCTAssertFalse(citation.contains("/"), "Should not contain volume/page separator")
    }

    func testSourceEquality() throws {
        // Given
        let source1 = Source(
            id: "src-1",
            bookTitle: "Book",
            text: "Text"
        )

        let source2 = Source(
            id: "src-1",
            bookTitle: "Book",
            text: "Text"
        )

        let source3 = Source(
            id: "src-2",
            bookTitle: "Book",
            text: "Text"
        )

        // Then
        XCTAssertEqual(source1, source2, "Sources with same properties should be equal")
        XCTAssertNotEqual(source1, source3, "Sources with different IDs should not be equal")
    }

    func testSourceInitWithDefaults() throws {
        // When
        let source = Source(
            bookTitle: "Test Book",
            text: "Test text"
        )

        // Then
        XCTAssertFalse(source.id.isEmpty, "Should generate UUID for ID")
        XCTAssertEqual(source.bookTitle, "Test Book")
        XCTAssertNil(source.author, "Should have nil author by default")
        XCTAssertNil(source.volumeNumber, "Should have nil volumeNumber by default")
        XCTAssertNil(source.pageNumber, "Should have nil pageNumber by default")
        XCTAssertEqual(source.text, "Test text")
        XCTAssertNil(source.sourceUrl, "Should have nil sourceUrl by default")
    }
}
