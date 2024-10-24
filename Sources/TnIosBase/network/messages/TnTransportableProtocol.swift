//
//  TnTransportableProtocol.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/25/24.
//

import Foundation

public protocol TnTransportableProtocol: TnLoggable {
    func send(data: Data) async throws

    var encoder: TnEncoder { get }
    var decoder: TnDecoder { get }
}

extension TnTransportableProtocol {
    public func send(msgData: TnMessageData) async throws {
        try await self.send(data: msgData.data)
    }
    
    public func send(typeCode: UInt8) async throws {
        try await self.send(data: typeCode.toData())
    }

    public func send<TMessage: TnMessageObject>(object: TMessage) async throws {
        let msgData = try object.toMessageData(encoder: encoder)
        try await self.send(data: msgData.data)
    }
    
    public func send<T: Codable>(typeCode: UInt8, value: T) async throws {
        let msgValue = TnMessageValue(typeCode, value)
        try await self.send(object: msgValue)
    }
    
    public func send<T: Codable>(msgValue: TnMessageValue<T>) async throws {
        try await self.send(object: msgValue)
    }
}

