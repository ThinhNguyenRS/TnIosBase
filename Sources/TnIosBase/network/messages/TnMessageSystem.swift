//
//  TnMessageSystem.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/15/24.
//

import Foundation

// MARK: TnMessageSystem
public enum TnMessageSystem: UInt8, CaseIterable {
    case indetifier
}

extension TnMessageSystem {
    public static func toMessageIndentifier(name: String) -> TnMessageValue<String> {
        TnMessageValue(Self.indetifier.rawValue, name)
    }
    
    public static func toMessageIndentifier(data: Data, decoder: TnDecoder) -> TnMessageValue<String>? {
        let msg = TnMessageData(data: data)
        if msg.typeCode == Self.indetifier.rawValue {
            return msg.toObject(decoder: decoder)
        }
        return nil
    }
}
