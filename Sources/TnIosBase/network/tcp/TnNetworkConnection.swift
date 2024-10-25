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
    
    public let receiveStream: TnAsyncStreamer<Data> = .init()
    private var receiveTask: Task<Void, Error>? = nil
    
    private let sendStream: TnAsyncStreamer<Data> = .init()
    private var sendTask: Task<Void, Error>? = nil

    public private(set) var name: String = ""
    public func setName(_ name: String) {
        if self.name.isEmpty {
            self.name = name
        }
    }
    
    public let isClient: Bool
    
    public init(nwConnection: NWConnection, delegate: TnNetworkDelegate?, transportingInfo: TnNetworkTransportingInfo) {
        self.isClient = false
        self.connection = nwConnection
        self.hostInfo = nwConnection.endpoint.getHostInfo()
        self.queue = DispatchQueue(label: "\(Self.self).queue")
        self.delegate = delegate
        self.transportingInfo = transportingInfo
        
        logDebug("inited connection", hostInfo.host)
    }
    
    public init(hostInfo: TnNetworkHostInfo, name: String, delegate: TnNetworkDelegate?, transportingInfo: TnNetworkTransportingInfo) {
        self.isClient = true
        self.hostInfo = hostInfo
        self.name = name
        self.connection = NWConnection(host: NWEndpoint.Host(hostInfo.host), port: NWEndpoint.Port(rawValue: hostInfo.port)!, using: .tcp)
        self.queue = DispatchQueue(label: "\(Self.self).queue")
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
        switch state {
        case .ready:
            logDebug("start !")
            // send its name to server
            if isClient {
                Task { [self] in
                    logDebug("send name", name)                    
                    try await send(object: TnMessageValue.from(TnMessageSystem.name, name))
                }
            }
            startReceiveMsg()
            startSendMsg()
            if !name.isEmpty {
                delegate?.tnNetworkReady(self)
            }
        case .waiting(let error):
            logDebug("waiting", error)
            stop(error: error)
        case .failed(let error):
            logDebug("failed", error)
            stop(error: error)
        case .cancelled:
            logDebug("cancelled")
            stop(error: nil)
        default:
            break
        }
    }
}

// MARK: start/stop
extension TnNetworkConnection {
    private func stop(error: Error?) {
        receiveStream.finish()
        receiveTask?.cancel()
        
        sendStream.finish()
        sendTask?.cancel()
        
        delegate?.tnNetworkStop(self, error: error)
    }
    
    public func start() {
        logDebug("start ...")

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
                    continuation.resume(returning: content)
                }
            }
        }
    }
    
    private func receiveMsg() async throws -> Data? {
        if let msgSizeData = try await receiveChunk(minSize: TSize.size, maxSize: TSize.size) {
            let msgSize: TSize = msgSizeData.toNumber()
            
            if msgSize < 0 || msgSize > transportingInfo.MTU {
                stop()
                throw TnAppError.general(message: "Receive error: Something wrong")
            } else {
                guard let msgData = try await receiveChunk(minSize: Int(msgSize), maxSize: Int(msgSize)), msgData.count == msgSize else {
                    stop()
                    throw TnAppError.general(message: "Receive error: Message corrupted")
                }
                return msgData
            }
        }
        
        return nil
    }
    
    private func startReceiveMsg() {
        receiveTask = Task {
            while connection.state == .ready {
                if let msgData = try await receiveMsg() {
                    // process identifier msg
                    if name.isEmpty {
                        if let msg = TnMessageValue<String>.from(TnMessageSystem.name, data: msgData, decoder: transportingInfo.decoder) {
                            self.name = msg.value
                            delegate?.tnNetworkReady(self)
                            continue
                        }
                    }
                    receiveStream.yield(msgData)
                }
                try await Task.sleep(nanoseconds: 1_000_1000)
            }
        }
    }
}

// MARK: TnNetworkConnection send async
extension TnNetworkConnection {
    private func sendChunk(_ data: Data) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            connection.send(content: data, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed( { [self] error in
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
    
    private func sendMsg(_ msgData: Data) async throws {
        let msgSizeData = TSize(msgData.count).toData()
        
        var sendData = Data(capacity: msgSizeData.count + msgData.count)
        sendData.append(msgSizeData)
        sendData.append(msgData)
        
        try await sendChunk(sendData)
    }
    
    private func startSendMsg() {
        sendTask = Task {
            for await msgData in sendStream.stream {
                try await sendMsg(msgData)
            }
        }
    }
}

// MARK: Transportable
extension TnNetworkConnection/*: TnTransportableProtocol*/ {
    public var encoder: TnEncoder {
        transportingInfo.encoder
    }
    
    public var decoder: any TnDecoder {
        transportingInfo.decoder
    }

    public func send(data: Data) async throws {
        guard connection.state == .ready else {
            return
        }
        sendStream.yield(data)
    }
    
    public func send(object: TnMessageObject) async throws {
        try await self.send(data: object.toData(encoder: encoder))
    }
}
