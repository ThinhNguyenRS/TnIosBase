//
//  TnNetworkServiceInfo.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/8/24.
//

import Foundation
import CoreBluetooth

public struct TnNetworkBleInfo {
    public let bleServiceUUID: CBUUID
    public let bleCharacteristicUUID: CBUUID
    public let bleRssiMin: Int
    
    public init(bleServiceUUID: CBUUID, bleCharacteristicUUID: CBUUID, bleRssiMin: Int) {
        self.bleServiceUUID = bleServiceUUID
        self.bleCharacteristicUUID = bleCharacteristicUUID
        self.bleRssiMin = bleRssiMin
    }
}

public struct TnNetworkTransportingInfo {
    public let EOM: Data
    public let MTU: Int
    public let encoder: TnEncoder
    
    public init(EOM: Data, MTU: Int, encoder: TnEncoder) {
        self.EOM = EOM
        self.MTU = MTU
        self.encoder = encoder
    }
}
