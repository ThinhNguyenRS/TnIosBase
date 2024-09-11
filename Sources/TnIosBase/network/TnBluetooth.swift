//
//  TnBluetooth.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/15/24.
//

import Foundation
import CoreBluetooth

public struct TnNetworkServiceInfo {
    public let bleServiceUUID: CBUUID
    public let bleCharacteristicUUID: CBUUID
    public let bleRssiMin: Int
    public let EOM: Data
    public let MTU: Int
    
    public init(bleServiceUUID: CBUUID, bleCharacteristicUUID: CBUUID, bleRssiMin: Int, EOM: Data, MTU: Int) {
        self.bleServiceUUID = bleServiceUUID
        self.bleCharacteristicUUID = bleCharacteristicUUID
        self.bleRssiMin = bleRssiMin
        self.EOM = EOM
        self.MTU = MTU
    }
}

public struct TnBluetoothPeripheralInfo: Hashable {
    public let id: String
    public let name: String
}

extension Sequence where Element: CBPeripheral {
    public func contains(byID: Element) -> Bool {
        self.contains(where: { v in v.identifier.uuidString == byID.identifier.uuidString})
    }
    
    public func contains(byID: String) -> Bool {
        self.contains(where: { v in v.identifier.uuidString == byID})
    }

    public func first(byID: String) -> Element? {
        self.first(where: { v in v.identifier.uuidString == byID })
    }
    
    public func toInfoList() -> [TnBluetoothPeripheralInfo] {
        self.map { v in TnBluetoothPeripheralInfo(id: v.identifier.uuidString, name: v.name ?? v.identifier.uuidString)}
    }
}

extension Array where Element: CBPeripheral {
    public mutating func removeAll(byID: Element) {
        self.removeAll(where: { v in v.identifier.uuidString == byID.identifier.uuidString })
    }

    public mutating func removeAll(byID: String) {
        self.removeAll(where: { v in v.identifier.uuidString == byID })
    }
}

extension Sequence where Element: CBCentral {
    public func contains(byID: Element) -> Bool {
        self.contains(where: { v in v.identifier.uuidString == byID.identifier.uuidString})
    }
    
    public func contains(byID: String) -> Bool {
        self.contains(where: { v in v.identifier.uuidString == byID})
    }

    public func first(byID: String) -> Element? {
        self.first(where: { v in v.identifier.uuidString == byID })
    }
}

extension Array where Element: CBCentral {
    public mutating func removeAll(byID: Element) {
        self.removeAll(where: { v in v.identifier.uuidString == byID.identifier.uuidString })
    }

    public mutating func removeAll(byID: String) {
        self.removeAll(where: { v in v.identifier.uuidString == byID })
    }
}
