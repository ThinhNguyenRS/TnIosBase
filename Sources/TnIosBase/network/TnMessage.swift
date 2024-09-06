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

public struct TnMessage {
    private(set) var data: Data
    public var typeCode: UInt8 {
        data[0]
    }
    
    public init(data: Data) {
        self.data = data
    }
    
    public init?<T: TnMessageProtocol>(object: T) {
        do {
            let data = try object.toJsonData()
            self.data = Data()
            self.data.append(object.typeCode)
            self.data.append(data)
        } catch {
            TnLogger.error("TnMessage", "Cannot encode from", T.self, object, error.localizedDescription)
            return nil
        }
    }
    
    public func toObject<T: Decodable>() -> T? {
        let jsonData = data.suffix(from: 1)
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: jsonData) as T
        } catch {
            let jsonString = String(data: jsonData, encoding: .utf8)
            TnLogger.error("TnMessage", "Cannot decode to", T.self, jsonString, error.localizedDescription)
        }
        return nil
    }
}

extension TnMessageProtocol {
    public func toMessage() -> TnMessage {
        TnMessage(object: self)!
    }
}

extension Data {
    public func toMessage() -> TnMessage {
        TnMessage(data: self)
    }
}
