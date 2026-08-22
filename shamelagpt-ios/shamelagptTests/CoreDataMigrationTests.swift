//
//  CoreDataMigrationTests.swift
//  shamelagptTests
//
//  Guards the model version chain: "ShamelaGPT" -> "ShamelaGPT 2" (the optional
//  `reasoning` attribute on MessageEntity) -> "ShamelaGPT 3" (the optional `ownerId`
//  attribute on ConversationEntity). Adding an optional attribute is a lightweight
//  change, but only if EVERY model version still ships in the bundle: Core Data locates
//  the source model by the version hashes recorded in the store, and if it cannot find
//  one it fails to open the store and CoreDataStack calls fatalError. These tests fail
//  loudly if a future change edits a shipped model in place instead of adding a version.
//
//  The v1 -> v3 case is not hypothetical padding: an install that has not been opened
//  since before the reasoning release skips a version, and Core Data has to infer a
//  mapping across both hops in one go.
//

import XCTest
import CoreData
@testable import ShamelaGPT

final class CoreDataMigrationTests: XCTestCase {

    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoreDataMigrationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory = temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        temporaryDirectory = nil
    }

    func testBothModelVersionsShipInTheBundle() throws {
        // Every superseded version must remain in the bundle. Without one, an installed
        // app sitting on it has no source model to migrate from.
        XCTAssertNotNil(try? modelURL(named: "ShamelaGPT"), "The v1 model must still ship")
        XCTAssertNotNil(try? modelURL(named: "ShamelaGPT 2"), "The v2 model must still ship")
        XCTAssertNotNil(try? modelURL(named: "ShamelaGPT 3"), "The v3 model must ship")
    }

    func testCurrentModelAddsOptionalReasoningAttribute() throws {
        let destination = try managedObjectModel(named: "ShamelaGPT 2")
        let messageEntity = try XCTUnwrap(destination.entitiesByName["MessageEntity"])
        let reasoning = try XCTUnwrap(messageEntity.attributesByName["reasoning"], "MessageEntity should declare `reasoning`")

        XCTAssertEqual(reasoning.attributeType, .stringAttributeType)
        XCTAssertTrue(reasoning.isOptional, "`reasoning` must be optional so existing rows stay valid")

        let source = try managedObjectModel(named: "ShamelaGPT")
        XCTAssertNil(source.entitiesByName["MessageEntity"]?.attributesByName["reasoning"],
                     "The v1 model must be left untouched")
    }

    func testMappingModelBetweenVersionsCanBeInferred() throws {
        // If this throws, the change is no longer lightweight and would need a
        // hand-written mapping model.
        let source = try managedObjectModel(named: "ShamelaGPT")
        let destination = try managedObjectModel(named: "ShamelaGPT 2")

        let mapping = try NSMappingModel.inferredMappingModel(forSourceModel: source, destinationModel: destination)
        XCTAssertFalse(mapping.entityMappings.isEmpty, "An inferred mapping model should cover the entities")
    }

    func testMigrationPreservesExistingMessagesAndLeavesReasoningNil() throws {
        let storeURL = temporaryDirectory.appendingPathComponent("ShamelaGPT.sqlite")
        let source = try managedObjectModel(named: "ShamelaGPT")
        let destination = try managedObjectModel(named: "ShamelaGPT 2")

        // Given - a store written by the shipped app, on the old model
        try writeLegacyStore(at: storeURL, using: source)

        // When - the app opens it with the new model, exactly as CoreDataStack does
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: destination)
        _ = try coordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true
            ]
        )

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        // Then - the pre-existing rows are still there, with reasoning defaulted to nil
        let request = NSFetchRequest<NSManagedObject>(entityName: "MessageEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        let messages = try context.fetch(request)

        XCTAssertEqual(messages.count, 2, "Migration must not drop rows")
        XCTAssertEqual(messages.map { $0.value(forKey: "content") as? String }, ["Question", "Answer"])
        XCTAssertNil(messages[0].value(forKey: "reasoning"), "Rows written before the upgrade have no reasoning")
        XCTAssertNil(messages[1].value(forKey: "reasoning"))

        let conversations = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "ConversationEntity"))
        XCTAssertEqual(conversations.count, 1, "Conversations must survive too")

        // And the migrated store accepts the new attribute
        messages[1].setValue("Weighing the evidence", forKey: "reasoning")
        try context.save()
        XCTAssertEqual(messages[1].value(forKey: "reasoning") as? String, "Weighing the evidence")
    }

    // MARK: - v3: per-user conversation scoping

    func testCurrentModelAddsOptionalOwnerIdAttribute() throws {
        let destination = try managedObjectModel(named: "ShamelaGPT 3")
        let conversationEntity = try XCTUnwrap(destination.entitiesByName["ConversationEntity"])
        let ownerId = try XCTUnwrap(
            conversationEntity.attributesByName["ownerId"],
            "ConversationEntity should declare `ownerId`"
        )

        XCTAssertEqual(ownerId.attributeType, .stringAttributeType)
        // Non-optional would make this a heavyweight migration: every existing row would
        // violate the model the instant the store opened, and there is no honest default
        // to give them anyway.
        XCTAssertTrue(ownerId.isOptional, "`ownerId` must be optional so existing rows stay valid")

        let v2 = try managedObjectModel(named: "ShamelaGPT 2")
        XCTAssertNil(v2.entitiesByName["ConversationEntity"]?.attributesByName["ownerId"],
                     "The v2 model must be left untouched")
        let v1 = try managedObjectModel(named: "ShamelaGPT")
        XCTAssertNil(v1.entitiesByName["ConversationEntity"]?.attributesByName["ownerId"],
                     "The v1 model must be left untouched")
    }

    func testMappingModelToCurrentVersionCanBeInferred() throws {
        let destination = try managedObjectModel(named: "ShamelaGPT 3")

        // Both hops, including the skip-a-version case. If either throws, the change is no
        // longer lightweight and would need a hand-written mapping model.
        for sourceName in ["ShamelaGPT", "ShamelaGPT 2"] {
            let source = try managedObjectModel(named: sourceName)
            let mapping = try NSMappingModel.inferredMappingModel(
                forSourceModel: source,
                destinationModel: destination
            )
            XCTAssertFalse(
                mapping.entityMappings.isEmpty,
                "An inferred mapping model should cover the entities for \(sourceName) -> v3"
            )
        }
    }

    func testMigrationToCurrentVersionPreservesRowsAndLeavesOwnerNil() throws {
        let destination = try managedObjectModel(named: "ShamelaGPT 3")

        for sourceName in ["ShamelaGPT", "ShamelaGPT 2"] {
            let storeURL = temporaryDirectory.appendingPathComponent("\(sourceName).sqlite")
            let source = try managedObjectModel(named: sourceName)

            // Given - a store written by a shipped build, on an older model
            try writeLegacyStore(at: storeURL, using: source)

            // When - the app opens it with the current model, exactly as CoreDataStack does
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: destination)
            _ = try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
                ]
            )

            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator

            // Then - nothing is dropped
            let conversations = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "ConversationEntity"))
            let messages = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "MessageEntity"))
            XCTAssertEqual(conversations.count, 1, "Migration from \(sourceName) must not drop conversations")
            XCTAssertEqual(messages.count, 2, "Migration from \(sourceName) must not drop messages")
            XCTAssertEqual(conversations.first?.value(forKey: "title") as? String, "Existing conversation")

            // And the rows land unowned. They predate scoping, so the app has no evidence
            // about who wrote them; claiming them for whoever signs in next is exactly the
            // leak this attribute exists to prevent.
            XCTAssertNil(
                conversations.first?.value(forKey: "ownerId"),
                "Rows written before scoping must migrate in as unowned"
            )

            // And the migrated store both accepts the attribute and can be filtered on it
            conversations.first?.setValue("firebase-uid-a", forKey: "ownerId")
            try context.save()

            let request = NSFetchRequest<NSManagedObject>(entityName: "ConversationEntity")
            request.predicate = NSPredicate(format: "ownerId == %@", "firebase-uid-b")
            XCTAssertEqual(try context.count(for: request), 0, "A different owner must match nothing")
            request.predicate = NSPredicate(format: "ownerId == %@", "firebase-uid-a")
            XCTAssertEqual(try context.count(for: request), 1)
        }
    }

    // MARK: - Helpers

    private func writeLegacyStore(at storeURL: URL, using model: NSManagedObjectModel) throws {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let store = try coordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: nil
        )

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        let now = Date()
        let conversation = NSEntityDescription.insertNewObject(forEntityName: "ConversationEntity", into: context)
        conversation.setValue("conversation-1", forKey: "id")
        conversation.setValue("Existing conversation", forKey: "title")
        conversation.setValue(now, forKey: "createdAt")
        conversation.setValue(now, forKey: "updatedAt")
        conversation.setValue(false, forKey: "isLocalOnly")

        for (index, payload) in [("Question", true), ("Answer", false)].enumerated() {
            let message = NSEntityDescription.insertNewObject(forEntityName: "MessageEntity", into: context)
            message.setValue("message-\(index)", forKey: "id")
            message.setValue("conversation-1", forKey: "conversationId")
            message.setValue(payload.0, forKey: "content")
            message.setValue(payload.1, forKey: "isUserMessage")
            message.setValue(false, forKey: "isFactCheckMessage")
            message.setValue(now.addingTimeInterval(Double(index)), forKey: "timestamp")
            message.setValue(conversation, forKey: "conversation")
        }

        try context.save()
        try coordinator.remove(store)
    }

    private func managedObjectModel(named name: String) throws -> NSManagedObjectModel {
        let url = try modelURL(named: name)
        return try XCTUnwrap(NSManagedObjectModel(contentsOf: url), "Could not load model at \(url)")
    }

    private func modelURL(named name: String) throws -> URL {
        let bundle = Bundle(for: SessionManager.self)
        let momdURL = try XCTUnwrap(bundle.url(forResource: "ShamelaGPT", withExtension: "momd"),
                                    "ShamelaGPT.momd is missing from the app bundle")
        let url = momdURL.appendingPathComponent("\(name).mom")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("Model version \(name) not found at \(url.path)")
        }
        return url
    }
}
