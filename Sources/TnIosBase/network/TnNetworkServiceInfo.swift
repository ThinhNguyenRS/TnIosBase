//
//  TnNetworkServiceInfo.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/8/24.
//

import Foundation
import CoreBluetooth

public struct TnNetworkServiceInfo {
    public let bleServiceUUID: CBUUID
    public let bleCharacteristicUUID: CBUUID
    public let bleRssiMin: Int
    public let EOM: Data
    public let MTU: Int
    public let encoder: TnEncoder
    
    public init(bleServiceUUID: CBUUID, bleCharacteristicUUID: CBUUID, bleRssiMin: Int, EOM: Data, MTU: Int, encoder: TnEncoder) {
        self.bleServiceUUID = bleServiceUUID
        self.bleCharacteristicUUID = bleCharacteristicUUID
        self.bleRssiMin = bleRssiMin
        self.EOM = EOM
        self.MTU = MTU
        self.encoder = encoder
    }
}
