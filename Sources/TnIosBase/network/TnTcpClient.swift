////
////  TnTcpClient.swift
////  tCamera
////
////  Created by Thinh Nguyen on 8/25/24.
////
//
//import Foundation
//import CocoaAsyncSocket
//
//protocol TnTcpClientDelegate {
//    func tnTcpClient(tcp: TnTcpClient, receivedData: Data)
//    func tnTcpClient(tcp: TnTcpClient, connectedHost: String, port: UInt16)
//    func tnTcpClient(tcp: TnTcpClient, disconnected: Bool, reason: String?)
//}
//
//// MARK: TnTcpClient
//class TnTcpClient: NSObject, TnTransportableProtocol {
//    let LOG_NAME = "TnTcpClient"
//    
//    private let queue: DispatchQueue = .init(label: "TnTcpClient")
//    lazy var socket: GCDAsyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: queue)
//    
//    let host: String
//    let port: UInt16
//    let eom: Data?
//    var delegate: TnTcpClientDelegate? = nil
//
//    private var isReading = false
//    private var sendingQueue: [Data] = []
//    
//    init(host: String, port: UInt16, eom: Data?) {
//        self.host = host
//        self.port = port
//        self.eom = eom
//    }
//    
//    init(socket: GCDAsyncSocket, eom: Data?) {
//        self.host = socket.connectedHost ?? ""
//        self.port = socket.connectedPort
//        self.eom = eom
//        super.init()
//        
//        self.socket = socket
//        self.readNext()
//    }
//    
//    func open(timeout: Double = -1) throws {
//        do {
//            try socket.connect(toHost: host, onPort: port, withTimeout: timeout)
//            TnLogger.error(LOG_NAME, "connected", host, port)
//        } catch {
//            TnLogger.error(LOG_NAME, "Cannot connect to", host, port, "[\(error.localizedDescription)]")
//            throw error
//        }
//    }
//    
//    static func open(host: String, port: UInt16, eom: Data?) -> TnTcpClient? {
//        let tcp = TnTcpClient(host: host, port: port, eom: eom)
//        do {
//            try tcp.open()
//            return tcp
//        } catch {
//        }
//        return nil
//    }
//    
//    func readNext() {
//        self.socket.readData(to: eom, withTimeout: -1, tag: 0)
//    }
//    
//    func send(_ data: Data) {
//        var dataTosend = data
//        if let eom {
//            dataTosend.append(eom)
//        }
//        
//        TnLogger.debug(LOG_NAME, "prepare send", dataTosend.count, sendingQueue.count)
//
//        sendingQueue.append(dataTosend)
//        if sendingQueue.count == 1 {
//            TnLogger.debug(LOG_NAME, "sending data", dataTosend.count)
//            self.socket.write(dataTosend, withTimeout: -1, tag: 0)
//        } else {
//            TnLogger.debug(LOG_NAME, "queueing data", dataTosend.count, sendingQueue.count)
//        }
//    }
//
////    func send(msg: TnMessage, eom: Data? = nil) {
////        TnLogger.debug(LOG_NAME, "send typeCode", msg.typeCode)
////        self.send(msg.data)
////    }
////    
////    func send(object: TnMessageProtocol) {
////        self.send(msg: object.toMessage())
////    }
//}
//
//extension TnTcpClient: GCDAsyncSocketDelegate {
//    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
//        TnLogger.error(LOG_NAME, "connected", host, port)
//        
//        delegate?.tnTcpClient(tcp: self, connectedHost: host, port: port)
//
//        // start read data
//        self.readNext()
//    }
//
//    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: (any Error)?) {
//        TnLogger.error(LOG_NAME, "disconnected", err?.localizedDescription)
//        delegate?.tnTcpClient(tcp: self, disconnected: true, reason: err?.localizedDescription)
//    }
//
//    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
//        TnLogger.debug(LOG_NAME, "received", data.count)
//        var receivedData = data
//        if let eom {
//            receivedData = data.subdata(in: 0..<(data.count - eom.count))
//        }
//        
//        delegate?.tnTcpClient(tcp: self, receivedData: receivedData)
//        
//        // read next data
//        self.readNext()
//    }
//    
//    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
//        // remove from queue
//        sendingQueue.remove(at: 0)
//
//        TnLogger.debug(LOG_NAME, "sent", sendingQueue.count)
//
//        if let dataTosend = sendingQueue.first {
//            TnLogger.debug(LOG_NAME, "sending next data", dataTosend.count)
//            self.socket.write(dataTosend, withTimeout: -1, tag: 0)
//        }
//    }
//}
