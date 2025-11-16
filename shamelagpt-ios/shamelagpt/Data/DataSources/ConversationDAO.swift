//
//  ConversationDAO.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import CoreData

/// Data Access Object for ConversationEntity CRUD operations
final class ConversationDAO: @unchecked Sendable {

    // MARK: - Properties
    private let coreDataStack: CoreDataStackProtocol

    // MARK: - Initialization
    init(coreDataStack: CoreDataStackProtocol = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Create

    /// Creates a new conversation entity
    /// - Parameters:
    ///   - id: Unique identifier for the conversation
    ///   - threadId: Optional OpenAI thread ID
    ///   - title: Title of the conversation
    ///   - conversationType: Type of conversation (regular or factCheck)
    ///   - context: The managed object context to use
    /// - Returns: The created ConversationEntity
    @discardableResult
    func create(
        id: String,
        threadId: String?,
        title: String,
        conversationType: String = "regular",
        isLocalOnly: Bool = false,
        in context: NSManagedObjectContext
    ) -> ConversationEntity {
        let entity = ConversationEntity(context: context)
        entity.id = id
        entity.threadId = threadId
        entity.title = title
        entity.conversationType = conversationType
        entity.createdAt = Date()
        entity.updatedAt = Date()
        // Set isLocalOnly if attribute exists in the model
        if let attrs = ConversationEntity.entity().attributesByName as? [String: Any], attrs.keys.contains("isLocalOnly") {
            entity.setValue(isLocalOnly, forKey: "isLocalOnly")
        }
        return entity
    }

    /// Upserts a conversation by id
    @discardableResult
    func upsert(
        id: String,
        threadId: String?,
        title: String,
        createdAt: Date,
        updatedAt: Date,
        conversationType: String = "regular",
        isLocalOnly: Bool = false,
        in context: NSManagedObjectContext
    ) -> ConversationEntity {
        if let existing = try? fetch(byId: id, from: context) {
            existing.threadId = threadId
            existing.title = title
            existing.conversationType = conversationType
            if existing.createdAt == nil {
                existing.createdAt = createdAt
            }
            existing.updatedAt = updatedAt
            if let attrs = ConversationEntity.entity().attributesByName as? [String: Any], attrs.keys.contains("isLocalOnly") {
                existing.setValue(isLocalOnly, forKey: "isLocalOnly")
            }
            return existing
        }
        let entity = ConversationEntity(context: context)
        entity.id = id
        entity.threadId = threadId
        entity.title = title
        entity.conversationType = conversationType
        entity.createdAt = createdAt
        entity.updatedAt = updatedAt
        if let attrs = ConversationEntity.entity().attributesByName as? [String: Any], attrs.keys.contains("isLocalOnly") {
            entity.setValue(isLocalOnly, forKey: "isLocalOnly")
        }
        return entity
    }

    // MARK: - Read

    /// Fetches all conversations ordered by updatedAt (most recent first)
    /// - Parameter context: The managed object context to use
    /// - Returns: Array of ConversationEntity
    /// - Throws: CoreDataError if fetch fails
    func fetchAll(from context: NSManagedObjectContext) throws -> [ConversationEntity] {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        // Sort by creation date (newest first) to show history in reverse chronological order
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    /// Fetches a conversation by its ID
    /// - Parameters:
    ///   - id: The conversation ID
    ///   - context: The managed object context to use
    /// - Returns: The ConversationEntity if found, nil otherwise
    /// - Throws: CoreDataError if fetch fails
    func fetch(byId id: String, from context: NSManagedObjectContext) throws -> ConversationEntity? {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    /// Fetches a conversation by its thread ID
    /// - Parameters:
    ///   - threadId: The OpenAI thread ID
    ///   - context: The managed object context to use
    /// - Returns: The ConversationEntity if found, nil otherwise
    /// - Throws: CoreDataError if fetch fails
    func fetch(byThreadId threadId: String, from context: NSManagedObjectContext) throws -> ConversationEntity? {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "threadId == %@", threadId)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    /// Fetches the most recent empty conversation (with no messages)
    /// - Parameter context: The managed object context to use
    /// - Returns: The most recent empty ConversationEntity if found, nil otherwise
    /// - Throws: CoreDataError if fetch fails
    func fetchMostRecentEmpty(from context: NSManagedObjectContext, includeLocalOnly: Bool = false) throws -> ConversationEntity? {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()

        // Filter for conversations with no messages
        let entityDesc = ConversationEntity.entity()
        if entityDesc.attributesByName.keys.contains("isLocalOnly") {
            if includeLocalOnly {
                request.predicate = NSPredicate(format: "messages.@count == 0")
            } else {
                request.predicate = NSPredicate(format: "messages.@count == 0 AND (isLocalOnly == NO OR isLocalOnly == nil)")
            }
        } else {
            request.predicate = NSPredicate(format: "messages.@count == 0")
        }

        // Sort by most recent updatedAt
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    // MARK: - Update

    /// Updates a conversation's title
    /// - Parameters:
    ///   - entity: The conversation entity to update
    ///   - title: The new title
    func updateTitle(_ entity: ConversationEntity, title: String) {
        entity.title = title
        entity.updatedAt = Date()
    }

    /// Updates a conversation's thread ID
    /// - Parameters:
    ///   - entity: The conversation entity to update
    ///   - threadId: The new thread ID
    func updateThreadId(_ entity: ConversationEntity, threadId: String) {
        entity.threadId = threadId
        entity.updatedAt = Date()
    }

    /// Marks a conversation as updated (updates the updatedAt timestamp)
    /// - Parameter entity: The conversation entity to mark as updated
    func markAsUpdated(_ entity: ConversationEntity) {
        entity.updatedAt = Date()
    }

    // MARK: - Delete

    /// Deletes a conversation entity
    /// - Parameters:
    ///   - entity: The conversation entity to delete
    ///   - context: The managed object context to use
    func delete(_ entity: ConversationEntity, from context: NSManagedObjectContext) {
        context.delete(entity)
    }

    /// Deletes a conversation by its ID
    /// - Parameters:
    ///   - id: The conversation ID to delete
    ///   - context: The managed object context to use
    /// - Throws: CoreDataError if the conversation is not found or deletion fails
    func delete(byId id: String, from context: NSManagedObjectContext) throws {
        guard let entity = try fetch(byId: id, from: context) else {
            throw CoreDataError.notFound
        }
        delete(entity, from: context)
    }

    /// Deletes all conversations
    /// - Parameter context: The managed object context to use
    /// - Throws: CoreDataError if deletion fails
    func deleteAll(from context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        do {
            let conversations = try context.fetch(request)
            conversations.forEach { context.delete($0) }
        } catch {
            throw CoreDataError.deleteFailed(error)
        }
    }

    // MARK: - Count

    /// Returns the total number of conversations
    /// - Parameter context: The managed object context to use
    /// - Returns: The count of conversations
    /// - Throws: CoreDataError if count fails
    func count(in context: NSManagedObjectContext) throws -> Int {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()

        do {
            return try context.count(for: request)
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }
}
