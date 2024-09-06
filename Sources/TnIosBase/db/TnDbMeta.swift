//
//  TnDbswift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 10/13/21.
//

import Foundation

struct TnDbFieldMeta {
    enum DbType: String {
        case int = "INTEGER"
        case float = "REAL"
        case data = "BLOB"
        case text = "TEXT"
    }
    let name: String
    let type: DbType
    var notNull: Bool = true
}

struct TnDbTableMeta<TItem> {
    let name: String
    let idName: String
    let fields: [TnDbFieldMeta]
    
    let itemResolve: (OpaquePointer) throws -> TItem
    let paramsResolve: (TItem) throws -> [Any]
}

extension TnDbTableMeta {
    func getSqlCreate() -> String {
        var sql = "create table if not exists \(name) ( \n"
        for field in fields {
            sql += "\(field.name) \(field.type.rawValue) \(field.notNull ? "NOT NULL" : ""), \n"
        }
        sql += "PRIMARY KEY (\(idName))"
        sql += ")"
        return sql
    }
    func getSqlSelect() -> String {
        let fieldNames = fields.map { $0.name }.joined(separator: ",")
        let sql = "select \(fieldNames) from \(name)"
        return sql
    }
    func getSqlSelect(fields: String) -> String {
        let sql = "select \(fields) from \(name)"
        return sql
    }
    func getSqlInsert() -> String {
        let fieldNames = fields.map { $0.name }.joined(separator: ",")
        let fieldNamesMask = fields.map { _ in "?" }.joined(separator: ",")
        let sql = "insert into \(name) ( \(fieldNames) ) values ( \(fieldNamesMask) ) "
        return sql
    }
    func getSqlUpdate() -> String {
        let fieldNamesMask = fields.map { "\($0.name)=?" }.joined(separator: ",")
        let sql = "update \(name) set \(fieldNamesMask)"
        return sql
    }
    func getSqlUpdate(_ names: [String]) -> String {
        let fieldNamesMask = names.map { "\($0)=?" }.joined(separator: ",")
        let sql = "update \(name) set \(fieldNamesMask)"
        return sql
    }
    func getSqlDelete() -> String {
        let sql = "delete from \(name)"
        return sql
    }
    func getSqlCount() -> String {
        let sql = "select count(*) from \(name)"
        return sql
    }
}

extension TnDbTableMeta {
    func create(_ db: TnDbSqlite) throws {
        let sql = getSqlCreate()

        TnLogger.debug("TnDbTableMeta", "create ...", name, sql)
        try db.execute(sql)
        TnLogger.debug("TnDbTableMeta", "create done", name)
    }
    
    func insert(_ db: TnDbSqlite, item: TItem) throws -> Bool {
        let values = try paramsResolve(item)
        let sql = getSqlInsert()
        return try db.execute(sql, params: values) == 1
    }
    func update(_ db: TnDbSqlite, item: TItem, condition: String) throws -> Bool {
        let values = try paramsResolve(item)
        var sql = getSqlUpdate()
        sql += " where " + condition
        return try db.execute(sql, params: values) > 0
    }
    func update(_ db: TnDbSqlite, names: [String], values: [Any], condition: String) throws -> Bool {
        var sql = getSqlUpdate(names)
        sql += " where " + condition
        return try db.execute(sql, params: values) > 0
    }

    func save(_ db: TnDbSqlite, item: TItem, condition: String) throws -> Bool {
        let count = try count(db, condition: condition)
        if count > 0 {
            return try update(db, item: item, condition: condition)
        } else {
            return try insert(db, item: item)
        }
    }
    
    func remove(_ db: TnDbSqlite, condition: String?) throws -> Bool {
        var sql = getSqlDelete()
        if condition != nil {
            sql += " where " + condition!
        }
        return try db.execute(sql) > 0
    }
    func count(_ db: TnDbSqlite, condition: String? = nil) throws -> Int {
        var sql = getSqlCount()
        if condition != nil {
            sql += " where " + condition!
        }
        return try db.queryScalarInt(sql) ?? 0
    }
    func queryMulti(_ db: TnDbSqlite, condition: String?, order: String? = nil, pageSize: Int = 0, pageIndex: Int = 0, filter: ((TItem) -> Bool)? = nil) throws -> [TItem] {
        var sql = getSqlSelect()
        if condition != nil {
            sql += " where " + condition!
        }
        if order != nil {
            sql += " order by " + order!
        }
        if pageSize > 0 {
            sql += " limit \(pageSize) offset \(pageIndex*pageSize) "
        }
        return try db.queryMulti(sql, getter: { stm in
            if let item = try? itemResolve(stm) {
                if filter == nil || filter!(item) {
                    return item
                }
            }
            return nil as TItem?
        })
    }
    func queryMulti<T>(_ db: TnDbSqlite, fields: String, condition: String?, order: String? = nil, pageSize: Int = 0, pageIndex: Int = 0, getter: (OpaquePointer) throws -> T) throws -> [T] {
        var sql = getSqlSelect()
        if condition != nil {
            sql += " where " + condition!
        }
        if order != nil {
            sql += " order by " + order!
        }
        if pageSize > 0 {
            sql += " limit \(pageSize) offset \(pageIndex*pageSize) "
        }
        return try db.queryMulti(sql, getter: getter)
    }
    
    
    func querySingle(_ db: TnDbSqlite, condition: String?) throws -> TItem? {
        var sql = getSqlSelect()
        if condition != nil {
            sql += " where " + condition!
        }
        return try db.querySingle(sql, getter: itemResolve)
    }

    func queryScalarString(_ db: TnDbSqlite, expression: String, condition: String?) throws -> String {
        var sql = "select \(expression) from \(name)"
        if condition != nil {
            sql += " where " + condition!
        }
        return try db.queryScalarString(sql) ?? ""
    }
    func queryScalarInt(_ db: TnDbSqlite, expression: String, condition: String?) throws -> Int {
        var sql = "select \(expression) from \(name)"
        if condition != nil {
            sql += " where " + condition!
        }
        return try db.queryScalarInt(sql) ?? 0
    }
}

//class TnDbItem {
//    let tableName: String
//
//
//}
