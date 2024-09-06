////
////  TnNetworkTCP.swift
////  tCamera
////
////  Created by Thinh Nguyen on 8/23/24.
////
//
//import Foundation
//import CocoaAsyncSocket
//
//
//protocol TnTcpServerDelegate {
//    func tnTcpServer(tcp: TnTcpServer, receivedData: Data, host: String)
//    func tnTcpServer(tcp: TnTcpServer, acceptedHost: String)
//    func tnTcpServer(tcp: TnTcpServer, disconnectedHost: String)
//}
//
//// MARK: TnTcpServer
//class TnTcpServer: NSObject, TnTransportableProtocol {
//    let LOG_NAME = "TnTcpServer"
//    
//    private let queue: DispatchQueue = .init(label: "TnTcpServer")
//    lazy var socket: GCDAsyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: queue)
//    
//    let host: String
//    let port: UInt16
//    let eom: Data?
//    
//    var delegate: TnTcpServerDelegate? = nil
//
//    private var clients: [TnTcpClient] = []
//
//    init(host: String, port: UInt16, eom: Data?) {
//        self.host = host
//        self.port = port
//        self.eom = eom
//    }
//    
//    func open() throws {
//        do {
//            try socket.accept(onPort: port)
//        } catch {
//            TnLogger.error(LOG_NAME, "Cannot listen on", host, port, "[\(error.localizedDescription)]")
//            throw error
//        }
//        TnLogger.debug(LOG_NAME, "listening on", host, port)
//    }
//    
//    static func open(host: String, port: UInt16, eom: Data?) -> TnTcpServer? {
//        let tcp = TnTcpServer(host: host, port: port, eom: eom)
//        do {
//            try tcp.open()
//            return tcp
//        } catch {
//        }
//        return nil
//    }
//    
//    func send(_ data: Data) {
//        if !clients.isEmpty {
//            for client in clients {
//                client.send(data)
//            }
//        }
//    }
//
////    func send(msg: TnMessage) {
////        if !clients.isEmpty {
////            self.send(msg.data)
////        }
////    }
////    
////    func send(object: TnMessageProtocol) {
////        if !clients.isEmpty {
////            self.send(msg: object.toMessage())
////        }
////    }
//}
//
//extension TnTcpServer: GCDAsyncSocketDelegate {
//    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: (any Error)?) {
//        TnLogger.debug(LOG_NAME, "disconnected", err?.localizedDescription)
//        if let clientIndex = clients.firstIndex(sock) {
//            let client = clients[clientIndex]
//            clients.remove(at: clientIndex)
//            TnLogger.debug(LOG_NAME, "remove client", client.host)
//
//            delegate?.tnTcpServer(tcp: self, disconnectedHost: client.host)
//        }
//    }
//    
//    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
//        TnLogger.debug(LOG_NAME, "accepted", newSocket.connectedHost, newSocket.connectedPort)
//        
//        let client = TnTcpClient(socket: newSocket, eom: eom)
//        clients.append(client)
//
//        delegate?.tnTcpServer(tcp: self, acceptedHost: client.host)
//    }
//    
//    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
//        TnLogger.debug(LOG_NAME, "received", sock.connectedHost, data.count)
//
//        if let client = clients.first(sock) {
//            // yield to cleint
//            client.socket(sock, didRead: data, withTag: tag)
//        }
//
//        // solve on received
//        var receivedData = data
//        if let eom {
//            receivedData = data.subdata(in: 0..<(data.count - eom.count))
//        }
//        
//        delegate?.tnTcpServer(tcp: self, receivedData: receivedData, host: host)
//    }
//    
//    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
//        TnLogger.debug(LOG_NAME, "sent")
//        if let client = clients.first(sock) {
//            // yield to cleint
//            client.socket(sock, didWriteDataWithTag: tag)
//        }
//    }
//}
//
//extension Array where Element: TnTcpClient {
//    func first(_ sock: GCDAsyncSocket) -> TnTcpClient? {
//        self.first(where: { v in v.socket == sock })
//    }
//    
//    func firstIndex(_ sock: GCDAsyncSocket) -> Int? {
//        self.firstIndex(where: { v in v.socket == sock })
//    }
//}
