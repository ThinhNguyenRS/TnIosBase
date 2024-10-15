//
//  TnBluetooth.swift
//  TnIosBase
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
    
    private let bleInfo: TnNetworkBleInfo
    private let transportingInfo: TnNetworkTransportingInfo
    private var status: Status = .none
    
    private var peripheralManager: CBPeripheralManager?
    private let transferCharacteristic: CBMutableCharacteristic
    private var connectedCentrals: [CBCentral] = []
    
    static var sendingWorkerID = 0
    private var sendingWorker: SendingWorker?

    public var delegate: TnBluetoothServerDelegate? = nil

    private var dataQueue: [String: Data] = [:]

    public init(bleInfo: TnNetworkBleInfo, delegate: TnBluetoothServerDelegate? = nil, transportingInfo: TnNetworkTransportingInfo) {
        self.bleInfo = bleInfo
        self.delegate = delegate
        self.transferCharacteristic = CBMutableCharacteristic(
            type: bleInfo.bleCharacteristicUUID,
            properties: [.notify, .writeWithoutResponse],
            value: nil,
            permissions: [.readable, .writeable]
        )
        self.transportingInfo = transportingInfo
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
            logDebug("poweredOn")
            setup()
            return
        case .resetting:
            logDebug("resetting")
            return
        case .unsupported:
            logDebug("unsupported")
            return
        case .unauthorized:
            logDebug("unauthorized")
            return
        case .poweredOff:
            logDebug("poweredOff")
            return
        case .unknown:
            logDebug("unknown")
            return
        @unknown default:
            return
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        connectedCentrals.append(central)
        logDebug("subscribed", central.identifier.uuidString)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        connectedCentrals.removeAll(byID: central)
        logDebug("unsubscribed", central.identifier.uuidString)
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
                logDebug("receiving")
            }
            let receiveMessage = requestValue.count == transportingInfo.EOM.count && requestValue == transportingInfo.EOM
            if !receiveMessage {
                // received chunk
                // append chunk
                data.append(requestValue)
            }

            if receiveMessage {
                logDebug("received", data.count)
                delegate?.tnBluetoothServer(ble: self, receivedID: request.central.identifier.uuidString, receivedData: data)
                data.removeAll()
            }
            dataQueue[request.central.identifier.uuidString] = data
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        logDebug("didReceiveRead")
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
        let transferService = CBMutableService(type: bleInfo.bleServiceUUID, primary: true)
        
        // Add the characteristic to the service.
        transferService.characteristics = [transferCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(transferService)
                
        self.status = .inited
        logDebug("inited")
        delegate?.tnBluetoothServer(ble: self, statusChanged: status)
    }
    
    public func start() {
        guard status == .inited || status == .stopped else {
            return
        }
        guard let peripheralManager else {
            return
        }
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [bleInfo.bleServiceUUID]])
        
        status = .started
        logDebug("started")
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
        logDebug("stopped")
        delegate?.tnBluetoothServer(ble: self, statusChanged: status)
    }
}

extension TnBluetoothServer: TnTransportableProtocol {
    public var encoder: TnEncoder {
        transportingInfo.encoder
    }
    
    public var decoder: any TnDecoder {
        transportingInfo.decoder
    }

    public func send(data: Data, to: [String]?) {
        guard !self.connectedCentrals.isEmpty, sendingWorker == nil else {
            return
        }
        
        TnBluetoothServer.sendingWorkerID += 1
        // TODO: ignore `to`
//        let centrals = to == nil || to!.isEmpty ? connectedCentrals : to!.map { v in connectedCentrals.first(byID: v)!}
//        sendingWorker = SendingWorker(
//            id: TnBluetoothServer.sendingWorkerID,
//            outer: self,
//            centrals: centrals,
//            data: data,
//            EOM: transportingInfo.EOM
//        )
        let centrals = connectedCentrals
        sendingWorker = SendingWorker(
            id: TnBluetoothServer.sendingWorkerID,
            outer: self,
            centrals: centrals,
            data: data,
            EOM: transportingInfo.EOM
        )
    }
}
