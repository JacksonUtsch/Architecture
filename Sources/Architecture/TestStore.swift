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

/// TestStores should be constructed in the scope of a singular test so they can deinit
public final class TestStore<State: Equatable, Action: Equatable, Environment>: ObservableObject {
	@UniquePublished public internal(set) var state: State
	internal let environment: Environment
	internal let reducer: (inout State, Action, Environment) -> AnyPublisher<Action, Never>
	private var cancellables: Set<AnyCancellable> = []
	
	/// The amount of accepted effects to exist on deinit
	/// - note: Use to skip exhaustively testing effects, not ideal usage
	public var effectTolerance: Int = 0
	internal var inFlightEffects: [TrackableEffect: AnyCancellable] = [:]
	internal var recievedEffects: [(action: Action, state: State)] = []
	internal var snapshotState: State
	
	private let file: StaticString
	private var line: UInt
	
	// MARK: Initializers
	public init(
		initialState: State,
		reducer: @escaping (inout State, Action, Environment) -> AnyPublisher<Action, Never>,
		environment: Environment,
		file: StaticString = #file,
		line: UInt = #line
	) {
		self.state = initialState
		self.reducer = reducer
		self.environment = environment
		self.file = file
		self.line = line
		self.snapshotState = initialState
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
		// accounts for recieved actions
		if recievedEffects.count > effectTolerance {
			XCTFail(
				"""
				The store received \(self.recievedEffects.count) unexpected \
				action\(self.recievedEffects.count == 1 ? "" : "s") after this one: …
				
				Unhandled actions: \(debugOutput(self.recievedEffects.map { $0.0 }))
				"""
			)
		}
		
		// accounts for in-flight actions
		if inFlightEffects.count > effectTolerance {
			XCTFail(
				"""
				An effect returned for this action is still running. It must complete before the end of \
				the test. …
				
				\(inFlightEffects.count - effectTolerance) effect\(inFlightEffects.count - effectTolerance == 1 ? "" : "s") must be accounted for \
				to pass the effect tolerance of \(effectTolerance)
				""",
				file: file,
				line: line
			)
		}
	}
	
	// MARK: Assert
	@discardableResult
	public func assert(
		_ action: Action,
		file: StaticString = #file,
		line: UInt = #line,
		mutates expectedMutation: ((_ original: inout State) -> ()) = { _ in }
	) -> Self {
		if recievedEffects.count > effectTolerance {
			XCTFail(
				"""
				\(recievedEffects.count - effectTolerance) effect\(inFlightEffects.count - effectTolerance == 1 ? "" : "s") must be accounted for \
				to pass the effect tolerance of \(effectTolerance)
				
				Unhandled actions: \(debugOutput(recievedEffects))
				""",
				file: file,
				line: line
			)
		}
		
		var expectation = state
		expectedMutation(&expectation)
		var didComplete = false
		let id = TrackableEffect.init(initialAction: action, file: file, line: line)
		let effect = reducer(&state, action, environment)
		snapshotState = state
		
		func recieveAction(_ action: Action) {
			let actionEffect = reducer(&state, action, environment)
			recievedEffects.append((action, state))
			actionEffect.sink { action in
				recieveAction(action)
			}.store(in: &cancellables)
		}
		
		let effectCancellable = effect.sink(
			receiveCompletion: { [weak self] _ in
				didComplete = true
				self?.inFlightEffects[id] = nil
			},
			receiveValue: { action in
				recieveAction(action)
			}
		)
		
		if !didComplete {
			self.inFlightEffects[id] = effectCancellable
		}
		
		assertEqual(expected: expectation, actual: state)
		
		if "\(self.file)" == "\(file)" {
			self.line = line
		}
		
		return self
	}
	
	// MARK: AssertReceived
	public func assertReceived(
		_ action: Action,
		file: StaticString = #file,
		line: UInt = #line,
		mutated expectedMutation: ((_ original: inout State) -> ()) = { _ in }
	) {
		guard let effect = recievedEffects.first else {
			XCTFail(
				"""
				Expected to receive an action, but received none.
				""",
				file: file,
				line: line
			)
			return
		}
		
		if effect.action != action {
			let diff =
				readableDiff(action, effect.0)
				.map { "\($0.indent(by: 4))\n\n(Expected: −, Received: +)" }
				?? """
				Expected:
				\(String(describing: action).indent(by: 2))
				
				Received:
				\(String(describing: effect.0).indent(by: 2))
				"""
			
			XCTFail(
				"""
				Received unexpected action: …
				
				\(diff)
				""",
				file: file,
				line: line
			)
			return
		}
		expectedMutation(&snapshotState)
		assertEqual(expected: snapshotState, actual: state)
		
		recievedEffects.removeFirst()
	}
	
	struct TrackableEffect: Hashable {
		let initialAction: Action
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
	
	/// Callback for derived state changes equated on state changes and declaration
	public func observe<LocalState: Equatable>(
		_ get: @escaping (State) -> LocalState,
		onChange callback: @escaping (LocalState) -> ()
	) {
		$state
			.map { get($0) }
			.removeDuplicates(by: { $0 == $1 })
			.sink { callback($0) }
			.store(in: &cancellables)
	}
}

// MARK: Derived
//extension TestStore {
//	/// Derived store that observes and sends changes to its parent
//	/// - Note: Non-functioning due to assert logic
//	public func derived<LocalState, LocalAction, LocalEnvironment>(
//		state toLocalState: @escaping (State) -> LocalState,
//		action fromLocalAction: @escaping (LocalAction) -> Action,
//		env toLocalEnvironment: @escaping (Environment) -> LocalEnvironment
//	) -> TestStore<LocalState, LocalAction, LocalEnvironment> {
//		var isSendingUp = false
//		let localStore = TestStore<LocalState, LocalAction, LocalEnvironment>(
//			initialState: toLocalState(self.state),
//			reducer: { localState, localAction, localEnvironment in
//				defer { isSendingUp = false }
//				isSendingUp = true
//				self.assert(fromLocalAction(localAction))
//				localState = toLocalState(self.state)
//				return .none
//			}, environment: toLocalEnvironment(environment)
//		)
//		self.$state
//			.sink { [weak localStore] newState in
//				guard !isSendingUp else { return }
//				localStore?.state = toLocalState(newState)
//			}.store(in: &cancellables)
//		return localStore
//	}
//
//	/// Derived store that only listsens to state
//	public func derived<LocalState>(
//		state toLocalState: @escaping (State) -> LocalState
//	) -> TestStore<LocalState, Never, Void> {
//		return derived(
//			state: toLocalState,
//			action: { $0 },
//			env: { _ in }
//		)
//	}
//
//	/// Derived store that gets and sets local state
//	/// - note: Resulting type is know as a StoreBinding
//	public func derived<LocalState: Equatable>(
//		get: @escaping (State) -> LocalState,
//		set: @escaping (LocalState) -> Action) -> TestStore<LocalState, LocalState, Void> {
//		return derived(state: get, action: set, env: { _ in })
//	}
//}

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
