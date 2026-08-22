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
    ///   - ownerId: Identity this conversation is filed under, from `SessionManager.conversationOwnerId()`
    ///   - context: The managed object context to use
    /// - Returns: The created ConversationEntity
    @discardableResult
    func create(
        id: String,
        threadId: String?,
        title: String,
        conversationType: String = "regular",
        isLocalOnly: Bool = false,
        ownerId: String?,
        in context: NSManagedObjectContext
    ) -> ConversationEntity {
        let entity = ConversationEntity(context: context)
        entity.id = id
        entity.threadId = threadId
        entity.title = title
        entity.conversationType = conversationType
        entity.ownerId = ownerId
        entity.createdAt = Date()
        entity.updatedAt = Date()
        // Set isLocalOnly if attribute exists in the model
        if let attrs = ConversationEntity.entity().attributesByName as? [String: Any], attrs.keys.contains("isLocalOnly") {
            entity.setValue(isLocalOnly, forKey: "isLocalOnly")
        }
        return entity
    }

    /// Upserts a conversation by id, filing it under `ownerId`.
    ///
    /// The lookup is deliberately **not** scoped to the owner. This runs off the server's
    /// conversation list for the signed-in account, so the server has just asserted that
    /// this id belongs to `ownerId`. A scoped lookup would miss a row stored under a
    /// different owner — in particular a row written before scoping existed, whose owner is
    /// nil — and insert a second row with the same id. Claiming the existing row instead is
    /// both correct and the only way a legacy row is ever adopted.
    @discardableResult
    func upsert(
        id: String,
        threadId: String?,
        title: String,
        createdAt: Date,
        updatedAt: Date,
        conversationType: String = "regular",
        isLocalOnly: Bool = false,
        ownerId: String?,
        in context: NSManagedObjectContext
    ) -> ConversationEntity {
        if let existing = try? fetchIgnoringOwner(byId: id, from: context) {
            existing.threadId = threadId
            existing.title = title
            existing.conversationType = conversationType
            existing.ownerId = ownerId
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
        entity.ownerId = ownerId
        entity.createdAt = createdAt
        entity.updatedAt = updatedAt
        if let attrs = ConversationEntity.entity().attributesByName as? [String: Any], attrs.keys.contains("isLocalOnly") {
            entity.setValue(isLocalOnly, forKey: "isLocalOnly")
        }
        return entity
    }

    // MARK: - Read

    /// Restricts a fetch to one owner.
    ///
    /// A nil owner is matched with `ownerId == nil` rather than by dropping the predicate.
    /// "The app cannot name who is using it" must not mean "return everything" — that is
    /// precisely the state a device is in after a session expires without a logout, and an
    /// unfiltered fetch there is the leak this scoping exists to close. It also confines
    /// rows written before scoping existed to that one anonymous bucket.
    private static func ownerPredicate(_ ownerId: String?) -> NSPredicate {
        guard let ownerId else { return NSPredicate(format: "ownerId == nil") }
        return NSPredicate(format: "ownerId == %@", ownerId)
    }

    private static func predicate(_ predicate: NSPredicate, ownedBy ownerId: String?) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, ownerPredicate(ownerId)])
    }

    /// Fetches the owner's conversations ordered by updatedAt (most recent first)
    /// - Parameters:
    ///   - ownerId: The identity to scope to; nil matches only unowned rows
    ///   - context: The managed object context to use
    /// - Returns: Array of ConversationEntity
    /// - Throws: CoreDataError if fetch fails
    func fetchAll(ownedBy ownerId: String?, from context: NSManagedObjectContext) throws -> [ConversationEntity] {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = Self.ownerPredicate(ownerId)
        // Sort by creation date (newest first) to show history in reverse chronological order
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    /// Fetches every conversation regardless of owner.
    ///
    /// Only for operations that are about the device rather than about a person — the
    /// logout wipe, which must also sweep rows belonging to nobody. Never use it to serve
    /// the UI.
    func fetchAllIgnoringOwner(from context: NSManagedObjectContext) throws -> [ConversationEntity] {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    /// Fetches one of the owner's conversations by its ID
    /// - Parameters:
    ///   - id: The conversation ID
    ///   - ownerId: The identity to scope to; nil matches only unowned rows
    ///   - context: The managed object context to use
    /// - Returns: The ConversationEntity if found, nil otherwise
    /// - Throws: CoreDataError if fetch fails
    func fetch(byId id: String, ownedBy ownerId: String?, from context: NSManagedObjectContext) throws -> ConversationEntity? {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = Self.predicate(NSPredicate(format: "id == %@", id), ownedBy: ownerId)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    /// Fetches a conversation by ID without an ownership check.
    ///
    /// Reserved for the sync upsert, where the server has already vouched that the id
    /// belongs to the account being synced. See `upsert(...)`.
    func fetchIgnoringOwner(byId id: String, from context: NSManagedObjectContext) throws -> ConversationEntity? {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    /// Fetches one of the owner's conversations by its thread ID
    /// - Parameters:
    ///   - threadId: The OpenAI thread ID
    ///   - ownerId: The identity to scope to; nil matches only unowned rows
    ///   - context: The managed object context to use
    /// - Returns: The ConversationEntity if found, nil otherwise
    /// - Throws: CoreDataError if fetch fails
    func fetch(byThreadId threadId: String, ownedBy ownerId: String?, from context: NSManagedObjectContext) throws -> ConversationEntity? {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = Self.predicate(NSPredicate(format: "threadId == %@", threadId), ownedBy: ownerId)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    /// Fetches the owner's most recent empty conversation (with no messages)
    /// - Parameters:
    ///   - context: The managed object context to use
    ///   - includeLocalOnly: Whether guest/offline conversations count
    ///   - ownerId: The identity to scope to; nil matches only unowned rows
    /// - Returns: The most recent empty ConversationEntity if found, nil otherwise
    /// - Throws: CoreDataError if fetch fails
    func fetchMostRecentEmpty(
        from context: NSManagedObjectContext,
        includeLocalOnly: Bool = false,
        ownedBy ownerId: String?
    ) throws -> ConversationEntity? {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()

        // Filter for conversations with no messages
        let entityDesc = ConversationEntity.entity()
        let emptyPredicate: NSPredicate
        if entityDesc.attributesByName.keys.contains("isLocalOnly") {
            if includeLocalOnly {
                emptyPredicate = NSPredicate(format: "messages.@count == 0")
            } else {
                emptyPredicate = NSPredicate(format: "messages.@count == 0 AND (isLocalOnly == NO OR isLocalOnly == nil)")
            }
        } else {
            emptyPredicate = NSPredicate(format: "messages.@count == 0")
        }
        request.predicate = Self.predicate(emptyPredicate, ownedBy: ownerId)

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

    /// Deletes one of the owner's conversations by its ID
    /// - Parameters:
    ///   - id: The conversation ID to delete
    ///   - ownerId: The identity to scope to; nil matches only unowned rows
    ///   - context: The managed object context to use
    /// - Throws: CoreDataError if the conversation is not found or deletion fails
    func delete(byId id: String, ownedBy ownerId: String?, from context: NSManagedObjectContext) throws {
        guard let entity = try fetch(byId: id, ownedBy: ownerId, from: context) else {
            throw CoreDataError.notFound
        }
        delete(entity, from: context)
    }

    /// Deletes the owner's conversations.
    /// - Parameters:
    ///   - ownerId: The identity to scope to; nil matches only unowned rows
    ///   - context: The managed object context to use
    /// - Throws: CoreDataError if deletion fails
    func deleteAll(ownedBy ownerId: String?, from context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = Self.ownerPredicate(ownerId)
        do {
            let conversations = try context.fetch(request)
            conversations.forEach { context.delete($0) }
        } catch {
            throw CoreDataError.deleteFailed(error)
        }
    }

    /// Deletes every conversation, whoever it belongs to.
    ///
    /// The logout wipe, and only that: leaving another owner's rows behind is the whole
    /// problem, and rows belonging to nobody have to go too.
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
