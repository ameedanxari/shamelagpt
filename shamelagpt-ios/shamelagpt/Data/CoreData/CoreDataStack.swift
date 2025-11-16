//
//  CoreDataStack.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import CoreData

/// Core Data stack with singleton pattern and background context support
final class CoreDataStack: @unchecked Sendable {

    // MARK: - Singleton
    static let shared = CoreDataStack()

    // MARK: - Properties
    private let modelName: String = "ShamelaGPT"

    /// Main persistent container
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)

        // Use in-memory store for UI testing
        if UserDefaults.standard.bool(forKey: "isUITesting") {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, you should handle this more gracefully
                fatalError("Unresolved error loading persistent store: \(error), \(error.userInfo)")
            }

            // Configure automatic merging
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }

        return container
    }()

    /// Main view context (use on main thread only)
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Background Context

    /// Creates a new background context for performing operations off the main thread
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Performs a task on a background context
    /// - Parameter block: The block to execute with the background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

    // MARK: - Save Context

    /// Saves the view context if it has changes
    /// - Throws: CoreDataError if the save fails
    func saveContext() throws {
        let context = viewContext

        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed(error)
        }
    }

    /// Saves a specific context if it has changes
    /// - Parameter context: The context to save
    /// - Throws: CoreDataError if the save fails
    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed(error)
        }
    }

    // MARK: - Delete All Data

    /// Deletes all data from the persistent store (useful for testing or logout)
    /// - Throws: CoreDataError if deletion fails
    func deleteAllData() throws {
        let entities = persistentContainer.managedObjectModel.entities

        for entity in entities {
            guard let entityName = entity.name else { continue }

            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try viewContext.execute(deleteRequest)
                try saveContext()
            } catch {
                throw CoreDataError.deleteFailed(error)
            }
        }
    }
}

// MARK: - Core Data Errors

/// Custom errors for Core Data operations
enum CoreDataError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case notFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .notFound:
            return "Requested data not found"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}

// MARK: - Equatable support

extension CoreDataError: Equatable {
    static func == (lhs: CoreDataError, rhs: CoreDataError) -> Bool {
        switch (lhs, rhs) {
        case (.notFound, .notFound):
            return true
        case (.invalidData, .invalidData):
            return true
        case (.saveFailed, .saveFailed):
            return true
        case (.fetchFailed, .fetchFailed):
            return true
        case (.deleteFailed, .deleteFailed):
            return true
        default:
            return false
        }
    }
}
