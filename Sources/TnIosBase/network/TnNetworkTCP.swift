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

public struct TnNetworkHostInfo: Codable {
    public let host: String
    public let port: UInt16
    
    public init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }
}

// MARK: TnNetworkServer
public class TnNetworkServer: TnLoggable {
    public let hostInfo: TnNetworkHostInfo
    
    private let listener: NWListener
    private var connectionsByID: [Int: TnNetworkConnectionServer] = [:]
    private let queue: DispatchQueue
    public var delegate: TnNetworkDelegateServer? = nil
    private let transportingInfo: TnNetworkTransportingInfo
    
    public init(hostInfo: TnNetworkHostInfo, queue: DispatchQueue, delegate: TnNetworkDelegateServer?, transportingInfo: TnNetworkTransportingInfo) {
        self.hostInfo = hostInfo
        self.queue = queue
        self.delegate = delegate
        self.transportingInfo = transportingInfo
        
        listener = try! NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: hostInfo.port)!)
        listener.parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(hostInfo.host), port: NWEndpoint.Port(rawValue: hostInfo.port)!)
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
        logDebug("accepted", connection.hostInfo.host)

        let connectionServer = connection as! TnNetworkConnectionServer
        delegate?.tnNetwork(self, accepted: connectionServer)
    }
    
    public func tnNetworkStop(_ connection: TnNetworkConnection, error: Error?) {
        logDebug("disconnected of", connection.hostInfo.host)

        let connectionServer = connection as! TnNetworkConnectionServer
        self.connectionsByID.removeValue(forKey: connectionServer.id)
        delegate?.tnNetwork(self, stopped: connectionServer, error: error)
    }

    public func tnNetwork(_ connection: TnNetworkConnection, receivedData: Data) {
        logDebug("received from", connection.hostInfo.host, receivedData.count)

        let connectionServer = connection as! TnNetworkConnectionServer
        delegate?.tnNetwork(self, connection: connectionServer, receivedData: receivedData)
    }
    
    public func tnNetwork(_ connection: TnNetworkConnection, sentData: Data) {
        logDebug("sent to", connection.hostInfo.host, sentData.count)

        let connectionServer = connection as! TnNetworkConnectionServer
        delegate?.tnNetwork(self, connection: connectionServer, sentData: sentData)
    }
}

extension TnNetworkServer: TnTransportableProtocol {
    public var encoder: TnEncoder {
        transportingInfo.encoder
    }
    
    public var decoder: any TnDecoder {
        transportingInfo.decoder
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
public class TnNetworkConnection:/* TnNetwork, */TnLoggable {
    public let hostInfo: TnNetworkHostInfo

    public var delegate: TnNetworkDelegate? = nil
    private let connection: NWConnection
    private let queue: DispatchQueue
    private var dataQueue: Data = .init()
    
    private let transportingInfo: TnNetworkTransportingInfo
        
    public init(nwConnection: NWConnection, queue: DispatchQueue?, delegate: TnNetworkDelegate?, transportingInfo: TnNetworkTransportingInfo) {
        self.connection = nwConnection
        self.hostInfo = nwConnection.endpoint.getHostInfo()
        self.queue = queue ?? DispatchQueue(label: "\(Self.Type.self).queue")
        self.delegate = delegate
        self.transportingInfo = transportingInfo
        
        logDebug("inited incoming", hostInfo.host)
    }
    
    public init(hostInfo: TnNetworkHostInfo, queue: DispatchQueue?, delegate: TnNetworkDelegate?, transportingInfo: TnNetworkTransportingInfo) {
        self.hostInfo = hostInfo
        self.connection = NWConnection(host: NWEndpoint.Host(hostInfo.host), port: NWEndpoint.Port(rawValue: hostInfo.port)!, using: .tcp)
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
    public var encoder: TnEncoder {
        transportingInfo.encoder
    }
    
    public var decoder: any TnDecoder {
        transportingInfo.decoder
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
    public func getHostInfo() -> TnNetworkHostInfo {
        switch self {
        case .hostPort(let host, let port):
            return TnNetworkHostInfo(host: "\(host)", port: port.rawValue)
        default:
            return TnNetworkHostInfo(host: "", port: 0)
        }
    }
}
