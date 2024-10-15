//
//  TnTransportableProtocol.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/25/24.
//

import Foundation

public protocol TnTransportableProtocol: TnLoggable {
//    func send(_ data: Data) async throws
    func send(_ data: Data, to: [String]?) async throws

    var encoder: TnEncoder { get }
    var decoder: TnDecoder { get }
}

extension TnTransportableProtocol {
    public func send(msgData: TnMessageData, to: [String]? = nil) async throws {
        try await self.send(msgData.data, to: to)
    }
    
    public func send<TMessage: TnMessageObject>(object: TMessage, to: [String]? = nil) async throws {
        try await self.send(msgData: object.toMessageData(encoder: encoder), to: to)
    }
    
    public func send<T: Codable>(typeCode: UInt8, value: T?, to: [String]? = nil) async throws {
        let msgValue = TnMessageValue(typeCode, value)
        try await self.send(object: msgValue, to: to)
    }
    
    public func send<T: Codable>(msgValue: TnMessageValue<T>, to: [String]? = nil) async throws {
        try await self.send(object: msgValue, to: to)
    }
}

