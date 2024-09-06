//
//  TnCollectionExtensions.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 12/08/2021.
//

import Foundation

extension Array {
    public struct FoundEntry {
        let idx: Index
        var item: Element
    }
    
    public mutating func replace(of: Element, filter: (Element, Element) -> Bool) {
        if let index = self.firstIndex(where: { item in filter(of, item) }) {
            self[index] = of
        }
    }
    
    public func forEach(_ handler: @escaping (Int, Element) -> Void) {
        for (idx, entry) in self.enumerated() {
            handler(idx, entry)
        }
    }

    public mutating func forEachMutable(_ handler: @escaping (Int, inout Element) -> Void) {
        for idx in self.indices {
            var entry = self[idx]
            handler(idx, &entry)
            // set back
            self[idx] = entry
        }
    }

    public mutating func forEachMutable(_ handler: @escaping (Int, inout Element) throws -> Void) rethrows {
        for idx in self.indices {
            var entry = self[idx]
            try handler(idx, &entry)
            // set back
            self[idx] = entry
        }
    }

    public func find(_ condition: (Element) -> Bool) -> FoundEntry? {
        if let index = self.firstIndex(where: condition) {
            return FoundEntry(idx: index, item: self[index])
        }
        return nil
    }
}

extension Array where Element: Equatable {
    @discardableResult public mutating func remove(of: Element) -> Bool {
        if let index = self.firstIndex(of: of) {
            self.remove(at: index)
            return true
        }
        return false
    }
}

extension Array where Element: TnEntityItem {
    @discardableResult public mutating func remove(id: String) -> Bool {
        if let index = self.firstIndex(where: { item in item.getId() == id }) {
            self.remove(at: index)
            return true
        }
        return false
    }
    
    public mutating func replace(_ of: Element) {
        if let index = self.firstIndex(where: { item in item.getId() == of.getId() }) {
            self[index] = of
        }
    }
    
    public mutating func replaceOrAdd(_ of: Element) {
        if let index = self.firstIndex(where: { item in item.getId() == of.getId() }) {
            self[index] = of
        } else {
            self.append(of)
        }
    }
    
    public func find(id: String?) -> FoundEntry? {
        if id == nil {
            return nil
        }
        
        if let index = self.firstIndex(where: { item in item.getId() == id! }) {
            return FoundEntry(idx: index, item: self[index])
        }
        return nil
    }
}

extension Array where Element: Identifiable {
    public func contains(_ item: Element) -> Bool {
        contains(where: {it in it.id == item.id })
    }
    
    @discardableResult public mutating func remove(id: Element.ID) -> Bool {
        if let index = self.firstIndex(where: { item in item.id == id }) {
            self.remove(at: index)
            return true
        }
        return false
    }
    
    public mutating func replace(_ of: Element) {
        if let index = self.firstIndex(where: { item in item.id == of.id }) {
            self[index] = of
        }
    }
    
    public mutating func replaceOrAdd(_ of: Element) {
        if let index = self.firstIndex(where: { item in item.id == of.id }) {
            self[index] = of
        } else {
            self.append(of)
        }
    }
    
    public func find(id: Element.ID?) -> Element? {
        if id == nil {
            return nil
        }
        
        if let index = self.firstIndex(where: { item in item.id == id! }) {
            return self[index]
        }
        return nil
    }
}

extension Comparable {
    public func valueInRange(_ bounds: ClosedRange<Self>) -> Self {
        var valueValid = self
        if !bounds.isEmpty {
            if valueValid < bounds.lowerBound {
                valueValid = bounds.lowerBound
            }
            if valueValid > bounds.upperBound {
                valueValid = bounds.upperBound
            }
        }
        return valueValid
    }

    public func valueInRange(_ bounds: [Self]) -> Self {
        var valueValid = self
        if bounds.count > 0 {
            if valueValid < bounds.min()! {
                valueValid = bounds.min()!
            }
            if valueValid > bounds.max()! {
                valueValid = bounds.max()!
            }
        }
        return valueValid
    }
}

extension Equatable {
    public func isIn(_ items: Self...) -> Bool {
        items.contains(self)
    }
    
    public func isIn(_ items: any Sequence<Self>) -> Bool {
        items.contains(self)
    }
}


extension Dictionary {
    public mutating func getOrSet(key: Key, defaultGetter: () -> Value) -> Value {
        var v = self[key]
        if v == nil {
            v = defaultGetter()
            self[key] = v
        }
        return v!
    }
}

public protocol TnInitializable {
    init()
}

extension Dictionary where Value: TnInitializable {
    public mutating func getOrSet(key: Key) -> Value {
        self.getOrSet(key: key, defaultGetter: { Value.init() })
    }
}

extension Data: TnInitializable {
    
}
