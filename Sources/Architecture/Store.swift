import Foundation
import SwiftUI
import Combine

// MARK: Store
class Store<State, Action, Environment>: ObservableObject {
    private(set) var state: State { didSet { if debug { print(state) } } }
    private let environment: Environment
    private let reducer: (inout State, Action, Environment) -> AnyPublisher<Action, Never>?
    private let debug: Bool
    
    let objectWillChange = ObservableObjectPublisher()
    
    private var cancellables: [AnyCancellable] = []
    
    init(
        initialState: State,
        reducer: @escaping (inout State, Action, Environment) -> AnyPublisher<Action, Never>?,
        environment: Environment,
        debug: Bool = false
    ) {
        self.state = initialState
        self.reducer = reducer
        self.environment = environment
        self.debug = debug
    }
    
    func send(_ action: Action, muted: Bool = false) {
        if let effect = reducer(&state, action, environment) {
            effect.receive(on: DispatchQueue.main)
                .sink { [unowned self] result in
                    self.send(result)
                }.store(in: &cancellables)
        } else {
            if muted == false {
                objectWillChange.send()
            }
        }
    }
    
    func binding<LocalState>(
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
    
    public func scope<LocalState, LocalAction, LocalEnvironment>(
        localEnvironment: LocalEnvironment,
        toLocalState: @escaping (State) -> LocalState,
        fromLocalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalState, LocalAction, LocalEnvironment> {
        let localStore = Store<LocalState, LocalAction, LocalEnvironment>(
            initialState: toLocalState(self.state),
            reducer: { localState, localAction, localEnvironment in
                self.send(fromLocalAction(localAction))
                localState = toLocalState(self.state)
                return nil
            }, environment: localEnvironment)
        self.objectWillChange.receive(on: DispatchQueue.main)
            .sink { [weak localStore, weak self] _ in
                if self != nil {
                    localStore?.state = toLocalState(self!.state)
                }
            }.store(in: &cancellables)
        return localStore
    }
}
