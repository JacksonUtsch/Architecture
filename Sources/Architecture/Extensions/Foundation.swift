//
//  Foundation.swift
//  Architecture
//
//  Created by Jackson Utsch on 3/12/21.
//

import Foundation

// MARK: Optional Contains
public extension Optional where Wrapped: Collection, Wrapped.Element: Equatable {
	func contains(_ item: Wrapped.Iterator.Element) -> Bool {
		if let array = self {
			if array.contains(item) {
				return true
			}
		}
		return false
	}
}

// MARK: Optional Subscripting
public extension Collection {
	/// Returns the element at the specified index if it is within bounds, otherwise nil.
	subscript(safe index: Index?) -> Element? {
		guard let index = index else {
			return nil
		}
		return indices.contains(index) ? self[index] : nil
	}
}

public extension Array where Element: Identifiable {
	/// Returns the first element with the specefied id, otherwise nil.
	subscript(safe id: Element.ID?) -> Element? {
		guard let id = id else {
			return nil
		}
		return self.filter({$0.id == id}).first
	}
}

import CoreGraphics

// MARK: CGSize
public extension CGSize {
	var short: CGFloat {
		return Swift.min(self.width, self.height)
	}
	
	var long: CGFloat {
		return Swift.max(self.width, self.height)
	}
}

// MARK: setMap
extension Set {
	public func setMap<U>(transform: (Element) -> U) -> Set<U> {
		return Set<U>(self.lazy.map(transform))
	}
}

// MARK: Codable Array
extension Array: RawRepresentable where Element: Codable {
	public init?(rawValue: String) {
		guard let data = rawValue.data(using: .utf8),
					let result = try? JSONDecoder().decode([Element].self, from: data)
		else { return nil }
		self = result
	}
	public var rawValue: String {
		guard let data = try? JSONEncoder().encode(self),
					let result = String(data: data, encoding: .utf8)
		else { return "[]" }
		return result
	}
}

#if os(macOS)
// aid for encoding NSRect
extension NSRect: RawRepresentable {
	public init?(rawValue: String) {
		self = NSRectFromString(rawValue)
	}
	public var rawValue: String {
		NSStringFromRect(self)
	}
	public typealias RawValue = String
}
#endif

extension Bool {
	public func toggled() -> Bool {
		if self == false {
			return true
		}
		return false
	}
}

#if DEBUG
// MARK: Static UUID
extension UUID {
	public static let deadbeef = UUID.init(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFBEEFDEAD")!
}
#endif
