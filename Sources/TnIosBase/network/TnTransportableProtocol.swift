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
    public func send(msg: TnMessage, to: [String]? = nil) async throws {
        try await self.send(msg.data, to: to)
    }
    
    public func send(object: TnMessageProtocol, to: [String]? = nil) async throws {
        try await self.send(msg: object.toMessage(encoder: encoder), to: to)
    }
}

