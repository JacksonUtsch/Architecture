//
//  Utility.swift
//  
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

// MARK: Optional Collection Subscripting
extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
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
