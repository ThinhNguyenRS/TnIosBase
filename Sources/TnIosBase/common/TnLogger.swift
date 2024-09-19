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
        
    public static func _log(_ level: OSLogType, _ name: String, showDate: Bool, _ items: Any?...) {
        var msg: String = ""
        if showDate {
            msg += "[\(Date.now().toStringMS())]"
        }
        msg += "[\(name)]"

        for it in items {
            if let it {
                msg += " \(it)"
            }
        }
        os_log(level, log: .default, "\(msg)")
    }

    public static func debug(_ name: String, showDate: Bool = true, _ items: Any?...) {
        _log(.debug, name, showDate: showDate, items)
    }
    public static func error(_ name: String, showDate: Bool = true, _ items: Any?...) {
        _log(.error, name, showDate: showDate, items)
    }
}

public protocol TnLoggable {
    var LOG_NAME: String { get }
}

extension TnLoggable {
    public func logDebug(showDate: Bool = true, _ items: Any?...) {
        TnLogger.debug(LOG_NAME, showDate: showDate, items)
    }
    
    public func logError(showDate: Bool = true, _ items: Any?...) {
        TnLogger.error(LOG_NAME, showDate: showDate, items)
    }
}
