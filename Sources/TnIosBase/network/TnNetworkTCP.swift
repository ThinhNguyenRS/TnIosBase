//
//  TnNetworkTCP.swift
//  tCamera
//
//  Created by Thinh Nguyen on 9/4/24.
//

import Foundation
import Network

public protocol TnNetworkDelegate {
//    func tnNetwork(_ connection: TnNetworkConnection, receivedData: Data)
//    func tnNetwork(_ connection: TnNetworkConnection, sentData: Data)
    
    func tnNetworkSent(_ connection: TnNetworkConnection, count: Int)
    func tnNetworkReceived(_ connection: TnNetworkConnection, data: Data)
    
    func tnNetworkReady(_ connection: TnNetworkConnection)
    func tnNetworkStop(_ connection: TnNetworkConnection, error: Error?)
}

public protocol TnNetworkDelegateServer {
    func tnNetworkReady(_ server: TnNetworkServer)
    func tnNetworkStop(_ server: TnNetworkServer, error: Error?)
    func tnNetworkStop(_ server: TnNetworkServer, connection: TnNetworkConnection, error: Error?)
    func tnNetworkAccepted(_ server: TnNetworkServer, connection: TnNetworkConnection)
    
    func tnNetworkSent(_ server: TnNetworkServer, connection: TnNetworkConnection, count: Int)
    func tnNetworkReceived(_ server: TnNetworkServer, connection: TnNetworkConnection, data: Data)
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
        
        let connection = TnNetworkConnection(nwConnection: nwConnection, delegate: self, transportingInfo: transportingInfo)
        self.connections.append(connection)
        connection.start()
    }
    
    private func stop() {
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
    
    public var connectionCount: Int {
        connections.count
    }
    
    public var hasConnections: Bool {
        !connections.isEmpty
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
            if let msg = TnMessageIdentifier.from(data: data, decoder: transportingInfo.decoder) {
                connection.setName(msg.name)
            }
        }
        delegate?.tnNetworkReceived(self, connection: connection, data: data)
    }

    public func tnNetworkSent(_ connection: TnNetworkConnection, count: Int) {
        logDebug("sent to", connection.hostInfo.host)

        delegate?.tnNetworkSent(self, connection: connection, count: count)
    }
}

extension TnNetworkServer: TnTransportableProtocol {
    public var encoder: TnEncoder {
        transportingInfo.encoder
    }
    
    public var decoder: any TnDecoder {
        transportingInfo.decoder
    }

    public func send(_ data: Data) async throws {
        for connection in connections {
            try await connection.send(data)
        }
    }
}

// MARK: TnNetworkConnection
public class TnNetworkConnection: TnLoggable {
    typealias TSize = UInt32
    
    public let hostInfo: TnNetworkHostInfo
    public var delegate: TnNetworkDelegate? = nil
    private let connection: NWConnection
    private let queue: DispatchQueue
    private let transportingInfo: TnNetworkTransportingInfo
    private let receiveQueueQueue: DispatchQueue
    
    public private(set) var name: String = ""
    public func setName(_ name: String) {
        if name.isEmpty {
            self.name = name
        }
    }
    
    private let isClient: Bool
    
    public init(nwConnection: NWConnection, delegate: TnNetworkDelegate?, transportingInfo: TnNetworkTransportingInfo) {
        self.isClient = false
        self.connection = nwConnection
        self.hostInfo = nwConnection.endpoint.getHostInfo()
        self.queue = DispatchQueue(label: "\(Self.self).queue")
        self.receiveQueueQueue = DispatchQueue(label: "\(Self.self).receiveQueueQueue")
        self.delegate = delegate
        self.transportingInfo = transportingInfo
        
        logDebug("inited incoming", hostInfo.host)
    }
    
    public init(hostInfo: TnNetworkHostInfo, name: String, delegate: TnNetworkDelegate?, transportingInfo: TnNetworkTransportingInfo) {
        self.isClient = true
        self.hostInfo = hostInfo
        self.name = name
        self.connection = NWConnection(host: NWEndpoint.Host(hostInfo.host), port: NWEndpoint.Port(rawValue: hostInfo.port)!, using: .tcp)
        self.queue = DispatchQueue(label: "\(Self.self).queue")
        self.receiveQueueQueue = DispatchQueue(label: "\(Self.self).receiveQueueQueue")
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
            logDebug("ready")
            // send its name to server
            if isClient {
                Task.detached { [self] in
                    try await send(object: TnMessageIdentifier(name: name))
                }
            }
            startReceiveMsg()
            delegate?.tnNetworkReady(self)
        case .waiting(let error):
            logDebug("waiting", error)
            stop(error: error)
        case .failed(let error):
            logDebug("failed", error)
            stop(error: error)
        case .cancelled:
            logDebug("cancelled")
        default:
            break
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

// MARK: TnNetworkConnection receiving async
extension TnNetworkConnection {
    private func receiveChunk(minSize: Int, maxSize: Int) async throws -> Data? {
        return try await withCheckedThrowingContinuation { continuation in
            connection.receive(minimumIncompleteLength: minSize, maximumLength: maxSize) { content, context, isComplete, error in
                if let error {
                    self.stop(error: error)
                    continuation.resume(throwing: error)
                } else if isComplete {
                    self.stop(error: nil)
                    continuation.resume(throwing: TnAppError.general(message: "Receive error: The connection is closed"))
                } else {
                    self.logDebug("receive chunk", content?.count)
                    continuation.resume(
                        returning: content
                    )
                }
            }
        }
    }
    
    private func receiveMsg() async throws -> Data? {
        if let msgSizeData = try await receiveChunk(minSize: TSize.size, maxSize: TSize.size) {
            let msgSize: TSize = msgSizeData.toNumber()
            self.logDebug("received msgSize", msgSize)
            
            if msgSize < 0 || msgSize > transportingInfo.MTU {
                self.stop()
                throw TnAppError.general(message: "Receive error: Something wrong")
            } else {
                guard let msgData = try await receiveChunk(minSize: Int(msgSize), maxSize: Int(msgSize)), msgData.count == msgSize else {
                    self.stop()
                    throw TnAppError.general(message: "Receive error: Message corrupted")
                }
                self.logDebug("received msg", msgData.count)
                return msgData
            }
        }
        
        return nil
    }
    
    private func startReceiveMsg() {
        Task {
            logDebug("startReceiveMsg start")
            while connection.state == .ready {
                logDebug("startReceiveMsg ...")
                if let msgData = try await self.receiveMsg() {
                    delegate?.tnNetworkReceived(self, data: msgData)
                }
                try await Task.sleep(nanoseconds: 1_000_1000)
            }
            logDebug("startReceiveMsg done", connection.state)
        }
    }
}

// MARK: TnNetworkConnection send async
extension TnNetworkConnection {
    private func sendChunk(_ data: Data) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            logDebug("sending", data.count)
            self.connection.send(content: data, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed( { [self] error in
                if let error = error {
                    logError("send error", error.localizedDescription)
                    stop(error: error)
                    continuation.resume(throwing: error)
                } else {
                    logDebug("sent", data.count)
                    continuation.resume(returning: Void())
                }
            }))
        }
    }
    
    private func sendMsg(_ msgData: Data) async throws {
        let msgSizeData = TSize(msgData.count).toData()
        
        var sendData = Data(capacity: msgSizeData.count + msgData.count)
        sendData.append(msgSizeData)
        sendData.append(msgData)

        try await sendChunk(sendData)
        delegate?.tnNetworkSent(self, count: sendData.count)
    }
}

extension TnNetworkConnection: TnTransportableProtocol {
    public var encoder: TnEncoder {
        transportingInfo.encoder
    }
    
    public var decoder: any TnDecoder {
        transportingInfo.decoder
    }

    public func send(_ data: Data) async throws {
        guard connection.state == .ready else {
            return
        }
        try await self.sendMsg(data)
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
