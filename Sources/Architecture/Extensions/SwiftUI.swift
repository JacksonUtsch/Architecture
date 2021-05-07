//
//  File.swift
//  
//
//  Created by Jackson Utsch on 5/6/21.
//

import SwiftUI

// MARK: Optional Binding
public func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
  Binding(
    get: { lhs.wrappedValue ?? rhs },
    set: { lhs.wrappedValue = $0 }
  )
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
