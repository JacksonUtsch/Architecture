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
	public func makeNSView(context: NSViewRepresentableContext<Self>) -> NSVisualEffectView {
		let view = NSVisualEffectView()
		view.blendingMode = .behindWindow
		return view
	}
	public func updateNSView(_ nsView: NSVisualEffectView, context: NSViewRepresentableContext<Self>) { }
	public init() { }
}
#endif
