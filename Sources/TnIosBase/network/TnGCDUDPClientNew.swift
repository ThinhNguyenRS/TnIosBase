////
////  TnUDPClient.swift
////  TnIosBase
////
////  Created by Thinh Nguyen on 05/08/2021.
////
//
//import Foundation
//import CocoaAsyncSocket
//
//class TnUDPClientNew: NSObject, GCDAsyncUdpSocketDelegate {
//    private let port: UInt16    
//    private var socket: GCDAsyncUdpSocket!
//    private var localIP: String = ""
//    var broadcastIP: String = ""
//
//    private var onClosed: (() -> Void)?
//    private var onReceiveSuccess: ((TnNetworkPacket) -> Void)?
//
//    private var onSendSuccess: ((Int) -> Void)?
//    private var onSendError: ((Int, TnNetworkError) -> Void)?
//
//    init(port: Int32) {
//        self.port = UInt16(port)
//        super.init()
//    }
//    
//    func isOpened() -> Bool {
//        return socket != nil && !socket.isClosed()
//    }
//    
//    func open() throws {
//        // let cellularIP = TnNetworkHelper.getAddress(for: .cellular)
//        guard let ip = TnNetworkHelper.getAddress(for: .wifi) else {
//            throw TnAppError.general(message: "You must connect to WIFI first !")
//        }
//        self.localIP = ip.address
//        self.broadcastIP = ip.address.prefix(last: ".")! + ".255"
//        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global())
//        try socket.bind(toPort: self.port)
//        try socket.enableBroadcast(true)
//    }
//        
//    func close(_ handler: (() -> Void)? = nil) {
//        if self.isOpened() {
//            self.onClosed = handler
//            socket.close()
//        }
//    }
//    
//    func send(_ packet: TnNetworkPacket, timeout: TimeInterval = 0.100, tag: Int = 0, onSuccess: ((Int) -> Void)? = nil, onError: ((Int, TnNetworkError) -> Void)? = nil) {
//        if !self.isOpened() {
//            onError?(tag, TnNetworkError.socketClosed)
//            return
//        }
//
//        self.onSendSuccess = onSuccess
//        self.onSendError = onError
//
//        do {
//            let data = try packet.message.toJsonData()
//            socket.send(data, toHost: packet.ip, port: port, withTimeout: timeout, tag: tag)
//        } catch {
//            onError?(tag, TnNetworkError.socketError(description: error.localizedDescription))
//        }
//    }
//    
//    func receiveMulti(_ onSuccess: @escaping (TnNetworkPacket) -> Void, onError: ((Error) -> Void)? = nil) {
//        if !self.isOpened() {
//            onError?(TnNetworkError.socketClosed)
//            return
//        }
//        self.onReceiveSuccess = onSuccess
//        do {
//            try socket.beginReceiving()
//        } catch {
//            onError?(TnNetworkError.socketError(description: error.localizedDescription))
//        }
//    }
//    
//    func receiveOnce(_ onSuccess: @escaping (TnNetworkPacket) -> Void, onError: ((Error) -> Void)? = nil) {
//        if !self.isOpened() {
//            onError?(TnNetworkError.socketClosed)
//            return
//        }
//        self.onReceiveSuccess = onSuccess
//        do {
//            try socket.receiveOnce()
//        } catch {
//            onError?(TnNetworkError.socketError(description: error.localizedDescription))
//        }
//    }
//
//    func stopReceive() {
//        if self.isOpened() {
//            socket.pauseReceiving()
//        }
//    }
//    
//    func resolveHost(_ address: Data) -> (host: String, port: UInt16) {
//        var hostName: NSString?
//        var port: UInt16 = 0
//        GCDAsyncSocket.getHost(&hostName, port: &port, fromAddress: address)
//        return (host: String(hostName!), port: port)
//    }
//    
//    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
//        TnLogger.warning("TnUDPClient", "didNotConnect!")
//    }
//    
//    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
//        TnLogger.warning("TnUDPClient", "didConnectToAddress: [\(address.toString())]")
//    }
//    
//    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
//        onSendSuccess?(tag)
//    }
//    
//    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
//        onSendError?(tag, TnNetworkError.socketError(description: error?.localizedDescription ?? ""))
//    }
//    
//    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
//        self.onClosed?()
//    }
//    
//    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
//        let host = resolveHost(address)
//        if !host.host.starts(with: "::ffff:") && host.host != localIP {
//            if let messageValid = try? data.tnToObjectFromJSON(TnNetworkMessage.self) {
//                self.onReceiveSuccess?(TnNetworkPacket(messageValid, ip: host.host))
//            }
//        }
//    }
//    
//    func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
////        self.receiveHandler?(data)
////        let dataString = data!.tnToUTF8()
////        print("TnUDPClient incoming message2: [\(dataString)]");
//    }
//    
//}
//
//class TnUDPClientDelegate: NSObject, GCDAsyncUdpSocketDelegate {
//    
//}
