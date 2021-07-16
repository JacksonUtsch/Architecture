//
//  TestStore.swift
//  Architecture
//
//  Created by Jackson Utsch on 7/14/21.
//

#if DEBUG
import Foundation
import SwiftUI
import Combine
import XCTestDynamicOverlay

public final class TestStore<State: Equatable, Action, Environment>: ObservableObject {
	@UniquePublished public internal(set) var state: State
	internal let environment: Environment
	internal let reducer: (inout State, Action, Environment) -> AnyPublisher<Action, Never>
	private var cancellables: Set<AnyCancellable> = []
	
	/// the amount of accepted effects to exist on deinit
	public var effectTolerance: Int = 0
	var effects: [TrackableEffect: AnyCancellable] = [:]
	
	public init(
		initialState: State,
		reducer: @escaping (inout State, Action, Environment) -> AnyPublisher<Action, Never>,
		environment: Environment
	) {
		self.state = initialState
		self.reducer = reducer
		self.environment = environment
	}
	
	private convenience init?(
		initialState: State?,
		reducer: @escaping (inout State, Action, Environment) -> AnyPublisher<Action, Never>,
		environment: Environment
	) {
		guard let initialState = initialState else { return nil }
		self.init(initialState: initialState, reducer: reducer, environment: environment)
	}
	
	/// Error-erased store with callbacks for handling
	public static func erasedErrors(
		initialState: State,
		reducer: @escaping (inout State, Action, Environment) -> AnyPublisher<Action, Error>,
		environment: Environment,
		onErr: ((Error) -> ())? = nil
	) -> TestStore<State, Action, Environment> {
		TestStore<State, Action, Environment>.init(
			initialState: initialState,
			reducer: { s, a, e in
				return reducer(&s, a, e)
					.catch { (err: Error) -> Empty<Action, Never> in
						onErr?(err); return .init()
					}.eraseToAnyPublisher()
			},
			environment: environment
		)
	}

	deinit {
		if effects.count > effectTolerance {
			XCTFail(
				"""
				\(effectTolerance - effects.count) effects must be accounted for \
				to pass the effect tolerance of \(effectTolerance)
				
				Unhandled actions: \(debugOutput(effects))
				"""
			)
		}
	}
	
//	enum Order {
//		case send(Action)
//		case recieve(Action)
//	}
		
	struct TrackableEffect: Hashable {
		let id = UUID()
		let file: StaticString
		let line: UInt
		
		static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.id == rhs.id
		}

		func hash(into hasher: inout Hasher) {
			self.id.hash(into: &hasher)
		}
	}
	
	@discardableResult
	public func assert(
		_ action: Action,
		file: StaticString = #file,
		line: UInt = #line,
		stateChanges: ((_ original: inout State) -> ()) = { _ in }
	) -> Self {
		if effects.count > effectTolerance {
			XCTFail(
				"""
				\(effectTolerance - effects.count) effects must be accounted for \
				to pass the effect tolerance of \(effectTolerance)
				
				Unhandled actions: \(debugOutput(effects))
				""",
				file: file,
				line: line
			)
		}
		// bufferedAction logic?
		
		var expectation = state
		stateChanges(&expectation)
		var didComplete = false
		let id = TrackableEffect.init(file: file, line: line)
		let effect = self.reducer(&state, action, environment)
		let effectCancellable = effect.sink(
			receiveCompletion: { [weak self] _ in
				didComplete = true
				self?.effects[id] = nil
			},
			receiveValue: { [weak self] action in
				self?.assert(action)
			}
		)
		
		if !didComplete {
			self.effects[id] = effectCancellable
		}
		
		assertEqual(expected: expectation, actual: state)
		
		return self
	}
	
//	public func recieve(
//		_ action: Action,
//		file: StaticString = #file,
//		line: UInt8 = #line
//	) {
//		
//	}
	
	// MARK: Derived
	/// Derived store that observes and sends changes to its parent
	public func derived<LocalState, LocalAction, LocalEnvironment>(
		state toLocalState: @escaping (State) -> LocalState,
		action fromLocalAction: @escaping (LocalAction) -> Action,
		env toLocalEnvironment: @escaping (Environment) -> LocalEnvironment
	) -> TestStore<LocalState, LocalAction, LocalEnvironment> {
		var isSendingUp = false
		let localStore = TestStore<LocalState, LocalAction, LocalEnvironment>(
			initialState: toLocalState(self.state),
			reducer: { localState, localAction, localEnvironment in
				defer { isSendingUp = false }
				isSendingUp = true
				self.assert(fromLocalAction(localAction))
				localState = toLocalState(self.state)
				return .none
			}, environment: toLocalEnvironment(environment)
		)
		self.$state
			.sink { [weak localStore] newState in
				guard !isSendingUp else { return }
				localStore?.state = toLocalState(newState)
			}.store(in: &cancellables)
		return localStore
	}

	/// Derived store that only listsens to state
	public func derived<LocalState>(
		state toLocalState: @escaping (State) -> LocalState
	) -> TestStore<LocalState, Never, Void> {
		return derived(
			state: toLocalState,
			action: { $0 },
			env: { _ in }
		)
	}

	/// Derived store that gets and sets local state
	/// - note: Resulting type is know as a StoreBinding
	public func derived<LocalState: Equatable>(
		get: @escaping (State) -> LocalState,
		set: @escaping (LocalState) -> Action) -> TestStore<LocalState, LocalState, Void> {
		return derived(state: get, action: set, env: { _ in })
	}
}

// MARK: Binding
extension TestStore {
	/// SwiftUI Binding with action
	@available(iOS 14, macOS 11.0, *)
	public func binding<LocalState>(
		get: @escaping (State) -> LocalState,
		send localState: @escaping (LocalState) -> Action
	) -> Binding<LocalState> {
		let binding = Binding(
			get: { get(self.state) },
			set: { newLocalState, transaction in
				if transaction.animation != nil {
					withTransaction(transaction) {
						self.assert(localState(newLocalState))
					}
				} else {
					self.assert(localState(newLocalState))
				}
			}
		)
		return binding
	}
	
	/// SwiftUI Binding with callback
	@available(iOS 14, macOS 11.0, *)
	public func binding<LocalState>(
		get: @escaping (State) -> LocalState,
		callback: @escaping (LocalState) -> ()
	) -> Binding<LocalState> {
		Binding(
			get: { get(self.state) },
			set: { newLocalState in
				callback(newLocalState)
			}
		)
	}
}

// MARK: StoreBinding
public typealias TestStoreBinding<S: Equatable> = TestStore<S, S, Void>

extension TestStoreBinding {
	public convenience init(constant: State) {
		self.init(
			initialState: constant,
			reducer: { _,_,_ in .none },
			environment: () as! Environment
		)
	}
}

// MARK: AssertEqual
public func assertEqual<T: Equatable>(
	expected: T,
	actual: T
) {
	if expected != actual {
		let diff =
			readableDiff(expected, actual)
			.map { "\($0.indent(by: 2))\n\n(Expected: −, Actual: +)" }
			?? """
						Expected:
						\(String(describing: expected).indent(by: 2))
						Actual:
						\(String(describing: actual).indent(by: 2))
						"""
		
		XCTFail(
			"""
						State change does not match expectation: …
						\(diff)
						"""
		)
	}
}
#endif
