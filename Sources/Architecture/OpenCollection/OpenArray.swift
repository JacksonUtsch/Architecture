//
//  OpenArray.swift.swift
//  Architecture
//
//  Created by Jackson Utsch on 5/6/21.
//

import Foundation

// MARK: OpenArray
public struct OpenArray<T: Identifiable & Equatable>: OpenCollection {
  public typealias C = [T]
  public typealias E = C.Element
  public var collection: C
  public var index: C.Index?
  
  public init(_ collection: C, at index: C.Index?) {
    self.collection = collection
    self.index = index
  }
}

extension OpenArray: Equatable {
  static public func == (lhs: Self, rhs: Self) -> Bool {
    lhs.collection == rhs.collection &&
      lhs.index == rhs.index
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
      if collection.isEmpty {
        collection = [element]
        self.index = 0
      } else {
        collection.insert(element, at: 0)
      }
      return
    }
    
    self.collection.insert(element, at: index + 1)
    self.index = index + 1
  }
  
  mutating func insert(
    _ element: C.Element,
    at position: C.Index
  ) {
    self.collection.insert(element, at: position)
    self.index = position
  }
  
  func index(from specifier: Specifier) -> C.Index? {
    switch specifier {
    case .current:
      guard let current = self.index else { return nil }
      return current
    case .using(let id):
      guard let current = self.collection.firstIndex(where: {$0.id == id}) else { return nil }
      return current
    case .at(let i):
      return i
    }
  }
  
  func id(from specifier: Specifier) -> T.ID? {
    switch specifier {
    case .current:
      guard let current = self.index else { return nil }
      return self.collection[safe: current]?.id
    case .using(let id):
      return id
    case .at(let i):
      return self.collection[safe: i]?.id
    }
  }
  
  mutating func open(with specifier: Specifier) {
    switch specifier {
    case .current:
      self.index = index(from: specifier)
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
