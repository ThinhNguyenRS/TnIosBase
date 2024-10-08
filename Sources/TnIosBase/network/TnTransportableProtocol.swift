//
//  TnTransportableProtocol.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/25/24.
//

import Foundation

public protocol TnTransportableProtocol: TnLoggable {
    func send(_ data: Data) async throws
    var encoder: TnEncoder { get }
    var decoder: TnDecoder { get }
}

extension TnTransportableProtocol {
    public func send(msg: TnMessage) async throws {
        logDebug("send typeCode", msg.typeCode)
        try await self.send(msg.data)
    }
    
    public func send(object: TnMessageProtocol) async throws {
        try await self.send(msg: object.toMessage(encoder: encoder))
    }
}

