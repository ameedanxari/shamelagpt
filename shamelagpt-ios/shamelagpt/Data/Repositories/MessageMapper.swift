//
//  MessageMapper.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Maps between MessageEntity (Core Data) and Message (Domain Model)
struct MessageMapper {

    // MARK: - Entity to Domain Model

    /// Converts a MessageEntity to a Message domain model
    /// - Parameter entity: The MessageEntity to convert
    /// - Returns: A Message domain model
    static func toDomainModel(_ entity: MessageEntity) -> Message {
        let sources = parseSources(from: entity.sources)

        return Message(
            id: entity.id ?? UUID().uuidString,
            conversationId: entity.conversationId ?? "",
            content: entity.content ?? "",
            isUserMessage: entity.isUserMessage,
            timestamp: entity.timestamp ?? Date(),
            sources: sources,
            imageData: entity.imageData,
            detectedLanguage: entity.detectedLanguage,
            isFactCheckMessage: entity.isFactCheckMessage
        )
    }

    /// Converts an array of MessageEntity to an array of Message domain models
    /// - Parameter entities: The array of MessageEntity to convert
    /// - Returns: An array of Message domain models
    static func toDomainModels(_ entities: [MessageEntity]) -> [Message] {
        return entities.map { toDomainModel($0) }
    }

    // MARK: - Domain Model to JSON

    /// Converts sources array to JSON string for storage
    /// - Parameter sources: Array of Source objects
    /// - Returns: JSON string representation, or nil if empty or encoding fails
    static func sourcesToJSON(_ sources: [Source]) -> String? {
        guard !sources.isEmpty else { return nil }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        do {
            let data = try encoder.encode(sources)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error encoding sources to JSON: \(error)")
            return nil
        }
    }

    // MARK: - JSON to Domain Model

    /// Parses sources from JSON string
    /// - Parameter jsonString: JSON string containing sources
    /// - Returns: Array of Source objects, empty if parsing fails
    private static func parseSources(from jsonString: String?) -> [Source] {
        guard let jsonString = jsonString,
              let data = jsonString.data(using: .utf8) else {
            return []
        }

        let decoder = JSONDecoder()

        do {
            return try decoder.decode([Source].self, from: data)
        } catch {
            print("Error decoding sources from JSON: \(error)")
            return []
        }
    }
}
