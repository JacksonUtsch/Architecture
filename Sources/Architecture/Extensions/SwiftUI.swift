//
//  SwiftUI.swift
//  Architecture
//
//  Created by Jackson Utsch on 5/6/21.
//

import SwiftUI

// MARK: Debug
extension View {
	public func debug(_ action: (() -> ())) -> some View {
		action()
		return self
	}
}

// MARK: Frame Shorthands
extension View {
	public func width(_ value: CGFloat) -> some View { self.frame(width: value) }
	
	public func height(_ value: CGFloat) -> some View { self.frame(height: value) }
	
	public func minWidth(_ value: CGFloat) -> some View { self.frame(minWidth: value) }
	
	public func minHeight(_ value: CGFloat) -> some View { self.frame(minHeight: value) }
}

// MARK: Hex support
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
	
	static public func hex(_ value: UInt, alpha: Double = 1) -> Color {
		Self.init(hex: value, alpha: alpha)
	}
}

// MARK: Optional Binding
public func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
  Binding(
    get: { lhs.wrappedValue ?? rhs },
    set: { lhs.wrappedValue = $0 }
  )
}

// MARK: GeometryBinding
public extension View {
  /**
   Bind any `CGFloat` value within a `GeometryProxy` value
   to an external binding.
   */
  func bindGeometry(
    to binding: Binding<CGRect>,
    reader: @escaping (GeometryProxy) -> CGRect) -> some View {
    self.background(GeometryBinding(reader: reader))
      .onPreferenceChange(GeometryPreference.self) {
        binding.wrappedValue = $0
    }
  }
}

public struct GeometryBinding: View {
  let reader: (GeometryProxy) -> CGRect
  public var body: some View {
    GeometryReader { geo in
      Color.clear.preference(
        key: GeometryPreference.self,
        value: self.reader(geo)
      )
    }
  }
}

public struct GeometryPreference: PreferenceKey {
  public typealias Value = CGRect
  public static var defaultValue: CGRect = .zero
  public static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    let nValue = nextValue()
    if value.width * value.height <= nValue.width * nValue.height {
      value = nValue
    }
  }
}
