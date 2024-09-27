//
//  TnPublisher.swift
//  tCamera
//
//  Created by Thinh Nguyen on 8/20/24.
//

import Foundation
import Combine

public var tnGlobalCancellables: Set<AnyCancellable> = .init()

extension Published.Publisher {
    public func onReceive(queue: DispatchQueue, debounceMs: Double, cancellables: inout Set<AnyCancellable>, handler: @escaping (Self.Output) -> Void) {
        self
            .debounce(for: .seconds(debounceMs/1000), scheduler: queue)
            .receive(on: queue)
            .sink(receiveValue: handler)
            .store(in: &cancellables)
    }
    
    public func onReceive(queue: DispatchQueue, debounceMs: Double, handler: @escaping (Self.Output) -> Void) {
        self
            .debounce(for: .seconds(debounceMs/1000), scheduler: queue)
            .receive(on: queue)
            .sink(receiveValue: handler)
            .store(in: &tnGlobalCancellables)
    }
    
    public func onReceive(debounceMs: Double, cancellables: inout Set<AnyCancellable>, handler: @escaping (Self.Output) -> Void) {
        self
            .debounce(for: .seconds(debounceMs/1000), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
            .store(in: &cancellables)
    }
    
    public func onReceive(debounceMs: Double, handler: @escaping (Self.Output) -> Void) {
        self
            .debounce(for: .seconds(debounceMs/1000), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
            .store(in: &tnGlobalCancellables)
    }
    
    public func onReceive(queue: DispatchQueue, cancellables: inout Set<AnyCancellable>, handler: @escaping (Self.Output) -> Void) {
        self
            .receive(on: queue)
            .sink(receiveValue: handler)
            .store(in: &cancellables)
    }
    
    public func onReceive(queue: DispatchQueue, handler: @escaping (Self.Output) -> Void) {
        self
            .receive(on: queue)
            .sink(receiveValue: handler)
            .store(in: &tnGlobalCancellables)
    }
    
    public func onReceive(cancellables: inout Set<AnyCancellable>, handler: @escaping (Self.Output) -> Void) {
        self
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
            .store(in: &cancellables)
    }
    
    public func onReceive(handler: @escaping (Self.Output) -> Void) {
        self
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
            .store(in: &tnGlobalCancellables)
    }
}
