//
//  TnBluetoothClient.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/15/24.
//

import Foundation
import CoreBluetooth
import os

public protocol TnBluetoothClientDelegate {
    func tnBluetoothClient(ble: TnBluetoothClient, statusChanged: TnBluetoothClient.Status)
    func tnBluetoothClient(ble: TnBluetoothClient, discoveredID: String)

    func tnBluetoothClient(ble: TnBluetoothClient, connectedID: String)
    func tnBluetoothClient(ble: TnBluetoothClient, disconnectedID: String)

    func tnBluetoothClient(ble: TnBluetoothClient, receivedID: String, receivedData: Data)
    func tnBluetoothClient(ble: TnBluetoothClient, sentID: String, sentData: Data)
}

// MARK: members
public class TnBluetoothClient: NSObject, ObservableObject {
    class SendingWorker: Hashable, TnLoggable {
        static func == (lhs: TnBluetoothClient.SendingWorker, rhs: TnBluetoothClient.SendingWorker) -> Bool {
            lhs.id == rhs.id
        }
        func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }

        enum Status {
            case none
            case sending
            case sendingEOM
            case finished
        }

        let id: Int
        let outer: TnBluetoothClient
        let peripheral: CBPeripheral
        private let data: Data
        private let mtu: Int

        private var sendingDataIndex = 0
        private var status: Status = .none
        
        init(id: Int, outer: TnBluetoothClient, peripheral: CBPeripheral, data: Data) {
            self.id = id
            self.outer = outer
            self.peripheral = peripheral
            self.data = data
            self.mtu = peripheral.maximumWriteValueLength(for: .withoutResponse)

            logDebug("sending", peripheral.name!, data.count)
            self.send()
        }
        
        private func sendEOM() {
            peripheral.writeValue(outer.info.EOM, for: outer.transferCharacteristic!, type: .withoutResponse)
            status = .finished

            logDebug("sent", peripheral.name!, data.count)
            outer.delegate?.tnBluetoothClient(ble: outer, sentID: peripheral.identifier.uuidString, sentData: data)

            outer.sendingWorkers.remove(of: self)
        }
        
        private func sendChunk() {
            let chunkSize = min(data.count - sendingDataIndex, mtu)
            // chunk
            let chunk = data.subdata(in: sendingDataIndex..<(sendingDataIndex + chunkSize))
            
            // send
            peripheral.writeValue(chunk, for: outer.transferCharacteristic!, type: .withoutResponse)

            sendingDataIndex += chunkSize
            if sendingDataIndex >= data.count {
                // send EOM signal
                status = .sendingEOM
            }
        }

        func send() {
            if status == .finished {
                return
            }
            
            if peripheral.canSendWriteWithoutResponse {
                if status == .sendingEOM {
                    sendEOM()
                    return
                }
                sendChunk()
            }
        }
    }

    public let info: TnNetworkServiceInfo
    private var centralManager: CBCentralManager!
    public private(set) var discoveredPeripherals: [CBPeripheral] = []
    public private(set) var connectedPeripherals: [CBPeripheral] = []

    private var transferCharacteristic: CBCharacteristic?
    private var status: Status = .none
    
    public var delegate: TnBluetoothClientDelegate?
    
    private var dataQueue: [String: Data] = [:]
    private let centralQueue: DispatchQueue = .init(label: "TnBluetoothClient.central")

    private static var sendingWorkerID = 0
    private var sendingWorkers: [SendingWorker] = []

    public init(info: TnNetworkServiceInfo, delegate: TnBluetoothClientDelegate? = nil) {
        self.info = info
        self.delegate = delegate
    }
}

// MARK: Inner types
extension TnBluetoothClient {
    public enum Status {
        case none
        case inited
        case ready
        case cleanup
    }
    typealias UseManagerHandler = (CBCentralManager) -> Void
}


// MARK: CBCentralManagerDelegate
extension TnBluetoothClient: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            setup()
        case .resetting:
            return
        case .unsupported:
            return
        case .unauthorized:
            return
        case .poweredOff:
            return
        case .unknown:
            return
        @unknown default:
            return
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Reject if the signal strength is too low to attempt data transfer.
        // Change the minimum RSSI value depending on your app’s use case.
        guard RSSI.intValue >= info.bleRssiMin else {
            logDebug("Discovered perhiperal not in expected range, at", RSSI.intValue)
            return
        }
        
        if !discoveredPeripherals.contains(byID: peripheral) {
            logDebug("discovered", peripheral.name!)
            discoveredPeripherals.append(peripheral)
            delegate?.tnBluetoothClient(ble: self, discoveredID: peripheral.identifier.uuidString)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let centralManager = self.centralManager else {
            return
        }
        logDebug("Peripheral Connected")
        
        // Stop scanning
        centralManager.stopScan()
        logDebug("Scanning stopped")
                
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        // Search only for services that match our UUID
        peripheral.discoverServices([info.bleServiceUUID])

        connectedPeripherals.append(peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        logDebug("disconnected", peripheral.identifier.uuidString)
        connectedPeripherals.removeAll(byID: peripheral)
        delegate?.tnBluetoothClient(ble: self, disconnectedID: peripheral.identifier.uuidString)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        cleanup()
    }
}

// MARK: CBPeripheralDelegate
extension TnBluetoothClient: CBPeripheralDelegate {
    /*
     *  The peripheral letting us know when services have been invalidated.
     */
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for service in invalidatedServices where service.uuid == info.bleServiceUUID {
            logDebug("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([info.bleServiceUUID])
        }
    }

    /*
     *  The Transfer Service was discovered
     */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            logDebug("Error discovering services:", error.localizedDescription)
            cleanup()
            return
        }
        
        // Discover the characteristic we want...
        
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        guard let peripheralServices = peripheral.services else { return }
        logDebug("Discovered services:", peripheralServices.count)

        for service in peripheralServices {
            peripheral.discoverCharacteristics([info.bleCharacteristicUUID], for: service)
        }
    }
    
    /*
     *  The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
     */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Deal with errors (if any).
        if let error = error {
            logDebug("Error discovering characteristics:", error.localizedDescription)
            cleanup()
            return
        }
        
        // Again, we loop through the array, just in case and check if it's the right one
        guard let serviceCharacteristics = service.characteristics else {
            return
        }

        logDebug("Discovered characteristics:", serviceCharacteristics.count)
        for characteristic in serviceCharacteristics where characteristic.uuid == info.bleCharacteristicUUID {
            // If it is, subscribe to it
            transferCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)

            // this is real connected
            logDebug("connected", peripheral.identifier.uuidString)
            delegate?.tnBluetoothClient(ble: self, connectedID: peripheral.identifier.uuidString)
        }
        
        // Once this is complete, we just need to wait for the data to come in.
        changeStatus(.ready)
    }
    
    /*
     *   This callback lets us know more data has arrived via notification on the characteristic
     */
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            logDebug("Error discovering characteristics:", error.localizedDescription)
            cleanup()
            return
        }
        
        guard let characteristicData = characteristic.value, let peripheral = characteristic.service?.peripheral else {
            return
        }
        
        var data = dataQueue[peripheral.identifier.uuidString] ?? .init()
        if data.isEmpty {
            logDebug("receiving", peripheral.identifier.uuidString)
        }
        let receiveMessage = characteristicData.count == info.EOM.count && characteristicData == info.EOM
        if !receiveMessage {
            // receive chunk
            data.append(characteristicData)
        }
        
        if receiveMessage {
            // signal
            logDebug("received", peripheral.identifier.uuidString, data.count)
            delegate?.tnBluetoothClient(ble: self, receivedID: peripheral.identifier.uuidString, receivedData: data)
            data.removeAll()
        }

        dataQueue[peripheral.identifier.uuidString] = data
    }

    /*
     *  The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            logDebug("Error changing notification state:", error.localizedDescription)
            return
        }
        
        // Exit if it's not the transfer characteristic
        guard characteristic.uuid == info.bleCharacteristicUUID else {
            return
        }
        
        if characteristic.isNotifying {
            // Notification has started
            logDebug("Notification began on: ", characteristic.service!.uuid.uuidString)
        } else {
            // Notification has stopped, so disconnect from the peripheral
            logDebug("Notification stopped on: ", characteristic.service!.uuid.uuidString)
//            cleanup()
        }
    }
    
    /*
     *  This is called when peripheral is ready to accept more data when using write without response
     */
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        for worker in sendingWorkers {
            if worker.peripheral == peripheral {
                worker.send()
            }
        }
    }
}

// MARK: functional
extension TnBluetoothClient {
    private func changeStatus(_ status: Status) {
        self.status = status
        delegate?.tnBluetoothClient(ble: self, statusChanged: status)
    }
    
    public func setupBle() {
        centralManager = CBCentralManager(delegate: self, queue: centralQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    private func setup() {
        let connectedPeripherals: [CBPeripheral] = (centralManager.retrieveConnectedPeripherals(withServices: [info.bleServiceUUID]))
        
        if !connectedPeripherals.isEmpty {
            for peripheral in connectedPeripherals {
                centralManager.connect(peripheral, options: nil)
            }
        } else {
            // We were not connected to our counterpart, so start scanning
            centralManager.scanForPeripherals(
                withServices: [info.bleServiceUUID],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            )
        }
        
        changeStatus(.inited)
    }
    
    /*
     *  Call this when things either go wrong, or you're done with the connection.
     *  This cancels any subscriptions if there are any, or straight disconnects if not.
     *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
     */
    private func cleanup() {
        // Don't do anything if we're not connected
        guard centralManager != nil else {
            return
        }
        
        for peripheral in self.connectedPeripherals {
            disconnect(peripheral: peripheral)
        }
        connectedPeripherals.removeAll()
        sendingWorkers.removeAll()
        
        changeStatus(.cleanup)
    }
    
    public func send(data: Data, peripheralIDs: [String]? = nil) {
        guard transferCharacteristic != nil else {
            return
        }
        
        let peripherals = peripheralIDs == nil || peripheralIDs!.isEmpty ? self.connectedPeripherals : peripheralIDs!.map { v in self.connectedPeripherals.first(byID: v)! }
        for peripheral in peripherals {
            TnBluetoothClient.sendingWorkerID += 1
            let worker = SendingWorker(
                id: TnBluetoothClient.sendingWorkerID,
                outer: self,
                peripheral: peripheral,
                data: data
            )
            sendingWorkers.append(worker)
        }
    }
    
    public func connect(peripheralID: String) {
        if let peripheral = discoveredPeripherals.first(byID: peripheralID) {
            // connect to the peripheral.
            logDebug("Connecting to perhiperal", peripheral.name!)
            centralManager!.connect(peripheral, options: nil)
        }
    }
    
    public func disconnect(peripheralID: String) {
        if let peripheral = discoveredPeripherals.first(byID: peripheralID) {
            disconnect(peripheral: peripheral)
        }
    }
    
    public func disconnect(peripheral: CBPeripheral) {
        if peripheral.state == .connected {
            logDebug("Disconnecting from perhiperal", peripheral.name!)

            for service in (peripheral.services ?? [] as [CBService]) {
                for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                    if characteristic.uuid == info.bleCharacteristicUUID && characteristic.isNotifying {
                        // It is notifying, so unsubscribe
                        peripheral.setNotifyValue(false, for: characteristic)
                    }
                }
            }
            // If we've gotten this far, we're connected, but we're not subscribed, so we just disconnect
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}

extension TnBluetoothClient {
    public func send(msg: TnMessage, peripheralIDs: [String]? = nil) {
        logDebug("send", msg.typeCode)
        self.send(data: msg.data, peripheralIDs: peripheralIDs)
    }
    
    public func send(object: TnMessageProtocol, peripheralIDs: [String]? = nil) throws {
        self.send(msg: try object.toMessage(encoder: info.encoder), peripheralIDs: peripheralIDs)
    }
}

extension TnBluetoothClient: TnTransportableProtocol {
    public func send(_ data: Data) {
        self.send(data: data, peripheralIDs: nil)
    }
}
