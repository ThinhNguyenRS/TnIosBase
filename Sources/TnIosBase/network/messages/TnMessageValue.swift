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
    public let value: T?
    
    public init(_ typeCode: UInt8, _ value: T?) {
        self.typeCode = typeCode
        self.value = value
    }
}
