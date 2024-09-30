//
//  TnCodablePersistentController.swift
//  TnCameraMaster
//
//  Created by Thinh Nguyen on 9/30/24.
//

import Foundation
import CoreData

public struct TnCodablePersistenceController: TnLoggable {
    public static let shared = TnCodablePersistenceController()
    
    //    lazy var backgroundContext: NSManagedObjectContext = {
    //        return self.container.newBackgroundContext()
    //    }()
    
    private var viewContext: NSManagedObjectContext { container.viewContext }
    private let container: NSPersistentContainer
    
    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TnCodableModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func fetchItems(typeName: String) throws -> [TnCodableItem]? {
        let request = TnCodableItem.fetchRequest();
        request.predicate = .init(format: "typeName == %@", typeName)
        
        do {
            let results = try viewContext.fetch(request)
            return results
        } catch {
            logError("fetchItems error", error)
            throw error
        }
    }
    
    func fetchItem(typeName: String) throws -> TnCodableItem? {
        let results = try self.fetchItems(typeName: typeName)
        return results?.first
    }
    
    public func fetch<T>() throws -> (objectID: NSManagedObjectID, object: T)? where T: Codable {
        let typeName = "\(T.self)"
        if let item = try self.fetchItem(typeName: typeName), let jsonData = item.jsonData {
            let obj = try jsonData.tnToObjectFromJSON(T.self)
            return (item.objectID, obj)
        }
        return nil
    }
    
    public func fetch<T>(defaultObject: @escaping () -> T) throws -> (objectID: NSManagedObjectID, object: T) where T: Codable {
        if let objPair: (NSManagedObjectID, T) = try self.fetch() {
            return objPair
        }
        let obj = defaultObject()
        let objID = try self.add(object: obj)
        return (objID, obj)
    }
    
    public func save() throws {
        do {
            try viewContext.save()
        } catch {
            logError("save error", error)
        }
    }

    public func add<T>(object: T) throws -> NSManagedObjectID where T: Codable {
        let item = TnCodableItem(context: viewContext)
        item.typeName = "\(T.self)"
        item.jsonData = try object.toJsonData()
        try self.save()
        return item.objectID
    }

    public func update<T>(objectID: NSManagedObjectID, object: T) throws where T: Codable {
        let item = viewContext.object(with: objectID) as! TnCodableItem
        item.jsonData = try object.toJsonData()
        try self.save()
    }
    
    public func delete(objectID: NSManagedObjectID) throws {
        let item = viewContext.object(with: objectID)
        viewContext.delete(item)
        try self.save()
    }

}
