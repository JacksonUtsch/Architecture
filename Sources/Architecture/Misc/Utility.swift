//
//  Utility.swift
//  Architecture
//
//  Created by Jackson Utsch on 3/12/21.
//

import Foundation
import SwiftUI

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

// MARK: Optional Binding
public func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
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

// MARK: Frame Shorthand
public extension View {
    func width(_ value: CGFloat) -> some View {
        self
            .frame(width: value)
    }
    
    func height(_ value: CGFloat) -> some View {
        self
            .frame(height: value)
    }
}

// MARK: CGSize
public extension CGSize {
    var short: CGFloat {
        return Swift.min(self.width, self.height)
    }
    
    var long: CGFloat {
        return Swift.max(self.width, self.height)
    }
}

// MARK: Constructor Enum
public enum Constructor {
    case empty
    case `default`
    case preview
}

// MARK: Color hex
extension Color {
    public init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

// MARK: setMap
extension Set {
  func setMap<U>(transform: (Element) -> U) -> Set<U> {
    return Set<U>(self.lazy.map(transform))
  }
}
