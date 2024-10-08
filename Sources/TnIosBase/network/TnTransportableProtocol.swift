//
//  TnTransportableProtocol.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/25/24.
//

import Foundation

public protocol TnTransportableProtocol: TnLoggable {
    func send(_ data: Data)
    func send(object: TnMessageProtocol) throws
}

extension TnTransportableProtocol {
    public func send(msg: TnMessage) {
        logDebug("send typeCode", msg.typeCode)
        self.send(msg.data)
    }
}

