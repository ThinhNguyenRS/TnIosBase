//
//  TnData.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 8/27/21.
//

import Foundation

// MARK: NSData toString
extension NSData {
    func toString() -> String {
        let dataString = String(decoding: self, as: UTF8.self)
        return dataString
    }
}

// MARK: Data toString
extension Data {
    func toString() -> String {
        let dataString = String(decoding: self, as: UTF8.self)
        return dataString
    }
}

// MARK: Data tnToObjectFromJSON
extension Data {
    func tnToObjectFromJSON<T: Decodable>(_ type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        let obj = try decoder.decode(type, from: self)
        return obj
    }
}


// MARK: Data split
extension Data {
    func split(separator: Data) -> [Data] {
        var chunks: [Data] = []
        var pos = startIndex
        // Find next occurrence of separator after current position:
        while let r = self[pos...].range(of: separator) {
            // Append if non-empty:
            if r.lowerBound > pos {
//                chunks.append(self[pos..<r.lowerBound])
                chunks.append(self.subdata(in: pos..<r.lowerBound))
            }
            // Update current position:
            pos = r.upperBound
        }
        // Append final chunk, if non-empty:
        if pos < endIndex {
//            chunks.append(self[pos..<endIndex])
            chunks.append(self.subdata(in: pos..<endIndex))
        }
        return chunks
    }
}

// MARK: FixedWidthInteger number to Data
extension FixedWidthInteger {
    /// number to Data
    public func toData() -> Data {
        withUnsafeBytes(of: self.bigEndian) { Data($0) }
    }
    
    /// data size of this type
    public static var size: Int {
        MemoryLayout<Self>.size
    }
}

// MARK: Data to number
extension Data {
    /// Data to number
    public func toNumber<T: FixedWidthInteger>() -> T {
        return self.withUnsafeBytes {
            $0.load(as: T.self).bigEndian
        }
    }
}
