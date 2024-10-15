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
    private var connections: [TnNetworkConnection] = []
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
    
    public var connectionCount: Int {
        connections.count
    }
    
    public var hasConnections: Bool {
        !connections.isEmpty
    }
}

// MARK: handle state
extension TnNetworkServer {
    private func stateDidChange(to newState: NWListener.State) {
        switch newState {
        case .ready:
            logDebug("ready")
            delegate?.tnNetworkReady(self)
        case .waiting(let error):
            logDebug("waiting", error)
            delegate?.tnNetworkStop(self, error: error)
        case .failed(let error):
            logDebug("failed", error)
            delegate?.tnNetworkStop(self, error: error)
        case .cancelled:
            logDebug("cancelled")
            delegate?.tnNetworkStop(self, error: nil)
        default:
            break
        }
    }
}

// MARK: accept
extension TnNetworkServer {
    private func didAccept(nwConnection: NWConnection) {
        logDebug("accepting")
        
        let connection = TnNetworkConnection(nwConnection: nwConnection, delegate: self, transportingInfo: transportingInfo)
        self.connections.append(connection)
        connection.start()
    }
}

// MARK: start/stop
extension TnNetworkServer {
    public func stop() {
        self.listener.stateUpdateHandler = nil
        self.listener.newConnectionHandler = nil
        for connection in self.connections {
            connection.stop()
        }
        self.listener.cancel()
        
        logDebug("stopped")
        delegate?.tnNetworkStop(self, error: nil)
    }
    
    public func start() {
        logDebug("starting...")
        
        listener.stateUpdateHandler = self.stateDidChange(to:)
        listener.newConnectionHandler = self.didAccept(nwConnection:)
        
        listener.start(queue: queue)
    }
}

// MARK: TnNetworkDelegate for client
extension TnNetworkServer: TnNetworkDelegate {
    public func tnNetworkReady(_ connection: TnNetworkConnection) {
        logDebug("accepted", connection.hostInfo.host)

        delegate?.tnNetworkAccepted(self, connection: connection)
    }
    
    public func tnNetworkStop(_ connection: TnNetworkConnection, error: Error?) {
        logDebug("disconnected of", connection.hostInfo.host)
        self.connections.removeAll(where: { c in c.name == connection.name})
        delegate?.tnNetworkStop(self, connection: connection, error: error)
    }

    public func tnNetworkReceived(_ connection: TnNetworkConnection, data: Data) {
        logDebug("received from", connection.hostInfo.host)
        
        // check identifier msg
        if connection.name.isEmpty {
            if let msg = TnMessageSystem.toMessageIndentifier(data: data, decoder: transportingInfo.decoder) {
                connection.setName(msg.value)
//                if var connectionIdx = connections.firstIndex(where: { $0 == connection}) {
//                    logDebug("receive name", msg.value)
//                    connection.setName(msg.value)
//                    connections[connectionIdx] = connection
//                    
//                }
                logDebug("connection names", connections.map { $0.name })
            }
        }
        delegate?.tnNetworkReceived(self, connection: connection, data: data)
    }

    public func tnNetworkSent(_ connection: TnNetworkConnection, count: Int) {
        logDebug("sent to", connection.hostInfo.host)

        delegate?.tnNetworkSent(self, connection: connection, count: count)
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
