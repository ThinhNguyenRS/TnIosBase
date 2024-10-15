//
//  TnMessage.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/17/24.
//

import Foundation

// MARK: TnMessage
public struct TnMessageData {
    private(set) var data: Data
    public var typeCode: UInt8 {
        data[0]
    }
    
    public init(data: Data) {
        self.data = data
    }
    
    public init(typeCode: UInt8, data: Data) {
        self.data = Data(capacity: data.count + 1)
        self.data.append(typeCode)
        self.data.append(data)
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
