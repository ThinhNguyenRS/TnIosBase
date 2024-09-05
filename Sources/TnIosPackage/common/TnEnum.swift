//
//  TnEnum.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/12/24.
//

import Foundation

// MARK: RawRepresentable
extension RawRepresentable where RawValue: FixedWidthInteger {
    func plus(_ v: RawValue, _ m: RawValue) -> Self {
        let vv = (self.rawValue + v) % m
        return Self(rawValue: vv)!
    }

    func increase(_ m: RawValue) -> Self {
        return plus(1, m)
    }
    
    func decrease(_ m: RawValue) -> Self {
        return plus(-1, m)
    }
}

extension RawRepresentable where RawValue: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: TnEnum
public protocol TnEnum: Hashable, CaseIterable, Identifiable, Codable, Comparable {
    static var allCases: [Self] {get}
    static var allMap: Dictionary<Self, String> {get}
}

extension TnEnum {
    public static var allNames: [String] { allCases.map { v in allMap[v] ?? ""} }
    public var description: String {
        Self.allMap[self] ?? ""
    }
    
    public var id: Self { self }
}

extension Sequence where Element: TnEnum {
    public var descriptions: [String] {
        self.map { v in v.description }
    }
}

//extension TnEnum where Self: RawRepresentable, RawValue: Comparable {
//    public static func < (lhs: Self, rhs: Self) -> Bool {
//        lhs.rawValue < rhs.rawValue
//    }
//}

// MARK: TnTripleState
public enum TnTripleState: Int, TnEnum {
    case off
    case on
    case auto
    
    public static var allMap: Dictionary<TnTripleState, String> {
        [
            .off: "Off",
            .on: "On",
            .auto: "Auto"
        ]
    }
}

extension TnTripleState {
    public static func fromBool(_ v: Bool?) -> Self {
        if v != nil {
            return v! ? .on : .off
        } else {
            return .auto
        }
    }
    
    public static func fromTwoBool(_ v1: Bool, _ v2: Bool) -> Self {
        if v1 {
            return .auto
        } else {
            return v2 ? .on : .off
        }
    }
    
    public func next() -> Self {
        Self(rawValue: (self.rawValue + 1) % 3)!
    }
    
    public func toBool() -> Bool? {
        if self == .auto {
            return nil
        }
        return self == .on
    }
    
    public func toValue<TValue>(_ v1: TValue, _ v2: TValue, _ v3: TValue) -> TValue {
        switch self {
        case .auto:
            v1
        case .on:
            v2
        case .off:
            v3
        }
    }
}
