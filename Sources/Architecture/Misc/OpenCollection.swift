//
//  OpenCollection.swift
//  Architecture
//
//  Created by Jackson Utsch on 3/29/21.
//

import Foundation

// MARK: OpenCollection
public protocol OpenCollection {
    associatedtype C: MutableCollection
    associatedtype E
    var collection: C { get set }
    var index: C.Index? { get  set }
    var current: E? { get }
    
    init(_ collection: C, at index: C.Index?)
}

public extension OpenCollection {
    var current: C.Element? {
        return collection[safe: index]
    }
    
    subscript(index: C.Index?) -> C.Element? {
        get {
            return collection[safe: index]
        }

        set(value) {
            guard let index = index else { return }
            guard let value = value else { return }
            self.collection[index] = value
        }
    }
}

public extension OpenCollection where C == Array<E>, C.Element: Identifiable {
    mutating func clear() {
        self.collection = []
        self.index = nil
    }
        
    mutating func open(using id: C.Element.ID?) {
        guard let id = id else {
            index = nil
            return
        }
        index = collection.firstIndex(where: {$0.id == id})
    }
    
    mutating func close(at i: Int) {
        guard let closingIndex = collection.indices.firstIndex(where: {$0 == i}) else {
            return
        }
        collection.remove(at: closingIndex)
        
        guard let index = self.index else {
            return
        }
        
        if index >= closingIndex {
            if index - 1 >= 0 {
                self.index = index - 1
            } else {
                if collection.count <= 0 {
                    self.index = nil
                }
            }
        }
    }
    
    mutating func close(using id: C.Element.ID) {
        guard let closingIndex = collection.firstIndex(where: {$0.id == id}) else {
            return
        }
        self.collection.remove(at: closingIndex)
        
        guard let index = self.index else {
            return
        }
        
        if index >= closingIndex {
            if index - 1 >= 0 {
                self.index = index - 1
            } else {
                if collection.count <= 0 {
                    self.index = nil
                }
            }
        }
    }
}

// MARK: OpenArray
public struct OpenArray<T: Identifiable>: OpenCollection {
    public typealias C = [T]
    public typealias E = C.Element
    public var collection: C
    public var index: C.Index?
    
    public init(_ collection: C, at index: C.Index?) {
        self.collection = collection
        self.index = index
    }
}

extension OpenArray: Codable where T: Codable {
    
}

public extension OpenArray {
    enum Specifier {
        case current
        case using(T.ID)
        case at(C.Index)
    }
    
    mutating func new(_ element: C.Element) {
        guard let index = index else {
            print("no index")
            if collection.isEmpty {
                collection = [element]
                self.index = 0
            } else {
                collection.insert(element, at: 0)
            }
            return
        }
        print("has index")
        
        self.collection.insert(element, at: index + 1)
        self.index = index + 1
    }
    
    func findIndex(with specifier: Specifier) -> C.Index? {
        var index: C.Index!
        switch specifier {
        case .current:
            guard let current = self.index else { return nil }
            index = current
        case .using(let id):
            guard let current = self.collection.firstIndex(where: {$0.id == id}) else { return nil }
            index = current
        case .at(let i):
            return i
        }
        return index
    }
    
    mutating func open(with specifier: Specifier) {
        switch specifier {
        case .current:
            self.index = findIndex(with: specifier)
        case .using(let id):
            self.open(using: id)
        case .at(let index):
            self.index = index
        }
    }
    
    mutating func close(with specifier: Specifier) {
        switch specifier {
        case .current:
            guard let current = self.index else { return }
            self.close(at: current)
        case .using(let id):
            self.close(using: id)
        case .at(let index):
            self.close(at: index)
        }
    }
}

// MARK: NavigationalArray
public struct NavigationalArray<T: Identifiable & Equatable>: OpenCollection {
    public typealias C = [T]
    public typealias E = C.Element
    public var collection: C
    public var index: C.Index?

    public init(_ collection: C, at index: C.Index?) {
        self.collection = collection
        self.index = index
    }
    
    public mutating func new(_ element: C.Element) {
        guard element != current else {
            return
        }
        
        guard let index = index else {
            print("no index")
            if collection.isEmpty {
                collection = [element]
                self.index = 0
            } else {
                collection.insert(element, at: 0)
            }
            return
        }
        print("has index")
        
        self.collection.insert(element, at: index + 1)
        self.index = index + 1
    }
    
    /// retruns true if successful
    @discardableResult
    public mutating func pull() -> Bool {
        guard let index = index else {
            return false
        }
        
        guard index > 0 else {
            return false
        }
        self.index = index - 1
        return true
    }
    
    /// retruns true if successful
    @discardableResult
    public mutating func push() -> Bool {
        guard let index = index else {
            if self.collection.count > 0 {
                self.index = 0
                return true
            }
            return false
        }
        
        guard self.collection.indices.contains(index + 1) else {
            return false
        }
        self.index = index + 1
        return true
    }
}

extension NavigationalArray: Codable where T: Codable {
    
}
