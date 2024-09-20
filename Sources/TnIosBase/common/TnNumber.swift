//
//  TnNumber.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 8/27/21.
//

import Foundation

extension FixedWidthInteger {
    public func encodeToString(_ radix: Int = 30) -> String {
        return String(self, radix: radix)
    }

    public mutating func inc(_ v: Self = 1) -> Self {
        self += v
        return self
    }
}

extension CVarArg {
    public func toString(_ format: String? = nil) -> String {
        String(format: format ?? "", self)
    }
}

public func getNumberFormatter(_ specifier: String) -> ((CVarArg) -> String) {
    { v in
        v.toString(specifier)
    }
}

public func getNumberPercentFormatter<TValue: BinaryFloatingPoint & CVarArg>(_ specifier: String = "0.0%%f") -> ((TValue) -> String) {
    { v in
        (v*100).toString(specifier)
    }
}

public let defaultNumberFormatter: (CVarArg) -> String = getNumberFormatter("0.1f")


//extension Float {
//    func toString(_ format: String = "%.2f") -> String {
//        String(format: format, self)
//    }
//}
//extension Double {
//    func toString(_ format: String = "%.2f") -> String {
//        String(format: format, self)
//    }
//}
//extension Int32 {
//    func toString(_ format: String = "%d") -> String {
//        String(format: format, self)
//    }
//}
//extension Int64 {
//    func toString(_ format: String = "%ld") -> String {
//        String(format: format, self)
//    }
//}

public func getValueInRange<T>(_ v: T, _ minV: T, _ maxV: T) -> T where T : Comparable {
    if v > maxV {
        return maxV
    }
    else if v < minV {
        return minV
    }
    return v
}

public func isValueInRange<T>(_ v: T, _ list: [T]) -> Bool where T: Equatable {
    var found = false
    for x in list {
        if v == x {
            found = true
            break
        }
    }
    return found
}

public func forceValueInRange<T>(_ v: inout T, _ list: [T], _ defaultValue: T? = nil) where T: Equatable {
    if !isValueInRange(v, list) {
        v = defaultValue ?? list.last!
    }
}
