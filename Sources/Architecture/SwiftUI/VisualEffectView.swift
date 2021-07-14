//
//  VisualEffectView.swift
//  Architecture
//
//  Created by Jackson Utsch on 7/14/21.
//

import SwiftUI

#if os(macOS)
// MARK: VisualEffectView
public struct VisualEffectView: NSViewRepresentable {
	public func makeNSView(context: NSViewRepresentableContext<Self>) -> NSVisualEffectView { NSVisualEffectView() }
	public func updateNSView(_ nsView: NSVisualEffectView, context: NSViewRepresentableContext<Self>) { nsView.blendingMode = .behindWindow }
	public init() { }
}
#endif
