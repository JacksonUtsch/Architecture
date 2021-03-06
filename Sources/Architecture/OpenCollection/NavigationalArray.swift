//
//  NavigationalArray.swift
//  Architecture
//
//  Created by Jackson Utsch on 5/6/21.
//

import Foundation

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
	
	// MARK: Need to fix destructive indexing..
	public mutating func new(_ element: C.Element) {
		guard element != current else { return }
		guard let index = index else {
			if collection.isEmpty {
				collection = [element]
				self.index = 0
			} else {
				collection.insert(element, at: 0)
				for i in collection.indices.reversed() {
					if i > 0 {
						collection.remove(at: i)
					}
				}
			}
			return
		}
		self.collection.insert(element, at: index + 1)
		self.index = index + 1
		for i in collection.indices.reversed() {
			if i > index + 1 {
				collection.remove(at: i)
			}
		}
	}
	
	/// retruns true if successful
	@discardableResult
	public mutating func pull() -> Bool {
		guard let index = index else { return false }
		guard index > 0 else { return false }
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
		guard self.collection.indices.contains(index + 1) else { return false }
		self.index = index + 1
		return true
	}
}

extension NavigationalArray: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.collection == rhs.collection &&
			lhs.index == rhs.index
	}
}

extension NavigationalArray: Codable where T: Codable {
	
}
