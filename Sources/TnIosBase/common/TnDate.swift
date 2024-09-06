//
//  TnUtil.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 10/08/2021.
//

import Foundation


extension Date {
    public enum Format: String {
        case full = "yyyy-MM-dd HH:mm:ss"
        case fullMS = "yyyy-MM-dd HH:mm:ss.SSS"
        case date = "yyyy-MM-dd"
        case short = "MM/dd HH:mm:ss"
//        case dateShortVN = "dd/MM"
        case shortVN = "dd/MM HH:mm:ss"
        case hour = "HH:mm:ss"
    }

//    static let date2020: Date = Date.parse("2020-01-01 00:00:00")!
    public static let dateStart: Date = Date.parse("2021-09-15 00:00:00", .full)!
    
    static public func createDateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    public static var millisecondsFromStart: UInt64 {
        return Date.now().millisecondsFromStart
    }

    static public func now() -> Date {
        return Date()
    }

    static public func parse(_ s: String, _ format: String) -> Date? {
        let formatter = createDateFormatter(format)
        return formatter.date(from: s)
    }
    static public func parse(_ s: String, _ format: Format = .full) -> Date? {
        parse(s, format.rawValue)
    }

    init(millisecondsFrom1970: UInt64) {
        self.init(timeIntervalSince1970: TimeInterval(Double(millisecondsFrom1970) / 1000.0))
    }
    init(millisecondsFromStart: UInt64) {
        self.init(timeInterval: TimeInterval(Double(millisecondsFromStart) / 1000.0), since: Date.dateStart)
    }

    public var millisecondsFrom1970: UInt64 {
        return UInt64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    public var millisecondsFromStart: UInt64 {
        return UInt64((self.timeIntervalSince(Date.dateStart) * 1000.0).rounded())
    }

    public func toString(_ format: String) -> String {
        let formatter = Date.createDateFormatter(format)
        return formatter.string(from: self)
    }

    public func toString(_ format: Format = .full) -> String {
        toString(format.rawValue)
    }

    public func toStringMS() -> String {
        toString(.fullMS)
    }

    public func encodeToString(_ radix: Int = 30) -> String {
        return self.millisecondsFromStart.encodeToString(radix)
    }

    static public func tnFromEncoded(_ encoded: String?, radix: Int = 30) -> Date? {
        if let ms = encoded?.decodeToInt(radix) {
            return Date(millisecondsFromStart: ms)
        }
        return nil
    }

    static public func intervalSeconds(miliseconds: UInt64) -> TimeInterval {
        Double(miliseconds)/1000
    }

    static public func intervalSeconds(miliseconds: Int32) -> TimeInterval {
        Double(miliseconds)/1000
    }

    static public func intervalSeconds(seconds: Int32) -> TimeInterval {
        Double(seconds)
    }

    static public func intervalSeconds(seconds: Double) -> TimeInterval {
        seconds
    }

    static public func intervalSeconds(minutes: Int32) -> TimeInterval {
        Double(minutes)*60
    }
    
    static public func intervalSeconds(minutes: Double) -> TimeInterval {
        Double(minutes)*60
    }

    static let hourValues: [Int32] = Array(1...24)
    static let hourNames: [String] = hourValues.map { String(format: "%02d:00", $0) }

}

extension Date {
    public func add(value: Int, component: Calendar.Component = .day) -> Date {
        Calendar.current.date(byAdding: component, value: value, to: self)!
    }
}
