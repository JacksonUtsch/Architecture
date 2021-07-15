//
//  KeyboardObserver.swift
//  Architecture
//
//  Created by Jackson Utsch on 7/14/21.
//

import SwiftUI
import Combine

#if os(iOS)
// MARK: KeyboardObserver
public class KeyboardObserver: ObservableObject {
	@Published public private(set) var keyboardHeight: CGFloat = 0
	private var cancellable: AnyCancellable?
	
	let keyboardWillShow = NotificationCenter.default
		.publisher(for: UIResponder.keyboardWillShowNotification)
		.compactMap { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height }
	
	let keyboardWillHide = NotificationCenter.default
		.publisher(for: UIResponder.keyboardWillHideNotification)
		.map { _ -> CGFloat in 0 }
	
	public init() {
		cancellable = Publishers.Merge(keyboardWillShow, keyboardWillHide)
			.subscribe(on: RunLoop.main)
			.assign(to: \.keyboardHeight, on: self)
	}
	
	public func endEditing() {
		UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
	}
}
#endif
