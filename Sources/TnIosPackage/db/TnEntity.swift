//
//  TnEntity.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 8/21/21.
//

import Foundation
//import SwiftProtobuf

public protocol TnJsonable {
    init(json: String) throws
    func json() throws -> String
}

public protocol TnEntityItem: TnJsonable, Equatable {
    static func getType() -> Int32
    static var `default`: Self {get}
    func getId() -> String
}

//extension Message {
//    init(json: String) throws {
//        try self.init(jsonString: json)
//    }
//    func json() throws -> String {
//        try self.jsonString()
//    }
//}
