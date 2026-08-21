//
//  CoreDataMigrationTests.swift
//  shamelagptTests
//
//  Guards the ShamelaGPT -> "ShamelaGPT 2" model upgrade (the optional `reasoning`
//  attribute on MessageEntity). Adding an optional attribute is a lightweight change,
//  but only if BOTH model versions ship in the bundle: Core Data needs the source
//  model to infer a mapping model, and if it cannot find one it fails to open the
//  store and CoreDataStack calls fatalError. These tests fail loudly if a future
//  change edits a shipped model in place instead of adding a version.
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
        // The previous version must remain in the bundle. Without it an installed app
        // has no source model to migrate from.
        XCTAssertNotNil(try? modelURL(named: "ShamelaGPT"), "The v1 model must still ship")
        XCTAssertNotNil(try? modelURL(named: "ShamelaGPT 2"), "The v2 model must ship")
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
