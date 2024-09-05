//
//  TnPublisher.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/20/24.
//

import Foundation
import Combine

extension Published.Publisher {
    public func onReceive(queue: DispatchQueue, debounceMs: Double, cancelables: inout Set<AnyCancellable>, handler: @escaping (Self.Output) -> Void) {
        self
            .debounce(for: .seconds(debounceMs/1000), scheduler: queue)
            .receive(on: queue)
            .sink(receiveValue: handler)
            .store(in: &cancelables)
    }
    
    public func onReceive(debounceMs: Double, cancelables: inout Set<AnyCancellable>, handler: @escaping (Self.Output) -> Void) {
        self
            .debounce(for: .seconds(debounceMs/1000), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
            .store(in: &cancelables)
    }
    
    public func onReceive(queue: DispatchQueue, cancelables: inout Set<AnyCancellable>, handler: @escaping (Self.Output) -> Void) {
        self
            .receive(on: queue)
            .sink(receiveValue: handler)
            .store(in: &cancelables)
    }

    public func onReceive(cancelables: inout Set<AnyCancellable>, handler: @escaping (Self.Output) -> Void) {
        self
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
            .store(in: &cancelables)
    }
}

