//
//  TnNetworkUDP.swift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 11/15/21.
//

import Foundation
import Network

class TnNetworkUDP {
    let localHost: NWEndpoint.Host
    let port: NWEndpoint.Port
    let connection: NWConnection
    let localIP: String
    let broadcastIP: String
    
    private let onOpenSuccess: (() -> Void)?
    private let onOpenError: ((TnNetworkError) -> Void)?
    
    init(port: Int32 = 50005, onSuccess: (() -> Void)? = nil, onError: ((TnNetworkError) -> Void)? = nil) {
        self.port = NWEndpoint.Port(rawValue: UInt16(port))!
        guard let ip = TnNetworkHelper.getAddress(for: .wifi) else {
            fatalError("You must connect to WIFI first !".lz())
        }
        self.localIP = ip.address
        self.broadcastIP = ip.address.prefix(last: ".")! + ".255"
        self.localHost = NWEndpoint.Host(ip.address)
        
        self.onOpenSuccess = onSuccess
        self.onOpenError = onError
        self.connection = NWConnection(host: self.localHost, port: self.port, using: .udp)
        self.connection.stateUpdateHandler = { newState in
            switch (newState) {
            case .setup:
                TnLogger.debug("TnNetworkUDP", "setup")
            case .ready:
                TnLogger.debug("TnNetworkUDP", "ready")
                self.onOpenSuccess?()
            case .preparing:
                TnLogger.debug("TnNetworkUDP", "preparing")
            case .cancelled:
                TnLogger.debug("TnNetworkUDP", "cancelled")
            case .waiting(_):
                TnLogger.debug("TnNetworkUDP", "waiting")
            case .failed(let ex):
                self.onOpenError?(TnNetworkError.socketError(description: ex.localizedDescription))
            @unknown default:
                break
            }
        }
        self.connection.start(queue: .global())
    }
    
    func isOpened() -> Bool {
        return connection.state == .ready || connection.state == .preparing
    }

    func close() {
        print("close")
        self.connection.cancel()
    }
    
    func send(_ content: Data, onSuccess: (() -> Void)? = nil, onError: ((TnNetworkError) -> Void)? = nil, onComplete: (() -> Void)? = nil) {
        print("send")
        self.connection.send(content: content, completion: NWConnection.SendCompletion.contentProcessed({ error in
            if let error = error, let onError = onError {
                TnLogger.debug("TnNetworkUDP", "send error", error.localizedDescription)
                onError(TnNetworkError.socketError(description: error.localizedDescription))
            } else {
                TnLogger.debug("TnNetworkUDP", "send success")
                onSuccess?()
            }
            onComplete?()
        }))
    }

    func send(_ content: String, onSuccess: (() -> Void)? = nil, onError: ((TnNetworkError) -> Void)? = nil, onComplete: (() -> Void)? = nil) {
        guard let data = content.data(using: .utf8) else {
            onError?(TnNetworkError.socketError(description: "Cannot serialize packet"))
            return
        }
        self.send(data, onSuccess: onSuccess, onError: onError, onComplete: onComplete)
    }
    
    func send(_ packet: TnNetworkPacket, onSuccess: (() -> Void)? = nil, onError: ((TnNetworkError) -> Void)? = nil, onComplete: (() -> Void)? = nil) {
        guard let data = try? packet.message.toJsonData() else {
            onError?(TnNetworkError.socketError(description: "Cannot serialize packet"))
            return
        }
        self.send(data, onSuccess: onSuccess, onError: onError, onComplete: onComplete)
    }

    
    func receive(onSuccess: @escaping (TnNetworkPacket) -> Void, onError: ((TnNetworkError) -> Void)? = nil, onComplete: (() -> Void)? = nil) {
        print("receive")
        self.connection.receiveMessage { (data, context, isComplete, error) in
            if isComplete {
                if let error = error, let onError = onError {
                    TnLogger.debug("TnNetworkUDP", "receive error", error.localizedDescription)
                    onError(TnNetworkError.socketError(description: error.localizedDescription))
                } else if let data = data {
                    if let messageValid = try? data.tnToObjectFromJSON(TnNetworkMessage.self) {
                        TnLogger.debug("TnNetworkUDP", "receive success")
//                        self.onReceiveSuccess?(TnNetworkPacket(messageValid, ip: ""))
                        onSuccess(TnNetworkPacket(messageValid, ip: context?.identifier ?? ""))
                    }
                }
                onComplete?()
            }
        }
    }
}
