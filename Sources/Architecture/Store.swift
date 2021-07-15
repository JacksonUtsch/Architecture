//
//  Store.swift
//  Architecture
//
//  Created by Jackson Utsch on 3/12/21.
//

import Foundation
import SwiftUI
import Combine

// MARK: Store
@available(iOS 13, macOS 10.15, *)
public class Store<State: Equatable, Action, Environment>: ObservableObject {
  @UniquePublished public internal(set) var state: State
	internal let environment: Environment
	internal let reducer: (inout State, Action, Environment) -> AnyPublisher<Action, Never>
  private var cancellables: [AnyCancellable] = []
  
  public init(
    initialState: State,
    reducer: @escaping (inout State, Action, Environment) -> AnyPublisher<Action, Never>,
    environment: Environment
  ) {
    self.state = initialState
    self.reducer = reducer
    self.environment = environment
		defaultDebug()
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
	) -> Store<State, Action, Environment> {
		Store<State, Action, Environment>.init(
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
	
	#if DEBUG
	private var onAction: ((Action) -> ())?
	private var onStateChange: ((State, State) -> ())?
	
	public func defaultDebug() {
		onAction = { print(String(describing: $0)) }
		onStateChange = {
			if let diff = readableDiff($0, $1) {
				print(diff)
			}
		}
	}
	
	/// Establish debugging preferences here
	/// - note: Can use readableDiff(...) for utility
	public func overrwriteDebug(
		actions: @escaping (Action) -> (),
		stateChanges: @escaping (State, State) -> ()
	) {
		self.onAction = actions
		self.onStateChange = stateChanges
	}
	#endif
	
  public func send(_ action: Action) {
    let tempState = state
		let effect = reducer(&state, action, environment)
		
		effect
			.sink { [weak self] result in
				self?.send(result)
			}.store(in: &cancellables)
		
		#if DEBUG
		onAction?(action)
		onStateChange?(tempState, state)
		#endif
  }
}

// MARK: Observe
extension Store {
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
extension Store {
  /// Derived store that observes and sends changes to its parent
  public func derived<LocalState, LocalAction, LocalEnvironment>(
    state toLocalState: @escaping (State) -> LocalState,
    action fromLocalAction: @escaping (LocalAction) -> Action,
    env toLocalEnvironment: @escaping (Environment) -> LocalEnvironment
  ) -> Store<LocalState, LocalAction, LocalEnvironment> {
		var isSendingUp = false
    let localStore = Store<LocalState, LocalAction, LocalEnvironment>(
      initialState: toLocalState(self.state),
      reducer: { localState, localAction, localEnvironment in
				defer { isSendingUp = false }
				isSendingUp = true
				self.send(fromLocalAction(localAction))
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
	) -> Store<LocalState, Never, Void> {
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
		set: @escaping (LocalState) -> Action) -> Store<LocalState, LocalState, Void> {
		return derived(state: get, action: set, env: { _ in })
	}
}

// MARK: Binding
extension Store {
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
            self.send(localState(newLocalState))
          }
        } else {
          self.send(localState(newLocalState))
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
public typealias StoreBinding<S: Equatable> = Store<S, S, Void>

extension StoreBinding {
  public convenience init(constant: State) {
    self.init(
      initialState: constant,
			reducer: { _,_,_ in .none },
      environment: () as! Environment
    )
  }
}
