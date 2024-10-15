//
//  TnTransportableProtocol.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/25/24.
//

import Foundation

public protocol TnTransportableProtocol: TnLoggable {
    func send(data: Data, to: [String]?) async throws

    var encoder: TnEncoder { get }
    var decoder: TnDecoder { get }
}

extension TnTransportableProtocol {
    public func send(msgData: TnMessageData, to: [String]?) async throws {
        try await self.send(data: msgData.data, to: to)
    }
    
    public func send(typeCode: UInt8, to: [String]?) async throws {
        try await self.send(data: typeCode.toData(), to: to)
    }

    public func send<TMessage: TnMessageObject>(object: TMessage, to: [String]?) async throws {
        let msgData = try object.toMessageData(encoder: encoder)
        try await self.send(data: msgData.data, to: to)
    }
    
    public func send<T: Codable>(typeCode: UInt8, value: T, to: [String]?) async throws {
        let msgValue = TnMessageValue(typeCode, value)
        try await self.send(object: msgValue, to: to)
    }
    
    public func send<T: Codable>(msgValue: TnMessageValue<T>, to: [String]?) async throws {
        try await self.send(object: msgValue, to: to)
    }
}

