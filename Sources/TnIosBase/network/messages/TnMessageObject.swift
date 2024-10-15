//
//  TnMessageProtocol.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/15/24.
//

import Foundation

// MARK: TnMessageObject
public protocol TnMessageObject: Codable {
    var typeCode: UInt8 { get }
}

extension TnMessageObject {
    public func toMessageData(encoder: TnEncoder) throws -> TnMessageData {
        do {
            let encodedData = try encoder.encode(self)
            return TnMessageData(typeCode: self.typeCode, data: encodedData)
        } catch {
            TnLogger.error("TnMessage", "Cannot encode from", Self.self, error.localizedDescription)
            throw error
        }
    }
}
