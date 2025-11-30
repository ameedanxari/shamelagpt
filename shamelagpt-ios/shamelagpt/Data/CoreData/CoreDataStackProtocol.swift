//
//  CoreDataStackProtocol.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import CoreData

/// Protocol for Core Data stack
protocol CoreDataStackProtocol: AnyObject, Sendable {
    var viewContext: NSManagedObjectContext { get }
    
    func newBackgroundContext() -> NSManagedObjectContext
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)
    func saveContext() throws
    func save(context: NSManagedObjectContext) throws
    func deleteAllData() throws
}

/// Extension to make CoreDataStack conform to the protocol
extension CoreDataStack: CoreDataStackProtocol {}
