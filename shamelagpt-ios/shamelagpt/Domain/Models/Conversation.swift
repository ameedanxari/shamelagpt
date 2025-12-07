//
//  Conversation.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Type of conversation
enum ConversationType: String, Codable, Equatable {
    case regular
    case factCheck
}

/// Domain model representing a conversation with the assistant
struct Conversation: Identifiable, Equatable {
    let id: String
    let threadId: String?
    let title: String
    let createdAt: Date
    let updatedAt: Date
    let messages: [Message]
    let conversationType: ConversationType
    let isLocalOnly: Bool

    init(
        id: String = UUID().uuidString,
        threadId: String? = nil,
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [Message] = [],
        conversationType: ConversationType = .regular
        ,
        isLocalOnly: Bool = false
    ) {
        self.id = id
        self.threadId = threadId
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
        self.conversationType = conversationType
        self.isLocalOnly = isLocalOnly
    }

    /// Returns the last message in the conversation
    var lastMessage: Message? {
        return messages.last
    }

    /// Returns the number of messages in the conversation
    var messageCount: Int {
        return messages.count
    }

    /// Returns true if the conversation has messages
    var hasMessages: Bool {
        return !messages.isEmpty
    }

    /// Returns a preview of the last message content (truncated to 100 characters)
    var previewText: String {
        guard let lastMessage = lastMessage else {
            return "No messages"
        }

        let content = lastMessage.content
        if content.count > 100 {
            let index = content.index(content.startIndex, offsetBy: 100)
            return String(content[..<index]) + "..."
        }
        return content
    }

    /// Creates a copy of the conversation with updated messages
    func withMessages(_ messages: [Message]) -> Conversation {
        Conversation(
            id: id,
            threadId: threadId,
            title: title,
            createdAt: createdAt,
            updatedAt: Date(),
            messages: messages,
            conversationType: conversationType
            ,
            isLocalOnly: isLocalOnly
        )
    }

    /// Creates a copy of the conversation with an updated title
    func withTitle(_ title: String) -> Conversation {
        Conversation(
            id: id,
            threadId: threadId,
            title: title,
            createdAt: createdAt,
            updatedAt: Date(),
            messages: messages,
            conversationType: conversationType
            ,
            isLocalOnly: isLocalOnly
        )
    }

    /// Creates a copy of the conversation with an updated conversation type
    func withConversationType(_ type: ConversationType) -> Conversation {
        Conversation(
            id: id,
            threadId: threadId,
            title: title,
            createdAt: createdAt,
            updatedAt: Date(),
            messages: messages,
            conversationType: type
            ,
            isLocalOnly: isLocalOnly
        )
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension Conversation {
    static var preview: Conversation {
        Conversation(
            title: "Sample Conversation",
            messages: [
                Message(
                    conversationId: "preview-conversation",
                    content: "What is the ruling on prayer?",
                    isUserMessage: true
                ),
                Message(
                    conversationId: "preview-conversation",
                    content: "Prayer is one of the five pillars of Islam...",
                    isUserMessage: false,
                    sources: [Source.preview]
                )
            ]
        )
    }

    static var emptyPreview: Conversation {
        Conversation(
            title: "New Conversation",
            messages: []
        )
    }
}
#endif
