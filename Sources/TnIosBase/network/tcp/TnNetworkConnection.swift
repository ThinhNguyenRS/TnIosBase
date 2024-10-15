//
//  TnNetworkConnection.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/15/24.
//

import Foundation
import Network

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
        if self.name.isEmpty {
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
        stop()
    }
}

// MARK: equatable
extension TnNetworkConnection: Equatable {
    public static func == (lhs: TnNetworkConnection, rhs: TnNetworkConnection) -> Bool {
        lhs.hostInfo == rhs.hostInfo
    }    
}

// MARK: handle state
extension TnNetworkConnection {
    private func onStateChanged(to state: NWConnection.State) {
        logDebug("state changed", state)
        
        switch state {
        case .ready:
            logDebug("ready")
            // send its name to server
            if isClient {
                Task { [self] in
                    logDebug("send name", name)
                    try await send(object: TnMessageSystem.toMessageIndentifier(name: name), to: nil)
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
}

// MARK: start/stop
extension TnNetworkConnection {
    private func stop(error: Error?) {
        if connection.state != .cancelled {
            connection.stateUpdateHandler = nil
            connection.cancel()
            delegate?.tnNetworkStop(self, error: error)
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
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                return
            }
            
            connection.receive(minimumIncompleteLength: minSize, maximumLength: maxSize) { [weak self] content, context, isComplete, error in
                guard let self else {
                    return
                }

                if let error {
                    stop(error: error)
                    continuation.resume(throwing: error)
                } else if isComplete {
                    stop(error: nil)
                    continuation.resume(throwing: TnAppError.general(message: "Receive error: The connection is closed"))
                } else {
                    logDebug("receive chunk", content?.count)
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
            logDebug("received msgSize", msgSize)
            
            if msgSize < 0 || msgSize > transportingInfo.MTU {
                stop()
                throw TnAppError.general(message: "Receive error: Something wrong")
            } else {
                guard let msgData = try await receiveChunk(minSize: Int(msgSize), maxSize: Int(msgSize)), msgData.count == msgSize else {
                    stop()
                    throw TnAppError.general(message: "Receive error: Message corrupted")
                }
                logDebug("received msg", msgData.count)
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
                if let msgData = try await receiveMsg() {
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
            connection.send(content: data, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed( { [self] error in
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

// MARK: TnTransportableProtocol
extension TnNetworkConnection: TnTransportableProtocol {
    public var encoder: TnEncoder {
        transportingInfo.encoder
    }
    
    public var decoder: any TnDecoder {
        transportingInfo.decoder
    }

    public func send(data: Data, to: [String]?) async throws {
        guard connection.state == .ready else {
            return
        }
        try await sendMsg(data)
    }
}
