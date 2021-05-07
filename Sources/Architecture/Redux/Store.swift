//
//  Store.swift
//  Architecture
//
//  Created by Jackson Utsch on 3/12/21.
//

import Foundation
import SwiftUI
import Combine
import SwiftyBeaver
import CombineSchedulers

// MARK: Store
@available(iOS 13, macOS 10.15, *)
public class Store<State: Equatable, Action, Environment>: ObservableObject {
  @UniquePublished public private(set) var state: State
  private let environment: Environment
  private let reducer: (inout State, Action, Environment) -> AnyPublisher<Action, Never>?
  internal let scheduler: AnySchedulerOf<DispatchQueue>
  
  private var cancellables: [AnyCancellable] = []
  
  private var actionsDebug: Log.Level? = nil
  private var stateChangeDebug: Log.Level? = nil
  
  public init(
    initialState: State,
    reducer: @escaping (inout State, Action, Environment) -> AnyPublisher<Action, Never>?,
    environment: Environment,
    scheduler: AnySchedulerOf<DispatchQueue> = .main
  ) {
    self.state = initialState
    self.reducer = reducer
    self.environment = environment
    self.scheduler = scheduler
  }
  
  private convenience init?(
    initialState: State?,
    reducer: @escaping (inout State, Action, Environment) -> AnyPublisher<Action, Never>?,
    environment: Environment
  ) {
    guard let initialState = initialState else {
      return nil
    }
    self.init(initialState: initialState, reducer: reducer, environment: environment)
  }
  
  public func send(_ action: Action) {
    if let level = actionsDebug {
      DispatchQueue.global(qos: .utility).async {
        Log.custom(level: level, message: action)
      }
    }
    
    let tempState = state
    if let effect = reducer(&state, action, environment) {
      effect.receive(on: scheduler)
        .sink { [unowned self] result in
          self.send(result)
        }.store(in: &cancellables)
    }
    
    if let level = stateChangeDebug {
      DispatchQueue.global(qos: .utility).async { [unowned self] in
        let diff = dumpDiff(state, tempState).joined()
        if diff.count > 0 {
          Log.custom(level: level, message: "\n" + "\(self.self) \n" + diff + "\n")
        }
      }
    }
  }
  
  /// Establishes logging preferences
  public func debug(
    actions: Log.Level? = nil,
    stateChanges: Log.Level? = nil
  ) {
    self.actionsDebug = actions
    self.stateChangeDebug = stateChanges
  }
  
  /// Callback for local state on state changes including declaration
  public func observe<LocalState>(
    get: @escaping (State) -> LocalState,
    callback: @escaping (LocalState) -> ()
  ) {
    $state.map { get($0) }
      .sink { callback($0) }
      .store(in: &cancellables)
  }
}

// MARK: Substores
extension Store {
  /// Scoped store that observes and sends changes to the parent
  public func substore<LocalState, LocalAction, LocalEnvironment>(
    state toLocalState: @escaping (State) -> LocalState,
    action fromLocalAction: @escaping (LocalAction) -> Action,
    env toLocalEnvironment: @escaping (Environment) -> LocalEnvironment
  ) -> Store<LocalState, LocalAction, LocalEnvironment> {
    let localStore = Store<LocalState, LocalAction, LocalEnvironment>(
      initialState: toLocalState(self.state),
      reducer: { localState, localAction, localEnvironment in
        self.send(fromLocalAction(localAction))
        return nil
      }, environment: toLocalEnvironment(environment)
    )
    
    self.$state.receive(on: scheduler)
      .sink { [weak localStore] newState in
        localStore?.state = toLocalState(newState)
      }.store(in: &cancellables)
    return localStore
  }
  
  /**
   Scoped store that observes and sends changes to the parent
   
   Used for destructive components such as nested state
   */
  public func subscriptStore<LocalState, LocalAction, LocalEnvironment>(
    state toLocalState: @escaping (State) -> LocalState?,
    action fromLocalAction: @escaping (LocalAction) -> Action,
    env toLocalEnvironment: @escaping (Environment) -> LocalEnvironment
  ) -> Store<LocalState, LocalAction, LocalEnvironment>? {
    if let localStore = Store<LocalState, LocalAction, LocalEnvironment>(
        initialState: toLocalState(self.state),
        reducer: { localState, localAction, localEnvironment in
          self.send(fromLocalAction(localAction))
          return nil
        }, environment: toLocalEnvironment(environment)) {
      
      self.$state.receive(on: scheduler)
        .sink { [weak localStore] newState in
          if let newLocalState = toLocalState(newState) {
            localStore?.state = newLocalState
          }
        }.store(in: &cancellables)
      return localStore
    }
    return nil
  }
}

// MARK: Bindings
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

public typealias StoreBinding<S: Equatable> = Store<S, S, Void>

extension StoreBinding {
  public convenience init(constant: State) {
    self.init(initialState: constant, reducer: {_,_,_ in nil}, environment: () as! Environment)
  }
}

extension Store {
  public func storeBinding<LocalState: Equatable>(
    get: @escaping (State) -> LocalState,
    set: @escaping (LocalState) -> Action) -> StoreBinding<LocalState> {
    return substore(state: get, action: set, env: {_ in})
  }
}
