//
//  TnMessageSystem.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/15/24.
//

import Foundation

// MARK: TnMessageValue
public struct TnMessageValue<T: Codable>: TnMessageObject {
    public let typeCode: UInt8
    public let value: T
    
    public init(_ typeCode: UInt8, _ value: T) {
        self.typeCode = typeCode
        self.value = value
    }
}

extension TnMessageValue {
    public static func from<TEnum: RawRepresentable<UInt8>>(_ typeCode: TEnum, _ value: T) -> Self {
        Self.init(typeCode.rawValue, value)
    }
    
    public static func from<TEnum: RawRepresentable<UInt8>>(_ typeCode: TEnum, data: Data, decoder: TnDecoder) -> Self? {
        let msg = TnMessageData(data: data)
        if msg.typeCode == typeCode.rawValue {
            return msg.toObject(decoder: decoder)
        }
        return nil
    }
}
