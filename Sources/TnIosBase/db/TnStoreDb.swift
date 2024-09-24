//
//  TnStore.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 8/21/21.
//

import Foundation

class TnStoreDb: TnDbBased {
    override func open() throws {
        try super.open()
        // create main table
        TnLogger.debug(name, "create main table ...")
        try db.execute("""
            create table if not exists objects (
            id TEXT NOT NULL,
            type INTEGER NOT NULL,
            json TEXT NOT NULL,
            PRIMARY KEY (id, type)
            )
            """)
        
        TnLogger.debug(name, "init done !")
    }

    func countBy(id: String, type: Int32) throws -> Int32 {
        return try db.querySingle("select count(*) from objects where id='\(id)' and type=\(type)") { stm in
            TnDbSqlite.getInt32(stm, idx: 0)
        }!
    }
    func countBy(type: Int32) throws -> Int32 {
        return try db.querySingle("select count(*) from objects where type=\(type)") { stm in
            TnDbSqlite.getInt32(stm, idx: 0)
        }!
    }
    func find<T: TnEntityItem>(id: String, type: T.Type) throws -> T? {
        return try db.querySingle("SELECT json FROM objects WHERE id='\(id)' and type=\(T.getType())") {stm in
            return TnDbSqlite.getObject(stm, idx: 0, type: type)
        }
    }
    
    @discardableResult func insert<T: TnEntityItem>(entity: T) throws -> Bool {
        return try db.execute("INSERT INTO objects (id, type, json) VALUES ('\(entity.getId())', \(T.getType()), '\(entity.json())')") > 0
    }
    
    @discardableResult func update<T: TnEntityItem>(entity: T) throws -> Bool {
        return try db.execute("UPDATE objects SET json='\(entity.json())' WHERE id='\(entity.getId())' and type=\(T.getType())") > 0
    }
    
    @discardableResult func save<T: TnEntityItem>(entity: T) throws -> Bool {
        if try countBy(id: entity.getId(), type: T.getType()) > 0 {
            return try update(entity: entity)
        } else {
            return try insert(entity: entity)
        }
    }
    
    @discardableResult func remove(id: String, type: Int32) throws -> Bool {
        return try db.execute("DELETE FROM objects WHERE id='\(id)' and type=\(type)") > 0
    }
    
    @discardableResult func remove<T: TnEntityItem>(entity: T) throws -> Bool {
        return try self.remove(id: entity.getId(), type: T.getType())
    }
    
    @discardableResult func removeAll(type: Int32) throws -> Bool {
        return try db.execute("DELETE FROM objects WHERE type=\(type)") > 0
    }

    @discardableResult func removeAll<T: TnEntityItem>(type: T.Type) throws -> Bool {
        return try db.execute("DELETE FROM objects WHERE type=\(type.getType())") > 0
    }

    func loadList<T: TnEntityItem>(_ type: T.Type) throws -> [T] {
        let ret: [T] = try db.queryMulti("SELECT json FROM objects WHERE type=\(T.getType())") {stm in
            TnDbSqlite.getObject(stm, idx: 0, type: T.self)
        }
        return ret;
    }
    
    func loadSingle<T: TnEntityItem>(_ type: T.Type) throws -> T? {
        return try db.querySingle("SELECT json FROM objects WHERE type=\(T.getType())") {stm in
            TnDbSqlite.getObject(stm, idx: 0, type: T.self)
        }
    }
    
    func loadSingleID<T: TnEntityItem>(_ type: T.Type) throws -> String? {
        return try db.querySingle("SELECT id FROM objects WHERE type=\(T.getType())") {stm in
            return TnDbSqlite.getString(stm, idx: 0)
        }
    }

    func loadAndSave<T: TnEntityItem>(_ type: T.Type) throws -> T {
        var entity = try loadSingle(T.self)
        if entity == nil {
            entity = T.default

            if try countBy(type: type.getType()) == 0 {
                try self.insert(entity: entity!)
            } else {
                try self.update(entity: entity!)
            }
        }
        return entity!
    }
}
