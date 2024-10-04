//
//  TnCodablePersistentController.swift
//  TnCameraMaster
//
//  Created by Thinh Nguyen on 9/30/24.
//

import Foundation
import CoreData

public class TnCodablePersistenceController: TnLoggable {
    class PersistentContainer: NSPersistentContainer, @unchecked Sendable { }
    public static let shared = TnCodablePersistenceController()
    
    private lazy var container: NSPersistentContainer = {
        let modelURL = Bundle.module.url(forResource: "TnCodableModel", withExtension: ".momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!

        let result = NSPersistentContainer(name: "TnCodableModel", managedObjectModel: model)
        result.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                self.logError("loadPersistentStores", error.localizedDescription)
            }
        }
        return result
    }()
    
    private init() {
        logDebug("inited")
    }
    
    func fetchItems(typeName: String) throws -> [TnCodableItem]? {
        let request = TnCodableItem.fetchRequest();
        request.predicate = .init(format: "typeName == %@", typeName)
        
        do {
            let results = try container.viewContext.fetch(request)
            return results
        } catch {
            logError("fetchItems error", error.localizedDescription)
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
            try container.viewContext.save()
        } catch {
            logError("save error", error.localizedDescription)
        }
    }

    public func add<T>(object: T) throws -> NSManagedObjectID where T: Codable {
        let item = TnCodableItem(context: container.viewContext)
        item.typeName = "\(T.self)"
        item.jsonData = try object.toJsonData()
        item.createdAt = .now
        item.updatedAt = .now
        try self.save()
        return item.objectID
    }

    public func update<T>(objectID: NSManagedObjectID, object: T) throws where T: Codable {
        let item = container.viewContext.object(with: objectID) as! TnCodableItem
        item.jsonData = try object.toJsonData()
        item.updatedAt = .now
        try self.save()
    }
    
    public func delete(objectID: NSManagedObjectID) throws {
        let item = container.viewContext.object(with: objectID)
        container.viewContext.delete(item)
        try self.save()
    }

}
