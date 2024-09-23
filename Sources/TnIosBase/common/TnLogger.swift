//
//  TnLogger.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 8/31/21.
//

import Foundation
import OSLog

extension OSLogType: @retroactive Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public class TnLogger {
    private init() {}
    public static var logLevel: OSLogType = .debug
        
    public static func _log(_ level: OSLogType, _ name: String, _ items: Any?...) {
        var msg: String = ""
        msg += "[\(name)]"

        for it in items {
            if let it {
                msg += " \(it)"
            }
        }
        os_log(level, log: .default, "\(msg)")
    }

    public static func debug(_ name: String, _ items: Any?...) {
        _log(.debug, name, items)
    }
    public static func error(_ name: String, _ items: Any?...) {
        _log(.error, name, items)
    }
}

public protocol TnLoggable {
    static var LOG_NAME: String { get }
}

extension TnLoggable {
    public func logDebug(_ items: Any?...) {
        TnLogger.debug(Self.LOG_NAME, items)
    }
    
    public func logError(_ items: Any?...) {
        TnLogger.error(Self.LOG_NAME, items)
    }
}
