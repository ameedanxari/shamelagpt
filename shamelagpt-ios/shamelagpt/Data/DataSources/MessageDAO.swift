//
//  MessageDAO.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import CoreData

/// Data Access Object for MessageEntity CRUD operations
final class MessageDAO: @unchecked Sendable {

    // MARK: - Properties
    private let coreDataStack: CoreDataStackProtocol

    // MARK: - Initialization
    init(coreDataStack: CoreDataStackProtocol = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Create

    /// Creates a new message entity
    /// - Parameters:
    ///   - id: Unique identifier for the message
    ///   - conversationId: ID of the parent conversation
    ///   - content: Message content
    ///   - isUserMessage: Whether this is a user message or assistant message
    ///   - timestamp: When the message was created
    ///   - sources: Optional JSON string of sources
    ///   - imageData: Optional image data for fact-checking
    ///   - detectedLanguage: Optional detected language code
    ///   - isFactCheckMessage: Whether this is a fact-checking message
    ///   - conversation: The parent conversation entity
    ///   - context: The managed object context to use
    /// - Returns: The created MessageEntity
    @discardableResult
    func create(
        id: String,
        conversationId: String,
        content: String,
        isUserMessage: Bool,
        timestamp: Date,
        sources: String?,
        imageData: Data? = nil,
        detectedLanguage: String? = nil,
        isFactCheckMessage: Bool = false,
        conversation: ConversationEntity,
        in context: NSManagedObjectContext
    ) -> MessageEntity {
        let entity = MessageEntity(context: context)
        entity.id = id
        entity.conversationId = conversationId
        entity.content = content
        entity.isUserMessage = isUserMessage
        entity.timestamp = timestamp
        entity.sources = sources
        entity.imageData = imageData
        entity.detectedLanguage = detectedLanguage
        entity.isFactCheckMessage = isFactCheckMessage
        entity.conversation = conversation
        return entity
    }

    // MARK: - Read

    /// Fetches all messages for a conversation ordered by timestamp
    /// - Parameters:
    ///   - conversationId: The conversation ID
    ///   - context: The managed object context to use
    /// - Returns: Array of MessageEntity
    /// - Throws: CoreDataError if fetch fails
    func fetchAll(
        forConversationId conversationId: String,
        from context: NSManagedObjectContext
    ) throws -> [MessageEntity] {
        let request: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "conversationId == %@", conversationId)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    /// Fetches a message by its ID
    /// - Parameters:
    ///   - id: The message ID
    ///   - context: The managed object context to use
    /// - Returns: The MessageEntity if found, nil otherwise
    /// - Throws: CoreDataError if fetch fails
    func fetch(byId id: String, from context: NSManagedObjectContext) throws -> MessageEntity? {
        let request: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    /// Fetches the last message in a conversation
    /// - Parameters:
    ///   - conversationId: The conversation ID
    ///   - context: The managed object context to use
    /// - Returns: The last MessageEntity if found, nil otherwise
    /// - Throws: CoreDataError if fetch fails
    func fetchLast(
        forConversationId conversationId: String,
        from context: NSManagedObjectContext
    ) throws -> MessageEntity? {
        let request: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "conversationId == %@", conversationId)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    // MARK: - Update

    /// Updates a message's content
    /// - Parameters:
    ///   - entity: The message entity to update
    ///   - content: The new content
    func updateContent(_ entity: MessageEntity, content: String) {
        entity.content = content
    }

    /// Updates a message's sources
    /// - Parameters:
    ///   - entity: The message entity to update
    ///   - sources: The new sources JSON string
    func updateSources(_ entity: MessageEntity, sources: String?) {
        entity.sources = sources
    }

    // MARK: - Delete

    /// Deletes a message entity
    /// - Parameters:
    ///   - entity: The message entity to delete
    ///   - context: The managed object context to use
    func delete(_ entity: MessageEntity, from context: NSManagedObjectContext) {
        context.delete(entity)
    }

    /// Deletes a message by its ID
    /// - Parameters:
    ///   - id: The message ID to delete
    ///   - context: The managed object context to use
    /// - Throws: CoreDataError if the message is not found or deletion fails
    func delete(byId id: String, from context: NSManagedObjectContext) throws {
        guard let entity = try fetch(byId: id, from: context) else {
            throw CoreDataError.notFound
        }
        delete(entity, from: context)
    }

    /// Deletes all messages for a conversation
    /// - Parameters:
    ///   - conversationId: The conversation ID
    ///   - context: The managed object context to use
    /// - Throws: CoreDataError if deletion fails
    func deleteAll(
        forConversationId conversationId: String,
        from context: NSManagedObjectContext
    ) throws {
        let request: NSFetchRequest<NSFetchRequestResult> = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "conversationId == %@", conversationId)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(batchDeleteRequest)
        } catch {
            throw CoreDataError.deleteFailed(error)
        }
    }

    // MARK: - Count

    /// Returns the count of messages in a conversation
    /// - Parameters:
    ///   - conversationId: The conversation ID
    ///   - context: The managed object context to use
    /// - Returns: The count of messages
    /// - Throws: CoreDataError if count fails
    func count(
        forConversationId conversationId: String,
        in context: NSManagedObjectContext
    ) throws -> Int {
        let request: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "conversationId == %@", conversationId)

        do {
            return try context.count(for: request)
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }
}
