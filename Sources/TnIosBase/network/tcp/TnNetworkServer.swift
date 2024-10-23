//
//  TnNetworkServer.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/15/24.
//

import Foundation
import Network

// MARK: TnNetworkServer
public class TnNetworkServer: TnLoggable {
    public let hostInfo: TnNetworkHostInfo
    
    private let listener: NWListener
    
    @TnLockable private var connections: [TnNetworkConnection] = []
    
    private let queue: DispatchQueue
    public var delegate: TnNetworkDelegateServer? = nil
    private let transportingInfo: TnNetworkTransportingInfo
    
    public init(hostInfo: TnNetworkHostInfo, delegate: TnNetworkDelegateServer?, transportingInfo: TnNetworkTransportingInfo) {
        self.hostInfo = hostInfo
        self.queue = DispatchQueue(label: "\(Self.self).queue")
        self.delegate = delegate
        self.transportingInfo = transportingInfo
        
        listener = try! NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: hostInfo.port)!)
        listener.parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(hostInfo.host), port: NWEndpoint.Port(rawValue: hostInfo.port)!)
    }
    
    deinit {
        self.stop()
    }
    
    public var hasConnections: Bool {
        !connections.isEmpty
    }
    
    public func hasConnection(name: String) -> Bool {
        connections.contains(where: { $0.name == name })
    }
}

// MARK: handle state
extension TnNetworkServer {
    private func stateDidChange(to newState: NWListener.State) {
        switch newState {
        case .ready:
            logDebug("start !")
            delegate?.tnNetworkReady(self)
        case .waiting(let error):
            logDebug("state waiting", error)
            delegate?.tnNetworkStop(self, error: error)
        case .failed(let error):
            logDebug("state failed", error)
            delegate?.tnNetworkStop(self, error: error)
        case .cancelled:
            logDebug("state cancelled")
            delegate?.tnNetworkStop(self, error: nil)
        default:
            break
        }
    }
}

// MARK: start/stop
extension TnNetworkServer {
    public func stop() {
        logDebug("stop ...")

        self.listener.stateUpdateHandler = nil
        self.listener.newConnectionHandler = nil
        for connection in self.connections {
            connection.stop()
        }
        self.listener.cancel()
        
        logDebug("stop !")
        delegate?.tnNetworkStop(self, error: nil)
    }
    
    public func start() {
        logDebug("start ...")
        
        listener.stateUpdateHandler = self.stateDidChange(to:)
        listener.newConnectionHandler = self.didAccept(nwConnection:)
        
        listener.start(queue: queue)
    }
}

// MARK: accept
extension TnNetworkServer {
    private func didAccept(nwConnection: NWConnection) {
        logDebug("connection accepting")
        let connection = TnNetworkConnection(nwConnection: nwConnection, delegate: self, transportingInfo: transportingInfo)
        self.connections.append(connection)
        connection.start()

        logDebug("connections", self.connections.map { $0.name })
    }
}

// MARK: TnNetworkDelegate for client
extension TnNetworkServer: TnNetworkDelegate {
    public func tnNetworkReady(_ connection: TnNetworkConnection) {
        logDebug("connection accepted \(connection.hostInfo.host):\(connection.hostInfo.port):\(connection.name)")
    }
    
    public func tnNetworkStop(_ connection: TnNetworkConnection, error: Error?) {
        logDebug("connection disconnected", connection.name)

        // remove the connection from dict
        self.connections.removeAll(where: { $0.name == connection.name})
        delegate?.tnNetworkStop(self, connection: connection, error: error)

        logDebug("connections", self.connections.map { $0.name })
    }
}

// MARK: TnTransportableProtocol
extension TnNetworkServer: TnTransportableProtocol {
    public var encoder: TnEncoder {
        transportingInfo.encoder
    }
    
    public var decoder: any TnDecoder {
        transportingInfo.decoder
    }

    public func send(data: Data, to: [String]?) async throws {
        for connection in connections {
            if to == nil || to!.contains(connection.name) {
                try await connection.send(data: data, to: nil)
            }
        }
    }
}
