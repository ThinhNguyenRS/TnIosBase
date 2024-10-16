//
//  TnLockable.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/16/24.
//

import Foundation


@propertyWrapper
public struct TnLockable<T> {

    private let lock = NSLock()
    private var value: T

    public init(wrappedValue: T) {
        self.value = wrappedValue
    }

    public var wrappedValue: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            value = newValue
        }
    }
}
