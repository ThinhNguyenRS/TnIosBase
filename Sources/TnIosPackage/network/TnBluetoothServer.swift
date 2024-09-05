//
//  TnBluetooth.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 06/08/2021.
//

import Foundation
import CoreBluetooth

public protocol TnBluetoothServerDelegate {
    func tnBluetoothServer(ble: TnBluetoothServer, statusChanged: TnBluetoothServer.Status)
    func tnBluetoothServer(ble: TnBluetoothServer, receivedID: String, receivedData: Data)
    func tnBluetoothServer(ble: TnBluetoothServer, sentIDs: [String], sentData: Data)
}

// MARK: members
public class TnBluetoothServer: NSObject {
    class SendingWorker: Hashable {
        public static func == (lhs: TnBluetoothServer.SendingWorker, rhs: TnBluetoothServer.SendingWorker) -> Bool {
            lhs.id == rhs.id
        }
        public func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }
        
        public enum Status {
            case none
            case sending
            case sendingEOM
            case finished
        }
        private let id: Int
        private let outer: TnBluetoothServer
        private let centrals: [CBCentral]
        private let data: Data
        private let EOM: Data
        private let MTU: Int
        
        private var sendingDataIndex = 0
        private var status: Status = .none

        init(id: Int, outer: TnBluetoothServer, centrals: [CBCentral], data: Data, EOM: Data) {
            self.id = id
            self.outer = outer
            self.centrals = centrals
            self.data = data
            self.EOM = EOM
            MTU = centrals.map { v in v.maximumUpdateValueLength }.min()!
            
            TnLogger.debug("TnBluetoothServer.SendingWorker", "sending", data.count)
            self.send()
        }

        func send() {
            if status == .finished {
                return
            }
            if status == .sendingEOM {
                sendEOM()
                return
            }

            guard let peripheralManager = outer.peripheralManager else {
                return
            }

            
            var sendingChunkSuccess = true
            while sendingChunkSuccess {
                // Chunk size
                let chunkSize = min(data.count - sendingDataIndex, MTU)

                // chunk
                let chunk = data.subdata(in: sendingDataIndex..<(sendingDataIndex + chunkSize))

                // send
                sendingChunkSuccess = peripheralManager.updateValue(chunk, for: outer.transferCharacteristic, onSubscribedCentrals: centrals)
                if sendingChunkSuccess {
                    sendingDataIndex += chunkSize
                    if sendingDataIndex >= data.count {
                        // send EOM signal
                        status = .sendingEOM
                        sendEOM()
                    }
                }
            }
        }
        
        private func sendEOM() {
            guard let peripheralManager = outer.peripheralManager else {
                return
            }

            if peripheralManager.updateValue(
                EOM,
                for: outer.transferCharacteristic,
                onSubscribedCentrals: centrals
            ) {
                status = .finished
                TnLogger.debug("TnBluetoothServer.SendingWorker", "sent", data.count)
                
                outer.delegate?.tnBluetoothServer(ble: outer, sentIDs: centrals.map { v in v.identifier.uuidString }, sentData: data)
                // remove myself
                outer.sendingWorker = nil
            }
        }
    }
    
    public let LOG_NAME: String = "TnBluetoothServer"
    private let info: TnBluetoothServiceInfo
    private var status: Status = .none
    
    private var peripheralManager: CBPeripheralManager?
    private let transferCharacteristic: CBMutableCharacteristic
    private var connectedCentrals: [CBCentral] = []
    
    static var sendingWorkerID = 0
    private var sendingWorker: SendingWorker?

    var delegate: TnBluetoothServerDelegate?

    private var dataQueue: [String: Data] = [:]

    public init(info: TnBluetoothServiceInfo, delegate: TnBluetoothServerDelegate? = nil) {
        self.info = info
        self.delegate = delegate
        self.transferCharacteristic = CBMutableCharacteristic(
            type: info.characteristicUUID,
            properties: [.notify, .writeWithoutResponse],
            value: nil,
            permissions: [.readable, .writeable]
        )
    }
    
    deinit {
        self.stop()
    }
}

// MARK: inner types
extension TnBluetoothServer {
    public enum Status {
        case none
        case inited
        case started
//        case ready
        case stopped
    }
    
    typealias UseManagerHandler = (CBPeripheralManager, CBMutableCharacteristic) -> Void
}

// MARK: CBPeripheralManagerDelegate
extension TnBluetoothServer: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            TnLogger.debug(LOG_NAME, "poweredOn")
            setup()
            return
        case .resetting:
            TnLogger.debug(LOG_NAME, "resetting")
            return
        case .unsupported:
            TnLogger.debug(LOG_NAME, "unsupported")
            return
        case .unauthorized:
            TnLogger.debug(LOG_NAME, "unauthorized")
            return
        case .poweredOff:
            TnLogger.debug(LOG_NAME, "poweredOff")
            return
        case .unknown:
            TnLogger.debug(LOG_NAME, "unknown")
            return
        @unknown default:
            return
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        connectedCentrals.append(central)
        TnLogger.debug(LOG_NAME, "subscribed", central.identifier.uuidString)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        connectedCentrals.removeAll(byID: central)
        TnLogger.debug(LOG_NAME, "unsubscribed", central.identifier.uuidString)
    }
    
    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // ready to send next chunk
        sendingWorker?.send()
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard let requestValue = request.value else {
                continue
            }
            
            var data = dataQueue[request.central.identifier.uuidString] ?? .init()
            if data.isEmpty {
                TnLogger.debug(LOG_NAME, "receiving", request.central.identifier.uuidString)
            }
            let receiveMessage = requestValue.count == info.EOM.count && requestValue == info.EOM
            if !receiveMessage {
                // received chunk
                // append chunk
                data.append(requestValue)
            }

            if receiveMessage {
                TnLogger.debug(LOG_NAME, "received", request.central.identifier.uuidString, data.count)
                delegate?.tnBluetoothServer(ble: self, receivedID: request.central.identifier.uuidString, receivedData: data)
                data.removeAll()
            }
            dataQueue[request.central.identifier.uuidString] = data
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        TnLogger.debug(LOG_NAME, "didReceiveRead")
    }
}

// MARK: functional
extension TnBluetoothServer {
    public func setupBle() {
        peripheralManager = peripheralManager ?? CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }
    
    private func setup() {
        guard let peripheralManager else {
            return
        }
        // Build our service.
        
        // Create a service from the characteristic.
        let transferService = CBMutableService(type: info.serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        transferService.characteristics = [transferCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(transferService)
                
        self.status = .inited
        TnLogger.debug(LOG_NAME, "inited")
        delegate?.tnBluetoothServer(ble: self, statusChanged: status)
    }
    
    public func start() {
        guard status == .inited || status == .stopped else {
            return
        }
        guard let peripheralManager else {
            return
        }
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [info.serviceUUID]])
        
        status = .started
        TnLogger.debug(LOG_NAME, "started")
        delegate?.tnBluetoothServer(ble: self, statusChanged: status)
    }
    
    public func stop() {
        guard status == .started else {
            return
        }
        guard let peripheralManager else {
            return
        }
        peripheralManager.stopAdvertising()
        
        status = .stopped
        TnLogger.debug(LOG_NAME, "stopped")
        delegate?.tnBluetoothServer(ble: self, statusChanged: status)
    }
    
    public func send(data: Data, centralIDs: [String]? = nil) {
        guard !self.connectedCentrals.isEmpty, sendingWorker == nil else {
            return
        }
        
        TnBluetoothServer.sendingWorkerID += 1
        let centrals = centralIDs == nil || centralIDs!.isEmpty ? connectedCentrals : centralIDs!.map { v in connectedCentrals.first(byID: v)!}
        sendingWorker = SendingWorker(
            id: TnBluetoothServer.sendingWorkerID,
            outer: self,
            centrals: centrals,
            data: data,
            EOM: info.EOM
        )
    }
}

extension TnBluetoothServer {
    public func send(msg: TnMessage, centralIDs: [String]? = nil) {
        self.send(data: msg.data, centralIDs: centralIDs)
    }
    
    public func send(object: TnMessageProtocol, centralIDs: [String]? = nil) {
        self.send(msg: object.toMessage(), centralIDs: centralIDs)
    }
}

extension TnBluetoothServer: TnTransportableProtocol {
    public func send(_ data: Data) {
        self.send(data: data, centralIDs: nil)
    }
}
