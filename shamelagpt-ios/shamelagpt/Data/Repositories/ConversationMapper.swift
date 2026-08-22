//
//  ConversationMapper.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Maps between ConversationEntity (Core Data) and Conversation (Domain Model)
struct ConversationMapper {

    // MARK: - Entity to Domain Model

    /// Converts a ConversationEntity to a Conversation domain model
    /// - Parameters:
    ///   - entity: The ConversationEntity to convert
    ///   - includeMessages: Whether to include messages in the conversion (default: true)
    /// - Returns: A Conversation domain model
    static func toDomainModel(_ entity: ConversationEntity, includeMessages: Bool = true) -> Conversation {
        var messages: [Message] = []

        if includeMessages, let messageEntities = entity.messages?.allObjects as? [MessageEntity] {
            // Sort messages by timestamp
            // distantPast, not Date(): an undated message read as "now" sorts to the end
            // and reads as the newest thing in the conversation, which is the one thing it
            // definitely is not. Undated content does not get to claim recency.
            let sortedMessages = messageEntities.sorted {
                ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast)
            }
            messages = MessageMapper.toDomainModels(sortedMessages)
        }

        // Parse conversation type, defaulting to regular if invalid
        let conversationType: ConversationType
        if let typeString = entity.conversationType,
           let type = ConversationType(rawValue: typeString) {
            conversationType = type
        } else {
            conversationType = .regular
        }

        // Read isLocalOnly if present in the Core Data model
        var isLocalOnly = false
        if let attributes = entity.entity.attributesByName as? [String: Any], attributes.keys.contains("isLocalOnly") {
            isLocalOnly = (entity.value(forKey: "isLocalOnly") as? Bool) ?? false
        }

        return Conversation(
            // A fresh UUID here would not match the stored row, so any later delete or
            // update against this id would silently affect nothing. Empty is at least
            // recognisable as broken.
            id: entity.id ?? "",
            threadId: entity.threadId,
            title: entity.title ?? "Untitled Conversation",
            // These feed the History sort. Defaulting to Date() put an undated
            // conversation at the top as the most recent — the same failure the sync
            // write path had, arriving from the read side instead.
            createdAt: entity.createdAt ?? .distantPast,
            updatedAt: entity.updatedAt ?? .distantPast,
            messages: messages,
            conversationType: conversationType,
            isLocalOnly: isLocalOnly
        )
    }

    /// Converts an array of ConversationEntity to an array of Conversation domain models
    /// - Parameters:
    ///   - entities: The array of ConversationEntity to convert
    ///   - includeMessages: Whether to include messages in the conversion (default: false for list views)
    /// - Returns: An array of Conversation domain models
    static func toDomainModels(_ entities: [ConversationEntity], includeMessages: Bool = false) -> [Conversation] {
        return entities.map { toDomainModel($0, includeMessages: includeMessages) }
    }
}
