//
//  TnBluetooth.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/15/24.
//

import Foundation
import CoreBluetooth

public struct TnBluetoothServiceInfo {
    public let serviceUUID: CBUUID
    public let characteristicUUID: CBUUID
    public let RssiMin: Int
    public let EOM: Data
    
    public init(serviceUUID: CBUUID, characteristicUUID: CBUUID, RssiMin: Int, EOM: Data) {
        self.serviceUUID = serviceUUID
        self.characteristicUUID = characteristicUUID
        self.RssiMin = RssiMin
        self.EOM = EOM
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
