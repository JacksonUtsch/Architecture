//
//  SwiftUI.swift
//  Architecture
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
  
  static public func hex(_ value: UInt, alpha: Double = 1) -> Color {
    Self.init(hex: value, alpha: alpha)
  }
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

#if os(macOS)
// MARK: VisualEffectView
public struct VisualEffectView: NSViewRepresentable {
  public func makeNSView(context: NSViewRepresentableContext<Self>) -> NSVisualEffectView { NSVisualEffectView() }
  public func updateNSView(_ nsView: NSVisualEffectView, context: NSViewRepresentableContext<Self>) { nsView.blendingMode = .behindWindow }
  public init() { }
}
#endif

// MARK: RoundedBox
public struct RoundedBox: Shape {
  var tl: CGFloat = 0.0
  var tr: CGFloat = 0.0
  var bl: CGFloat = 0.0
  var br: CGFloat = 0.0
  
  public init(
    tl: CGFloat = 0.0,
    tr: CGFloat = 0.0,
    bl: CGFloat = 0.0,
    br: CGFloat = 0.0
  ) {
    self.tl = tl
    self.tr = tr
    self.bl = bl
    self.br = br
  }
  
  public func path(in rect: CGRect) -> Path {
    var path = Path()
    let w: CGFloat = rect.width
    let h: CGFloat = rect.height
    
    // Make sure we do not exceed the size of the rectangle
    let tr = min(min(self.tr, h/2), w/2)
    let tl = min(min(self.tl, h/2), w/2)
    let bl = min(min(self.bl, h/2), w/2)
    let br = min(min(self.br, h/2), w/2)
    
    path.move(to: CGPoint(x: 0, y: 0))
    path.addLine(to: CGPoint(x: w - tr, y: 0))
    path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
    path.addLine(to: CGPoint(x: w, y: h - br))
    path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
    path.addLine(to: CGPoint(x: bl, y: h))
    path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
    path.addLine(to: CGPoint(x: 0, y: tl))
    path.addArc(center: CGPoint(x: tl, y: tl), radius: tl, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
    return Path(path.cgPath)
  }
}

extension View {
  public func debug(_ action: (() -> ())) -> some View {
    action()
    return self
  }
}
