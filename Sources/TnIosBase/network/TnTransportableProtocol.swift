//
//  TnTransportableProtocol.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/25/24.
//

import Foundation

public protocol TnTransportableProtocol: TnLoggable {
    var LOG_NAME: String { get }
    func send(_ data: Data)
}

extension TnTransportableProtocol {
    public func send(msg: TnMessage) {
        TnLogger.debug(LOG_NAME, "send typeCode", msg.typeCode)
        self.send(msg.data)
    }
    
    public func send(object: TnMessageProtocol) throws {
        self.send(msg: try object.toMessage())
    }
}

