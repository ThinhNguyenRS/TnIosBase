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

public class TnNetworkServer: TnNetwork, TnTransportableProtocol {
    public let LOG_NAME = "TnNetworkServer"
    
    public let host: String
    public let port: UInt16
    
    private let listener: NWListener
    private var connectionsByID: [Int: TnNetworkConnectionServer] = [:]
    private let queue: DispatchQueue
    private let delegate: TnNetworkDelegateServer?
    private let EOM: Data
    private let MTU: Int

    public init(host: String, port: UInt16, queue: DispatchQueue, delegate: TnNetworkDelegateServer?, EOM: Data, MTU: Int) {
        self.host = host
        self.port = port
        self.queue = queue
        self.delegate = delegate
        self.EOM = EOM
        self.MTU = MTU
        
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

        let connection = TnNetworkConnectionServer(nwConnection: nwConnection, queue: queue, delegate: self, EOM: EOM, MTU: MTU)
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

    public func send(_ data: Data) {
        for connection in connectionsByID.values {
            connection.send(data)
        }
    }
}

extension TnNetworkServer: TnNetworkDelegate {
    public func tnNetworkReady(_ connection: TnNetworkConnection) {
        logDebug("accepted", connection.host, connection.port)

        let connectionServer = connection as! TnNetworkConnectionServer
        delegate?.tnNetwork(self, accepted: connectionServer)
    }
    
    public func tnNetworkStop(_ connection: TnNetworkConnection, error: Error?) {
        logDebug("disconnected", connection.host, connection.port)

        let connectionServer = connection as! TnNetworkConnectionServer
        self.connectionsByID.removeValue(forKey: connectionServer.id)
        delegate?.tnNetwork(self, stopped: connectionServer, error: error)
    }

    public func tnNetwork(_ connection: TnNetworkConnection, receivedData: Data) {
        logDebug("received", connection.host, connection.port, receivedData.count)

        let connectionServer = connection as! TnNetworkConnectionServer
        delegate?.tnNetwork(self, connection: connectionServer, receivedData: receivedData)
    }
    
    public func tnNetwork(_ connection: TnNetworkConnection, sentData: Data) {
        logDebug("sent", connection.host, connection.port, sentData.count)

        let connectionServer = connection as! TnNetworkConnectionServer
        delegate?.tnNetwork(self, connection: connectionServer, sentData: sentData)
    }
}

public class TnNetworkConnection: TnNetwork, TnTransportableProtocol {
    public let LOG_NAME = "TnNetworkConnection"

    //The TCP maximum package size is 64K 65536
    let MTU: Int
    
    public let host: String
    public let port: UInt16
    
    private let delegate: TnNetworkDelegate?
    private let connection: NWConnection
    private let queue: DispatchQueue
    private let EOM: Data
    private var dataQueue: Data = .init()
    
    public init(nwConnection: NWConnection, queue: DispatchQueue?, delegate: TnNetworkDelegate?, EOM: Data, MTU: Int) {
        self.connection = nwConnection
        let hp = nwConnection.endpoint.getHostAndPort()
        self.host = hp.host
        self.port = hp.port
        self.queue = queue ?? DispatchQueue(label: "\(LOG_NAME).queue")
        self.delegate = delegate
        self.EOM = EOM
        self.MTU = MTU
        
        logDebug("inited", host, port)
    }
    
    public init(host: String, port: UInt16, queue: DispatchQueue?, delegate: TnNetworkDelegate?, EOM: Data, MTU: Int) {
        self.host = host
        self.port = port
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
        self.queue = queue ?? DispatchQueue(label: "\(LOG_NAME).queue")
        self.delegate = delegate
        self.EOM = EOM
        self.MTU = MTU

        logDebug("inited", host, port)
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
        switch state {
        case .ready:
            logDebug("ready")
//            receive()
            delegate?.tnNetworkReady(self)
            
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
    
    private func findEom() -> Int {
        guard dataQueue.count >= EOM.count else {
            return -1
        }
        let eomCount = EOM.count
        var found = false
        
        var startIndex = dataQueue.count - eomCount
        while !found && startIndex >= 0 {
            let eomAssume = dataQueue[startIndex...(startIndex+eomCount-1)]
            if eomAssume == EOM {
                found = true
            } else {
                startIndex -= 1
            }
        }
        return found ? startIndex : -1
    }
    
    private func processReceived(_ data: Data?) {
        if let data = data, !data.isEmpty {
            // receive data, add to queue
            dataQueue.append(data)
            
            let eomIndex = findEom()
            if eomIndex > -1 {
                let receivedData = dataQueue[0...eomIndex-1]
                logDebug("received", receivedData.count)
                delegate?.tnNetwork(self, receivedData: receivedData)

                // reset data queue
                dataQueue.removeSubrange(0...eomIndex+EOM.count-1)
            }
        }
    }
    
    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: MTU) { [self] (data, _, isComplete, error) in
            processReceived(data)
            
            if isComplete {
                // receive completed, that may be meant the connection is disconnected
                stop(error: nil)
            } else if let error = error {
                stop(error: error)
            } else {
                // continue receive
                receive()
            }
        }
    }
    
    private func sendChunk(_ data: Data, completion: @escaping () -> Void) {
        self.connection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.stop(error: error)
                return
            }
            completion()
        }))
    }

    public func start() {
        logDebug("starting")

        connection.stateUpdateHandler = self.onStateChanged(to:)
        receive()
        
        connection.start(queue: queue)
    }
    
    public func stop() {
        stop(error: nil)
    }
    
    public func send(_ data: Data) {
        sendChunk(data, completion: { [self] in
            sendChunk(EOM, completion: { [self] in
                // signal send
                logDebug("sent", data.count)
                self.delegate?.tnNetwork(self, sentData: data)
            })
        })
    }
}

public class TnNetworkConnectionServer: TnNetworkConnection {
    private static var nextID: Int = 0
    let id: Int

    override init(nwConnection: NWConnection, queue: DispatchQueue?, delegate: TnNetworkDelegate?, EOM: Data, MTU: Int) {
        self.id = Self.nextID
        Self.nextID += 1
        super.init(nwConnection: nwConnection, queue: queue, delegate: delegate, EOM: EOM, MTU: MTU)
    }
}

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
