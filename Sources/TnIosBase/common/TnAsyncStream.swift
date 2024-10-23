//
//  TnAsyncStream.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/23/24.
//

import Foundation

public final class TnAsyncStream<TElement> {
    public typealias TAsyncStream = AsyncStream<TElement>
    public typealias TAsyncContinuation = TAsyncStream.Continuation

    private var continuation: TAsyncContinuation!
    public private(set) var stream: TAsyncStream!
    
    public init() {
        self.stream = .init { continuation in
            self.continuation = continuation
        }
    }
    
    public init(capacities: Int) {
        self.stream = .init(bufferingPolicy: .bufferingNewest(capacities)){ continuation in
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
