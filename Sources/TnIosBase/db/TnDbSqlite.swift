//
//  TnDbSqlite.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 08/08/2021.
//

import Foundation
import SQLite3
//import SwiftProtobuf
//import Logging
//import NIOConcurrencyHelpers

protocol TnDb {
}

class TnDbSqlite: TnDb {
    enum DbState {
        case none
        case opened
        case closed
    }
    enum DbError : Error {
        case error(message: String)
    }
    
    private var dbPath: String
    private var db: OpaquePointer?
    private var state: DbState = .none
    
    var errorCode: Int32 = SQLITE_OK
    var errorMessage: String = ""
    
    private let locker = NSLock()
    
    init(_ dbPath: String) {
        self.dbPath = dbPath
        self.state = .none
    }
    
    private func resolveError(_ sql: String, _ code: Int32 = SQLITE_OK) -> Bool {
        errorMessage = ""
        if errorCode != code {
            errorMessage = String(cString: sqlite3_errstr(errorCode)!)
            TnLogger.error(dbPath, "Error: [\(sql)] [\(errorCode)] [\(errorMessage)]")
            return false
        }
        return true
    }
    
    private func executeAndResolve(_ sql: String, _ executor: () -> Int32, code: Int32 = SQLITE_OK) throws -> Bool {
        errorCode = executor()
        let ok = resolveError(sql, code)
        
        if !ok {
            throw DbError.error(message: errorMessage)
        }
        
        return ok
    }
    
    func open() throws -> Void {
        if state == .opened {
            return
        }
        let fileURL = try URL.createFolder("db").subPath(dbPath)
        errorCode = sqlite3_open(fileURL.path, &db)
        guard resolveError("open") else {
            throw DbError.error(message: errorMessage)
        }
        if !resolveError("open") {
            state = .opened
        }
    }

    func close() {
        if state == .opened {
            sqlite3_close(db)
            db = nil
            state = .closed
        }
    }
    
    func queryMulti<T>(_ sql: String, getter: (OpaquePointer) throws -> T?, paramBinder: ((OpaquePointer) throws -> Void)? = nil) throws -> [T] {
        locker.lock()
        defer {
            locker.unlock()
        }
        
        var ret: [T] = []
        var statement: OpaquePointer?
        // prepare statement
        if try executeAndResolve(sql, { sqlite3_prepare_v2(db, sql, -1, &statement, nil) }) {
            // bind params
            try paramBinder?(statement!)
            
            // loop to statement
            while sqlite3_step(statement) == SQLITE_ROW {
                if let item = try getter(statement!) {
                    ret.append(item)
                }
            }
            sqlite3_finalize(statement)
        }
        TnLogger.debug(dbPath, "queryMulti", sql, ret.count)

        return ret
    }
    func queryMulti<T>(_ sql: String, getter: (OpaquePointer) throws -> T?, params: [Any]) throws -> [T] {
        try queryMulti(sql, getter: getter, paramBinder: { stm in TnDbSqlite.asParamBinder(stm: stm, params: params) })
    }

    func querySingle<T>(_ sql: String, getter: (OpaquePointer) throws -> T?, paramBinder: ((OpaquePointer) throws -> Void)? = nil) throws -> T? {
        locker.lock()
        defer {
            locker.unlock()
        }

        var ret: T?
        var statement: OpaquePointer?
        // prepare statement
        if try executeAndResolve(sql, { sqlite3_prepare_v2(db, sql, -1, &statement, nil) }) {
            // bind params
            try paramBinder?(statement!)

            // loop to statement
            if sqlite3_step(statement) == SQLITE_ROW {
                ret = try getter(statement!)
            }
            sqlite3_finalize(statement)
        }
        
        TnLogger.debug(dbPath, "querySingle", sql, ret != nil ? 1 : 0)

        return ret
    }
    func querySingle<T>(_ sql: String, getter: (OpaquePointer) throws -> T?, params: [Any]) throws -> T? {
        try querySingle(sql, getter: getter, paramBinder: { stm in TnDbSqlite.asParamBinder(stm: stm, params: params) })
    }

    func queryScalarString(_ sql: String, paramBinder: ((OpaquePointer) throws -> Void)? = nil) throws -> String? {
        try self.querySingle(
            sql,
            getter: { stm in
                TnDbSqlite.getString(stm, idx: 0)
            },
            paramBinder: paramBinder
        )
    }
    func queryScalarString(_ sql: String, params: [Any]) throws -> String? {
        try queryScalarString(sql, paramBinder: { stm in TnDbSqlite.asParamBinder(stm: stm, params: params) })
    }

    func queryScalarInt(_ sql: String, paramBinder: ((OpaquePointer) throws -> Void)? = nil) throws -> Int? {
        try self.querySingle(
            sql,
            getter: { stm in
                TnDbSqlite.getInt(stm, idx: 0)
            },
            paramBinder: paramBinder
        )
    }
    func queryScalarInt(_ sql: String, params: [Any]) throws -> Int? {
        try queryScalarInt(sql, paramBinder: { stm in TnDbSqlite.asParamBinder(stm: stm, params: params) })
    }
    
    @discardableResult func execute(_ sql: String, paramBinder: ((OpaquePointer) throws -> Void)? = nil) throws -> Int32 {
        locker.lock()
        defer {
            locker.unlock()
        }

        var affectedCount: Int32 = 0
        var statement: OpaquePointer?
        // prepare statement
        if try executeAndResolve(sql, { sqlite3_prepare_v2(db, sql, -1, &statement, nil) }) {
            // bind params
            try paramBinder?(statement!)
            
            // execute
            errorCode = sqlite3_step(statement)
            let ok = resolveError(sql, SQLITE_DONE)

            affectedCount = sqlite3_changes(db)

            // finalize
            sqlite3_finalize(statement)
            
            if !ok {
                throw DbError.error(message: errorMessage)
            }
        }
        
        TnLogger.debug(dbPath, "execute", sql, affectedCount)
        
        return affectedCount
    }
    @discardableResult func execute(_ sql: String, params: [Any]) throws -> Int32 {
        try execute(sql, paramBinder: { stm in TnDbSqlite.asParamBinder(stm: stm, params: params) })
    }

    func lastRowID() -> Int64 {
        return sqlite3_last_insert_rowid(db)
    }
    
    func nextRowID() -> Int64 {
        lastRowID() + 1
    }
}

extension TnDbSqlite {
    static func getInt(_ statement: OpaquePointer, idx: Int32) -> Int {
        return Int(sqlite3_column_int(statement, idx))
    }
    static func getInt32(_ statement: OpaquePointer, idx: Int32) -> Int32 {
        return sqlite3_column_int(statement, idx)
    }
    static func getInt64(_ statement: OpaquePointer, idx: Int32) -> Int64 {
        return sqlite3_column_int64(statement, idx)
    }
    static func getBool(_ statement: OpaquePointer, idx: Int32) -> Bool {
        return sqlite3_column_int(statement, idx) != 0
    }
    static func getDouble(_ statement: OpaquePointer, idx: Int32) -> Double {
        return sqlite3_column_double(statement, idx)
    }
    static func getFloat(_ statement: OpaquePointer, idx: Int32) -> Float {
        return Float(sqlite3_column_double(statement, idx))
    }
    static func getString(_ statement: OpaquePointer, idx: Int32) -> String {
        let cString = sqlite3_column_text(statement, idx)
        return cString != nil ? String(cString: cString!) : ""
    }
    static func getData(_ statement: OpaquePointer, idx: Int32) -> Data {
        let dataLen = sqlite3_column_bytes(statement, idx)
        let dataPoint = sqlite3_column_blob(statement, idx)
        if dataLen > 0 && dataPoint != nil {
            return Data(bytes: dataPoint!, count: Int(dataLen))
        }
        return Data()
    }

    static func getObject<T: Codable>(_ statement: OpaquePointer, idx: Int32) -> T? {
        var ret: T?
        
        let cString = sqlite3_column_text(statement, idx)
        if cString != nil {
            let string = String(cString: cString!)
            ret = string.toObject(T.self)
        }
        return ret
    }
    static func getObject<T: Codable>(_ statement: OpaquePointer, idx: Int32, type: T.Type) -> T? {
        return getObject(statement, idx: idx)
    }
    static func getObject<T: TnJsonable>(_ statement: OpaquePointer, idx: Int32) -> T? {
        var ret: T?
        
        let cString = sqlite3_column_text(statement, idx)
        if cString != nil {
            let string = String(cString: cString!)
            ret = try? T.init(json: string)
        }
        return ret
    }
    static func getObject<T: TnJsonable>(_ statement: OpaquePointer, idx: Int32, type: T.Type) -> T? {
        return getObject(statement, idx: idx)
    }

    static func getObjectArray<T: Codable>(_ statement: OpaquePointer, idx: Int32) -> [T] {
        var ret: [T] = []        
        let cString = sqlite3_column_text(statement, idx)
        if cString != nil {
            let string = String(cString: cString!)
            ret = string.toObjectArray(T.self)
        }
        return ret
    }
    static func getObjectArray<T: Codable>(_ statement: OpaquePointer, idx: Int32, type: T.Type) -> [T] {
        return getObjectArray(statement, idx: idx)
    }
    
    static func setInt(_ statement: OpaquePointer, idx: Int32, value: Int) {
        sqlite3_bind_int(statement, idx+1, Int32(value))
    }
    static func setInt32(_ statement: OpaquePointer, idx: Int32, value: Int32) {
        sqlite3_bind_int(statement, idx+1, value)
    }
    static func setInt64(_ statement: OpaquePointer, idx: Int32, value: Int64) {
        sqlite3_bind_int64(statement, idx+1, value)
    }
    static func setBool(_ statement: OpaquePointer, idx: Int32, value: Bool) {
        sqlite3_bind_int(statement, idx+1, value ? 1 : 0)
    }
    static func setFloat(_ statement: OpaquePointer, idx: Int32, value: Float) {
        sqlite3_bind_double(statement, idx+1, Double(value))
    }
    static func setDouble(_ statement: OpaquePointer, idx: Int32, value: Double) {
        sqlite3_bind_double(statement, idx+1, value)
    }
    static func setString(_ statement: OpaquePointer, idx: Int32, value: String) {
        sqlite3_bind_text(statement, idx+1, NSString(string: value).utf8String, -1, nil)
    }
    static func setData(_ statement: OpaquePointer, idx: Int32, value: Data) {
        _ = value.withUnsafeBytes { buffer in
            sqlite3_bind_blob(statement, idx+1, buffer.baseAddress, Int32(value.count), nil)
        }
//        _ = value.withUnsafeBytes { buffer in
//            sqlite3_bind_blob(statement, idx+1, buffer, Int32(value.count), nil)
//        }
    }
    static func setObject<T: Codable>(_ statement: OpaquePointer, idx: Int32, value: T?) {
        var json: String = ""
        if value != nil {
            json = try! value.toJson()
        }
        sqlite3_bind_text(statement, idx+1, json, -1, nil)
    }
    static func setObject<T: TnJsonable>(_ statement: OpaquePointer, idx: Int32, value: T?) {
        var json: String = ""
        if value != nil {
            json = try! value!.json()
        }
        sqlite3_bind_text(statement, idx+1, json, -1, nil)
    }
    static func setObjectArray<T: Codable>(_ statement: OpaquePointer, idx: Int32, value: [T]?) {
        var json: String = ""
        if value != nil {
            json = try! value.toJson()
        }
        sqlite3_bind_text(statement, idx+1, json, -1, nil)
    }
    
    static func set(_ statement: OpaquePointer, idx: Int32, value: Any) {
        switch value {
        case let val as Data:
            setData(statement, idx: idx, value: val)
            
        case let val as Bool:
            setBool(statement, idx: idx, value: val)

        case let val as Int:
            setInt(statement, idx: idx, value: val)

        case let val as Int64:
            setInt64(statement, idx: idx, value: val)

        case let val as Int32:
            setInt32(statement, idx: idx, value: val)

        case let val as Double:
            setDouble(statement, idx: idx, value: val)

        case let val as Float:
            setFloat(statement, idx: idx, value: val)

        case let val as String:
            setString(statement, idx: idx, value: val)

        default: break
            // do nothing
        }
    }
    static func asParamBinder(stm: OpaquePointer, params: [Any]) {
        params.forEach { idx, param in
            TnDbSqlite.set(stm, idx: Int32(idx), value: param)
        }
    }
    
}
