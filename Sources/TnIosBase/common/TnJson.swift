//
//  TnJson.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 8/27/21.
//

import Foundation

extension Encodable {
    func toJsonData() throws -> Data {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            return data
        } catch {
            TnLogger.error("Encodable", "Cannot encode JSON", self, error.localizedDescription)
            throw error
        }
    }

    func toJson() throws -> String {
        let data = try self.toJsonData()
        let string = String(data: data, encoding: .utf8)!
        return string
    }
}
