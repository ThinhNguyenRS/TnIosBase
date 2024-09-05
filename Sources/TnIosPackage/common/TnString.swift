//
//  TnString.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 8/27/21.
//

import Foundation

extension String {
    func toData() -> Data? {
        var ret: Data?
        if self.count > 0 {
            ret = self.data(using: .utf8)!
        }
        return ret
    }
    
    func toObject<T: Decodable>(_ type: T.Type) -> T? {
        var ret: T?
        if let data = self.toData() {
            let decoder = JSONDecoder()
            do {
                ret = try decoder.decode(T.self, from: data)
            } catch {
                TnLogger.error("JSON to object", type, self, error.localizedDescription)
            }
        }
        return ret
    }
    
    func toObjectArray<T: Decodable>(_ type: T.Type) -> [T] {
        var ret: [T] = []
        if let data = self.toData() {
            let decoder = JSONDecoder()
            ret = (try? decoder.decode([T].self, from: data)) ?? []
        }
        return ret
    }

    func decodeToInt(_ radix: Int = 30) -> UInt64? {
        return UInt64(self, radix: radix)
    }
    
    func containsInsensitive(_ of: String) -> Bool {
        if let _ = self.range(of: of, options: [.caseInsensitive, .diacriticInsensitive]) {
            return true
        }
        return false
    }

    func equalsInsensitive(_ of: String) -> Bool {
        self.compare(of, options: [.caseInsensitive, .diacriticInsensitive]).rawValue == 0
    }
}

/// suffix/prefix
extension String {
    func prefix(last: String) -> String? {
        if let foundIndex = self.range(of: last, options: .backwards)?.lowerBound {
            return String(self[..<foundIndex])
        }
        return nil
    }
    func prefix(first: String) -> String? {
        if let foundIndex = self.range(of: first)?.lowerBound {
            return String(self[..<foundIndex])
        }
        return nil
    }

    func subfix(last: String) -> String? {
        if let foundIndex = self.range(of: last, options: .backwards)?.lowerBound {
            return String(self[self.index(foundIndex, offsetBy: last.count)...])
        }
        return nil
    }
    func subfix(first: String) -> String? {
        if let foundIndex = self.range(of: first)?.lowerBound {
            return String(self[self.index(foundIndex, offsetBy: first.count)...])
        }
        return nil
    }
    
    func trim() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\0", with: "")
    }
    
    func format(_ arguments: any CVarArg...) -> String {
        return String(format: self, arguments)
    }
}

