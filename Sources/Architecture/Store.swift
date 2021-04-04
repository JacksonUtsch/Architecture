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

// MARK: Store
@available(iOS 13, macOS 10.15, *)
public class Store<State, Action, Environment>: ObservableObject {
    @Published public private(set) var state: State
    private let environment: Environment
    private let reducer: (inout State, Action, Environment) -> AnyPublisher<Action, Never>?
    
    private var cancellables: [AnyCancellable] = []
    
    private var actionsDebug: Log.Level? = nil
    private var stateChangeDebug: Log.Level? = nil
    
    public init(
        initialState: State,
        reducer: @escaping (inout State, Action, Environment) -> AnyPublisher<Action, Never>?,
        environment: Environment
    ) {
        self.state = initialState
        self.reducer = reducer
        self.environment = environment
    }
    
    public func send(_ action: Action) {
        if let level = actionsDebug {
            DispatchQueue.global(qos: .utility).async {
                Log.custom(level: level, message: action)
            }
        }
        
        let tempState = state
        if let effect = reducer(&state, action, environment) {
            effect.receive(on: DispatchQueue.main)
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
    
    /// establish logging preferences
    public func debug(actions: Log.Level? = nil, stateChanges: Log.Level? = nil) {
        self.actionsDebug = actions
        self.stateChangeDebug = stateChanges
    }
    
    /// state binding with action
    @available(iOS 14, macOS 11.0, *)
    public func binding<LocalState>(
        get: @escaping (State) -> LocalState,
        send localState: @escaping (LocalState) -> Action
        ) -> Binding<LocalState> {
        Binding(
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
    }
    
    /// state binding with callback
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
    
    /// callback for local state on state changes including declaration
    public func observe<LocalState>(
        get: @escaping (State) -> LocalState,
        callback: @escaping (LocalState) -> ()
    ) {
        $state.map { get($0) }
            .sink { callback($0) }
            .store(in: &cancellables)
    }
    
    /// scoped store that observes and sends changes to the parent
    public func scope<LocalState, LocalAction, LocalEnvironment>(
        localEnvironment: LocalEnvironment,
        toLocalState: @escaping (State) -> LocalState?,
        fromLocalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalState, LocalAction, LocalEnvironment> {
        let localStore = Store<LocalState, LocalAction, LocalEnvironment>(
            initialState: toLocalState(self.state)!,
            reducer: { localState, localAction, localEnvironment in
                self.send(fromLocalAction(localAction))
                return nil
            }, environment: localEnvironment)
        
        self.$state.receive(on: DispatchQueue.main)
            .sink { [weak localStore] newState in
                if let newLocalState = toLocalState(newState) {
                    localStore?.state = newLocalState
                }
            }.store(in: &cancellables)
        return localStore
    }
}

public struct EmptyEnvironment {
    public init() { }
}
