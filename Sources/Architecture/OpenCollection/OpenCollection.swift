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
		guard let closingIndex = collection.indices.firstIndex(where: {$0 == i}) else { return }
		collection.remove(at: closingIndex)
		guard let index = self.index else { return }
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
		guard let closingIndex = collection.firstIndex(where: {$0.id == id}) else { return }
		self.collection.remove(at: closingIndex)
		guard let index = self.index else { return }
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
