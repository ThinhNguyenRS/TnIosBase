//
//  TnMessage.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/17/24.
//

import Foundation

public protocol TnMessageProtocol: Codable {
    var typeCode: UInt8 { get }
}

extension TnMessageProtocol {
    public func toMessage() throws -> TnMessage {
        try TnMessage(object: self)
    }
}

public struct TnMessage {
    private(set) var data: Data
    public var typeCode: UInt8 {
        data[0]
    }
    
    public init(data: Data) {
        self.data = data
    }
    
    public init<T: TnMessageProtocol>(object: T) throws {
        do {
            self.data = Data()
            self.data.append(object.typeCode)
            
            let jsonData = try object.toJsonData()
            self.data.append(jsonData)
        } catch {
            TnLogger.error("TnMessage", "Cannot encode from", T.self, error.localizedDescription)
            throw error
        }
    }
    
    public func toObject<T: Codable>() -> T? {
        let jsonData = data.suffix(from: 1)
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: jsonData) as T
        } catch {
            TnLogger.error("TnMessage", "Cannot decode to", T.self, error.localizedDescription)
        }
        return nil
    }
    
    public func jsonString() -> String {
        let jsonData = data.suffix(from: 1)
        return String(data: jsonData, encoding: .utf8)!
    }
}
