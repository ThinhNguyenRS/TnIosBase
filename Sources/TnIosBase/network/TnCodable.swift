//
//  TnCodable.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/8/24.
//

import Foundation

public protocol TnEncoder {
    func encode<T>(_ value: T) throws -> Data where T : Encodable
}

public protocol TnDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

public struct TnJsonEncoder: TnEncoder {
    private let encoder = JSONEncoder()
    
    public init() {}
    
    public func encode<T>(_ value: T) throws -> Data where T : Encodable {
        try encoder.encode(value)
    }
}

public struct TnJsonDecoder: TnDecoder {
    private let decoder = JSONDecoder()

    public init() {}

    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        try decoder.decode(type, from: data)
    }
}
