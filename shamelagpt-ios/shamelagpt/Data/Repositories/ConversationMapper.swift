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
            let sortedMessages = messageEntities.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
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
            id: entity.id ?? UUID().uuidString,
            threadId: entity.threadId,
            title: entity.title ?? "Untitled Conversation",
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date(),
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
