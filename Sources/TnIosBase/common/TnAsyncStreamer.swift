//
//  TnAsyncStream.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/23/24.
//

import Foundation

public final class TnAsyncStreamer<TElement> {
    public typealias TAsyncStream = AsyncStream<TElement>
    public typealias TAsyncContinuation = TAsyncStream.Continuation

    private var continuation: TAsyncContinuation!
    public private(set) var stream: TAsyncStream!
    
    public init(bufferingPolicy limit: TAsyncContinuation.BufferingPolicy) {
        self.stream = .init { continuation in
            self.continuation = continuation
        }
    }
    
    @discardableResult
    public func yield(_ v: TElement) -> TAsyncContinuation.YieldResult {
        continuation.yield(v)
    }
    
    public func finish() {
        continuation.finish()
    }
}

extension TnAsyncStreamer {
    public convenience init() {
        self.init(bufferingPolicy: .unbounded)
    }
    
    public convenience init(newest: Int) {
        self.init(bufferingPolicy: .bufferingNewest(newest))
    }
    
    public convenience init(oldest: Int) {
        self.init(bufferingPolicy: .bufferingOldest(oldest))
    }
}
