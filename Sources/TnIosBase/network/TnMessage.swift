//
//  TnMessage.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/17/24.
//

import Foundation

// MARK: TnMessageProtocol
public protocol TnMessageProtocol: Codable {
    var typeCode: UInt8 { get }
}

extension TnMessageProtocol {
    public func toMessage(encoder: TnEncoder) throws -> TnMessage {
        try TnMessage(object: self, encoder: encoder)
    }
}

// MARK: TnMessage
public struct TnMessage {
    private(set) var data: Data
    public var typeCode: UInt8 {
        data[0]
    }
    
    public init(data: Data) {
        self.data = data
    }
    
    public init<T: TnMessageProtocol>(object: T, encoder: TnEncoder) throws {
        do {
            self.data = Data()
            self.data.append(object.typeCode)
            
            let encodedData = try encoder.encode(object)
            self.data.append(encodedData)
        } catch {
            TnLogger.error("TnMessage", "Cannot encode from", T.self, error.localizedDescription)
            throw error
        }
    }
    
    public func toObject<T: Codable>(decoder: TnDecoder) -> T? {
        let encodedData = data[1...]
        do {
            return try decoder.decode(T.self, from: encodedData) as T
        } catch {
            TnLogger.error("TnMessage", "Cannot decode to", T.self, error.localizedDescription)
        }
        return nil
    }
}

// MARK: TnMessageIdentifier
public struct TnMessageIdentifier: TnMessageProtocol {
    public var typeCode: UInt8 { 0 }
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}
