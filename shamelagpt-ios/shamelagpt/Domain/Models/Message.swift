//
//  Message.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Domain model representing a single message in a conversation
struct Message: Identifiable, Equatable {
    let id: String
    let conversationId: String
    let content: String
    let isUserMessage: Bool
    let timestamp: Date
    let sources: [Source]
    let imageData: Data?
    let detectedLanguage: String?
    let isFactCheckMessage: Bool

    init(
        id: String = UUID().uuidString,
        conversationId: String,
        content: String,
        isUserMessage: Bool,
        timestamp: Date = Date(),
        sources: [Source] = [],
        imageData: Data? = nil,
        detectedLanguage: String? = nil,
        isFactCheckMessage: Bool = false
    ) {
        self.id = id
        self.conversationId = conversationId
        self.content = content
        self.isUserMessage = isUserMessage
        self.timestamp = timestamp
        self.sources = sources
        self.imageData = imageData
        self.detectedLanguage = detectedLanguage
        self.isFactCheckMessage = isFactCheckMessage
    }

    /// Returns true if the message is from the assistant
    var isAssistantMessage: Bool {
        return !isUserMessage
    }

    /// Returns true if the message has sources
    var hasSources: Bool {
        return !sources.isEmpty
    }

    /// Returns the display name for the detected language
    var languageDisplayName: String? {
        guard let languageCode = detectedLanguage else { return nil }
        return Locale.current.localizedString(forLanguageCode: languageCode) ?? languageCode.uppercased()
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension Message {
    static var preview: Message {
        Message(
            conversationId: "preview-conversation",
            content: "This is a sample message",
            isUserMessage: true
        )
    }

    static var previewAssistant: Message {
        Message(
            conversationId: "preview-conversation",
            content: "This is a sample assistant message with sources",
            isUserMessage: false,
            sources: [Source.preview]
        )
    }
}
#endif
