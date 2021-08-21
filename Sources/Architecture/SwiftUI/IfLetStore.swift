//
//  IfLetStore.swift
//  Architecture
//
//  Created by Jackson Utsch on 7/14/21.
//

import SwiftUI

public struct IfLetStore<State: Equatable, Action, Environment, Content>: View where Content: View {
	private let content: (Store<State?, Action, Environment>) -> Content
	@ObservedObject private var store: Store<State?, Action, Environment>
	
	/// Initializes an `IfLetStore` view that computes content depending on if a store of optional
	/// state is `nil` or non-`nil`.
	///
	/// - Parameters:
	///   - store: A store of optional state.
	///   - ifContent: A function that is given a store of non-optional state and returns a view that
	///     is visible only when the optional state is non-`nil`.
	///   - elseContent: A view that is only visible when the optional state is `nil`.
	public init<IfContent, ElseContent>(
		store: Store<State?, Action, Environment>,
		content ifContent: @escaping (Store<State, Action, Environment>) -> IfContent,
		elseContent: @escaping @autoclosure () -> ElseContent
	) where Content == _ConditionalContent<IfContent, ElseContent> {
		self.store = store
		self.content = { contentStore in
			if let state = contentStore.state {
				return ViewBuilder.buildEither(first: ifContent(store.derived(state: { $0 ?? state }, action: { $0 }, env: { $0 })))
			} else {
				return ViewBuilder.buildEither(second: elseContent())
			}
		}
	}
	
	/// Initializes an `IfLetStore` view that computes content depending on if a store of optional
	/// state is `nil` or non-`nil`.
	///
	/// - Parameters:
	///   - store: A store of optional state.
	///   - ifContent: A function that is given a store of non-optional state and returns a view that
	///     is visible only when the optional state is non-`nil`.
	/// - note : Default else content is EmptyView()
	public init<IfContent>(
		store: Store<State?, Action, Environment>,
		content ifContent: @escaping (Store<State, Action, Environment>) -> IfContent
	) where Content == _ConditionalContent<IfContent, EmptyView> {
		self.store = store
		self.content = { contentStore in
			if let state = contentStore.state {
				return ViewBuilder.buildEither(first: ifContent(store.derived(state: { $0 ?? state }, action: { $0 }, env: { $0 })))
			} else {
				return ViewBuilder.buildEither(second: EmptyView())
			}
		}
	}
	
	public var body: some View {
		content(self.store)
	}
}
