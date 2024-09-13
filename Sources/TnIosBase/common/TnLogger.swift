//
//  TnLogger.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 8/31/21.
//

import Foundation

public class TnLogger {
    private init() {}
    
    public enum LogLevel: Int, Comparable {
        public static func < (lhs: TnLogger.LogLevel, rhs: TnLogger.LogLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        case debug, warning, error
    }
    public static var logLevel: LogLevel = .debug
        
    public static func _log(_ level: LogLevel, _ name: String, showDate: Bool, _ items: Any?...) {
        if level >= logLevel {
            if showDate {
                print("[\(Date.now().toStringMS())]", terminator: " ")
            }

            print("[\(name)]", terminator: " ")
            for it in items {
                print(it ?? "", terminator: " ")
            }

            print("\n", terminator: "")
        }
    }

    public static func debug(_ name: String, showDate: Bool = true, _ items: Any?...) {
        _log(.debug, name, showDate: showDate, items)
    }
    public static func warning(_ name: String, showDate: Bool = true, _ items: Any?...) {
        _log(.warning, name, showDate: showDate, items)
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
