//
//  TnNetworkTCP.swift
//  tCamera
//
//  Created by Thinh Nguyen on 9/4/24.
//

import Foundation
import Network

public protocol TnNetworkDelegate {
    func tnNetwork(_ connection: TnNetworkConnection, receivedData: Data)
    func tnNetwork(_ connection: TnNetworkConnection, sentData: Data)

    func tnNetworkReady(_ connection: TnNetworkConnection)
    func tnNetworkStop(_ connection: TnNetworkConnection, error: Error?)
}

public protocol TnNetworkDelegateServer {
    func tnNetworkReady(_ server: TnNetworkServer)
    func tnNetworkStop(_ server: TnNetworkServer, error: Error?)

    func tnNetwork(_ server: TnNetworkServer, accepted: TnNetworkConnectionServer)
    func tnNetwork(_ server: TnNetworkServer, stopped: TnNetworkConnectionServer, error: Error?)
    func tnNetwork(_ server: TnNetworkServer, connection: TnNetworkConnection, receivedData: Data)
    func tnNetwork(_ server: TnNetworkServer, connection: TnNetworkConnection, sentData: Data)
}

public protocol TnNetwork {
    var host: String {get}
    var port: UInt16 {get}
}

// MARK: TnNetworkServer
public class TnNetworkServer: TnNetwork, TnLoggable {
    public let host: String
    public let port: UInt16
    
    private let listener: NWListener
    private var connectionsByID: [Int: TnNetworkConnectionServer] = [:]
    private let queue: DispatchQueue
    private let delegate: TnNetworkDelegateServer?
    private let transportingInfo: TnNetworkTransportingInfo
    
    public init(host: String, port: UInt16, queue: DispatchQueue, delegate: TnNetworkDelegateServer?, transportingInfo: TnNetworkTransportingInfo) {
        self.host = host
        self.port = port
        self.queue = queue
        self.delegate = delegate
        self.transportingInfo = transportingInfo
        
        listener = try! NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!)
        listener.parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!)
    }
    
    deinit {
        self.stop()
    }
    
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
    
    private func didAccept(nwConnection: NWConnection) {
        logDebug("accepting")
        
        let connection = TnNetworkConnectionServer(nwConnection: nwConnection, queue: queue, delegate: self, transportingInfo: transportingInfo)
        self.connectionsByID[connection.id] = connection
        connection.start()
    }
    
    private func stop() {
        self.listener.stateUpdateHandler = nil
        self.listener.newConnectionHandler = nil
        for connection in self.connectionsByID.values {
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
    
    public func sendAsync(_ data: Data) async throws {
        for connection in connectionsByID.values {
            try await connection.sendAsync(data)
        }
    }
    
    public var connectionCount: Int {
        connectionsByID.count
    }
    
    public var hasConnections: Bool {
        !connectionsByID.isEmpty
    }
}

extension TnNetworkServer: TnNetworkDelegate {
    public func tnNetworkReady(_ connection: TnNetworkConnection) {
        logDebug("accepted", connection.host)

        let connectionServer = connection as! TnNetworkConnectionServer
        delegate?.tnNetwork(self, accepted: connectionServer)
    }
    
    public func tnNetworkStop(_ connection: TnNetworkConnection, error: Error?) {
        logDebug("disconnected of", connection.host)

        let connectionServer = connection as! TnNetworkConnectionServer
        self.connectionsByID.removeValue(forKey: connectionServer.id)
        delegate?.tnNetwork(self, stopped: connectionServer, error: error)
    }

    public func tnNetwork(_ connection: TnNetworkConnection, receivedData: Data) {
        logDebug("received from", connection.host, receivedData.count)

        let connectionServer = connection as! TnNetworkConnectionServer
        delegate?.tnNetwork(self, connection: connectionServer, receivedData: receivedData)
    }
    
    public func tnNetwork(_ connection: TnNetworkConnection, sentData: Data) {
        logDebug("sent to", connection.host, sentData.count)

        let connectionServer = connection as! TnNetworkConnectionServer
        delegate?.tnNetwork(self, connection: connectionServer, sentData: sentData)
    }
}

extension TnNetworkServer: TnTransportableProtocol {
    public func send(object: TnMessageProtocol) throws {
        try self.send(object.toMessage(encoder: transportingInfo.encoder).data)
    }
    
    public func send(_ data: Data) {
        for connection in connectionsByID.values {
            connection.send(data)
        }
    }
}

// MARK: TnNetworkReceiveData
public struct TnNetworkReceiveData {
    public let content: Data?
    public let context: NWConnection.ContentContext?
    public let isComplete: Bool
    public let error: NWError?
}

// MARK: TnNetworkConnection
public class TnNetworkConnection: TnNetwork, TnLoggable {
    public let host: String
    public let port: UInt16
    
    private let delegate: TnNetworkDelegate?
    private let connection: NWConnection
    private let queue: DispatchQueue
    private var dataQueue: Data = .init()
    
    private let transportingInfo: TnNetworkTransportingInfo
        
    public init(nwConnection: NWConnection, queue: DispatchQueue?, delegate: TnNetworkDelegate?, transportingInfo: TnNetworkTransportingInfo) {
        self.connection = nwConnection
        let hp = nwConnection.endpoint.getHostAndPort()
        self.host = hp.host
        self.port = hp.port
        self.queue = queue ?? DispatchQueue(label: "\(Self.Type.self).queue")
        self.delegate = delegate
        self.transportingInfo = transportingInfo
        
        logDebug("inited incoming", host)
    }
    
    public init(host: String, port: UInt16, queue: DispatchQueue?, delegate: TnNetworkDelegate?, transportingInfo: TnNetworkTransportingInfo) {
        self.host = host
        self.port = port
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
        self.queue = queue ?? DispatchQueue(label: "\(Self.Type.self).queue")
        self.delegate = delegate
        self.transportingInfo = transportingInfo
        
        logDebug("inited client")
    }
    
    deinit {
        self.stop()
    }
    
    
    private func stop(error: Error?) {
        connection.stateUpdateHandler = nil
        connection.cancel()
        delegate?.tnNetworkStop(self, error: error)
    }
    
    private func onStateChanged(to state: NWConnection.State) {
        logDebug("state changed", state)
        
        switch state {
        case .ready:
            logDebug("ready", "maximumDatagramSize", connection.maximumDatagramSize)
            startReceiveAsync()
            delegate?.tnNetworkReady(self)
        case .waiting(let error):
            logDebug("waiting", error)
            stop(error: error)
        case .failed(let error):
            logDebug("failed", error)
            stop(error: error)
        case .cancelled:
            logDebug("cancelled")
//            stop(error: nil)
        default:
            break
        }
    }
    
    private func receiveChunkAsync() async -> TnNetworkReceiveData {
        return await withCheckedContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: transportingInfo.MTU) { content, context, isComplete, error in
                continuation.resume(
                    returning: TnNetworkReceiveData(content: content, context: context, isComplete: isComplete, error: error)
                )
            }
        }
    }

    private func receiveAsync() async throws -> [Data]? {
        let result = await receiveChunkAsync()
        
        var parts: [Data]? = nil
        
        if let error = result.error {
            stop(error: error)
            throw TnAppError.general(message: "Receive error: \(error.localizedDescription)")
        } else if result.isComplete {
            stop(error: nil)
            throw TnAppError.general(message: "Receive error: The connection is closed")
        } else {
            if let data = result.content, !data.isEmpty {
                // receive data, add to queue
                dataQueue.append(data)
                
                // detect EOM
                if dataQueue.count > transportingInfo.EOM.count {
                    let eomAssume = dataQueue.suffix(transportingInfo.EOM.count)
                    if eomAssume == transportingInfo.EOM {
                        // get received data
                        let receivedData = dataQueue[0...dataQueue.count-transportingInfo.EOM.count-1]
                        logDebug("received", receivedData.count)
                        
                        parts = receivedData.split(separator: transportingInfo.EOM)

                        // reset data queue
                        dataQueue.removeAll()
                    }
                }
            }
        }
        
        return parts
    }
    
    private func startReceiveAsync() {
        Task {
            let sleepNanos: UInt64 = 10*1000*1000
            while connection.state == .ready {
                if let parts = try await receiveAsync() {
                    for part in parts {
                        // signal
                        delegate?.tnNetwork(self, receivedData: part)
                    }
                }
                
                try await Task.sleep(nanoseconds: sleepNanos)
            }
        }
    }

    public func sendAsync(_ data: Data?) async throws {
        guard connection.state == .ready else {
            return
        }

        // append EOM
        var dataToSend = data
        if dataToSend != nil {
            dataToSend!.append(transportingInfo.EOM)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.connection.send(content: dataToSend, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed( { [self] error in
                if let error = error {
                    logError("send error", error.localizedDescription)
                    stop(error: error)
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: Void())
                }
            }))
        }
    }

    public func start() {
        logDebug("starting")

        connection.stateUpdateHandler = self.onStateChanged(to:)        
        connection.start(queue: queue)
    }
    
    public func stop() {
        stop(error: nil)
    }
}

extension TnNetworkConnection: TnTransportableProtocol {
    public func send(object: TnMessageProtocol) throws {
        try self.send(object.toMessage(encoder: transportingInfo.encoder).data)
    }
    
    public func send(_ data: Data) {
        Task {
            try await tnDoCatchAsync(name: "send") {
                try await self.sendAsync(data)
            }
        }
    }
}

// MARK: TnNetworkConnectionServer
public class TnNetworkConnectionServer: TnNetworkConnection {
    private static var nextID: Int = 0
    let id: Int

    override init(nwConnection: NWConnection, queue: DispatchQueue?, delegate: TnNetworkDelegate?, transportingInfo: TnNetworkTransportingInfo) {
        self.id = Self.nextID
        Self.nextID += 1
        super.init(nwConnection: nwConnection, queue: queue, delegate: delegate, transportingInfo: transportingInfo)
    }
}

// MARK: NWEndpoint
extension NWEndpoint {
    public func getHostAndPort() -> (host: String, port: UInt16) {
        switch self {
        case .hostPort(let host, let port):
            return (host: "\(host)", port: port.rawValue)
        default:
            return (host: "", port: 0)
        }
    }
}
