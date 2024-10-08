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

    public func send(_ data: Data) async throws {
        for connection in connectionsByID.values {
            try await connection.send(data)
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
            logDebug("ready")
//            startReceiveAsync()
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
//            stop(error: nil)
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

//// MARK: receiving async old
//extension TnNetworkConnection {
//    private func receiveChunkAsync() async -> TnNetworkReceiveData {
//        return await withCheckedContinuation { continuation in
//            connection.receive(minimumIncompleteLength: 1, maximumLength: transportingInfo.MTU) { content, context, isComplete, error in
//                continuation.resume(
//                    returning: TnNetworkReceiveData(content: content, context: context, isComplete: isComplete, error: error)
//                )
//            }
//        }
//    }
//
//    private func receiveAsync() async throws -> [Data]? {
//        let result = await receiveChunkAsync()
//        
//        var parts: [Data]? = nil
//        
//        if let error = result.error {
//            stop(error: error)
//            throw TnAppError.general(message: "Receive error: \(error.localizedDescription)")
//        } else if result.isComplete {
//            stop(error: nil)
//            throw TnAppError.general(message: "Receive error: The connection is closed")
//        } else {
//            if let data = result.content, !data.isEmpty {
//                logDebug("receiving", data.count)
//                // receive data, add to queue
//                dataQueue.append(data)
//                
//                // detect EOM
//                if dataQueue.count > transportingInfo.EOM.count {
//                    let eomAssume = dataQueue.suffix(transportingInfo.EOM.count)
//                    if eomAssume == transportingInfo.EOM {
//                        // get received data
//                        let receivedData = dataQueue[0...dataQueue.count-transportingInfo.EOM.count-1]
//                        logDebug("received", receivedData.count)
//                        
//                        parts = receivedData.split(separator: transportingInfo.EOM)
//
//                        // reset data queue
//                        dataQueue.removeAll()
//                    }
//                }
//            }
//        }
//        
//        return parts
//    }
//    
//    private func startReceiveAsync() {
//        Task {
//            let sleepNanos: UInt64 = 10_1000_1000
//            while connection.state == .ready {
//                if let parts = try await receiveAsync() {
//                    for part in parts {
//                        // signal
//                        delegate?.tnNetwork(self, receivedData: part)
//                    }
//                }
//                
//                try await Task.sleep(nanoseconds: sleepNanos)
//            }
//        }
//    }
//}
//
//// MARK: send async old
//extension TnNetworkConnection {
//    private func sendAsyncOld(_ data: Data?) async throws {
//        guard connection.state == .ready else {
//            return
//        }
//
//        // append EOM
//        var dataToSend = data
//        if dataToSend != nil {
//            dataToSend!.append(transportingInfo.EOM)
//        }
//        
//        return try await withCheckedThrowingContinuation { continuation in
//            self.connection.send(content: dataToSend, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed( { [self] error in
//                if let error = error {
//                    logError("send error", error.localizedDescription)
//                    stop(error: error)
//                    continuation.resume(throwing: error)
//                } else {
//                    continuation.resume(returning: Void())
//                }
//            }))
//        }
//    }
//}

// MARK: receiving async new
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
                    self.logDebug("receiving", content?.count)
                    continuation.resume(
                        returning: content
                    )
                }
            }
        }
    }
    
    private func receiveMsg() async throws -> Data? {
        if let msgSizeData = try await receiveChunk(minSize: MemoryLayout<Int>.size, maxSize: MemoryLayout<Int>.size) {
            let msgSize = msgSizeData.withUnsafeBytes {
                $0.load(as: Int.self)
            }
            guard let msgData = try await receiveChunk(minSize: msgSize, maxSize: msgSize), msgData.count == msgSize else {
                throw TnAppError.general(message: "Receive error: Message corrupted")
            }

            self.logDebug("received", msgData.count)
            return msgData
        }
        
        return nil
    }
    
    private func startReceiveMsg() {
        Task {
            while connection.state == .ready {
                if let msgData = try await receiveMsg() {
                    // signal
                    delegate?.tnNetwork(self, receivedData: msgData)
                }
//                try await Task.sleep(nanoseconds: 10_1000_1000)
            }
        }
    }
}

// MARK: send async new
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
        let msgSizeData = withUnsafeBytes(of: msgData.count) {
            Data($0)
        }
        try await sendChunk(msgSizeData)
        try await sendChunk(msgData)
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

//        try await self.sendAsyncOld(data)
        try await self.sendMsg(data)
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
