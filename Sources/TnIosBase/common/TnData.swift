//
//  TnData.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 8/27/21.
//

import Foundation

extension Data {
    func toString() -> String {
        let dataString = String(decoding: self, as: UTF8.self)
        return dataString
    }
    
    func tnToObjectFromJSON<T: Decodable>(_ type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        let obj = try decoder.decode(type, from: self)
        return obj
    }
}

extension NSData {
    func toString() -> String {
        let dataString = String(decoding: self, as: UTF8.self)
        return dataString
    }
}
