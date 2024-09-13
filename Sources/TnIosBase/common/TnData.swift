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

extension Data {
    func split(separator: Data) -> [Data] {
        var chunks: [Data] = []
        var pos = startIndex
        // Find next occurrence of separator after current position:
        while let r = self[pos...].range(of: separator) {
            // Append if non-empty:
            if r.lowerBound > pos {
                chunks.append(self[pos..<r.lowerBound])
            }
            // Update current position:
            pos = r.upperBound
        }
        // Append final chunk, if non-empty:
        if pos < endIndex {
            chunks.append(self[pos..<endIndex])
        }
        return chunks
    }
}

