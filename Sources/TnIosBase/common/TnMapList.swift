//
//  TnMapList.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 9/12/21.
//

import Foundation

struct TnMapList<TItem: Identifiable> {
    private var _map: [TItem.ID: TItem] = [:]
    private var _sorter: ((TItem, TItem) -> Bool)?
    private var _list: [TItem] = []

    init(sorter: ((TItem, TItem) -> Bool)? = nil) {
        self._sorter = sorter
    }
    
    private mutating func _updateList() {
        if _sorter != nil {
            _list = _map.values.sorted(by: _sorter!)
        } else {
            _list = [TItem](_map.values)
        }
    }
    
    mutating func set(list: [TItem]) {
        for item in list {
            _map[item.id] = item
        }
        _updateList()
    }

    @inlinable var count: Int {
        _map.count
    }

    mutating func remove(_ item: TItem) {
        _map.removeValue(forKey: item.id)
        _updateList()
    }
    
    mutating func remove(id: TItem.ID) {
        _map.removeValue(forKey: id)
        _updateList()
    }

    mutating func remove(condition: (TItem) -> Bool) {
        let items = self.filter(condition)
        for item in items {
            _map.removeValue(forKey: item.id)
        }
        _updateList()
    }
    
    mutating func clear() {
        _map.removeAll()
        _list.removeAll()
    }

    @inlinable mutating func removeAll() {
        clear()
    }

    @inlinable func contains(_ id: TItem.ID) -> Bool {
        let item = _map[id]
        return item != nil
    }

    @inlinable func get(_ id: TItem.ID) -> TItem? {
        _map[id]
    }
    
    mutating func set(_ item: TItem) {
        _map[item.id] = item
        _updateList()
    }
    
    @inlinable func values() -> [TItem] {
        _list
    }

    @inlinable func keys() -> [TItem.ID] {
        [TItem.ID](_map.keys)
    }
    
    func filter(_ condition: (TItem) -> Bool, sort: Bool = true) -> [TItem] {
        var ret = _list.filter(condition)
        if sort, let sorter = _sorter {
            ret.sort(by: sorter)
        }
        return ret;
    }
    
    var first: TItem? {
        _list.first
    }

    func first(_ condition: (TItem) -> Bool) -> TItem? {
        _list.first(where: condition)
    }
    
    func isDuplicate(_ item: TItem, _ condition: (TItem) -> Bool) -> Bool {
        _list.contains(where: {p in condition(p) && p.id != item.id} )
    }

    func isDuplicate(_ id: TItem.ID, _ condition: (TItem) -> Bool) -> Bool {
        _list.contains(where: {p in condition(p) && p.id != id} )
    }

//    func first(_ condition: (TItem) -> Bool) -> TItem? {
//        _list.first { value in
//            condition(value)
//        }
//    }
//
//    func last(_ condition: (TItem) -> Bool) -> TItem? {
//        _list.last { value in
//            condition(value)
//        }
//    }
//
//    func contains(_ condition: (TItem) -> Bool) -> Bool {
//        _list.contains { value in
//            condition(value)
//        }
//    }

    func loop(_ handler: (Int, TItem) -> Void) {
        for (idx, item) in _list.enumerated() {
            handler(idx, item)
        }
    }
}
