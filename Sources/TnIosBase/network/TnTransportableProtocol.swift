//
//  TnTransportableProtocol.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/25/24.
//

import Foundation

public protocol TnTransportableProtocol: TnLoggable {
    func send(_ data: Data)
}

extension TnTransportableProtocol {
    public func send(msg: TnMessage) {
        logDebug("send typeCode", msg.typeCode)
        self.send(msg.data)
    }
    
    public func send(object: TnMessageProtocol, encoder: TnEncoder) throws {
        self.send(msg: try object.toMessage(encoder: encoder))
    }
}

