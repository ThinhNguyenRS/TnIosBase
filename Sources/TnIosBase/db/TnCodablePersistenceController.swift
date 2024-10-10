//
//  TnCodablePersistentController.swift
//  TnCameraMaster
//
//  Created by Thinh Nguyen on 9/30/24.
//

import Foundation
import CoreData

public actor TnCodablePersistenceController: TnLoggable {
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
    
//    var context: NSManagedObjectContext {
//        container.viewContext
//    }

    lazy var context: NSManagedObjectContext = container.newBackgroundContext()

    func fetchItems(typeName: String) throws -> [TnCodableItem]? {
        let request = TnCodableItem.fetchRequest();
        request.predicate = .init(format: "typeName == %@", typeName)
        
        return try tnDoCatch(name: "fetchItems") { [self] in
            let results = try context.fetch(request)
            return results
        }
    }
    
    func fetchItem(typeName: String) throws -> TnCodableItem? {
        let results = try self.fetchItems(typeName: typeName)
        return results?.last
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
        if let objPair: (NSManagedObjectID, T) = try? self.fetch() {
            return objPair
        }
        let obj = defaultObject()
        let objID = try self.add(object: obj)
        return (objID, obj)
    }
    
    public func save() throws {
        try tnDoCatch(name: "save") {
            try self.context.save()
        }
    }

    public func add<T>(object: T) throws -> NSManagedObjectID where T: Codable {
        let item = TnCodableItem(context: context)
        item.typeName = "\(T.self)"
        item.jsonData = try object.toJsonData()
        item.createdAt = .now
        item.updatedAt = .now
        try self.save()
        return item.objectID
    }

    public func update<T>(objectID: NSManagedObjectID, object: T) throws where T: Codable {
        if let item = context.object(with: objectID) as? TnCodableItem {
            item.jsonData = try object.toJsonData()
            item.updatedAt = .now
            try self.save()
        }
    }
    
    public func delete(objectID: NSManagedObjectID) throws {
        let item = context.object(with: objectID)
        context.delete(item)
        try self.save()
    }

}
