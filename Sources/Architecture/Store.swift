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
    
    public let objectWillChange = ObservableObjectPublisher()
    private var cancellables: [AnyCancellable] = []
    
    public var debug: Debug = .none
    
    public init(
        initialState: State,
        reducer: @escaping (inout State, Action, Environment) -> AnyPublisher<Action, Never>?,
        environment: Environment
    ) {
        self.state = initialState
        self.reducer = reducer
        self.environment = environment
    }
    
    public func send(_ action: Action, muted: Bool = false) {
        let tempState = state
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
        
        if case let .some(level) = debug {
            Log.custom(level: level, message: "\n" + "\(self.self) \n" + dumpDiff(state, tempState).joined() + "\n")
        }
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
    
//    public func scope<LocalState, LocalAction, LocalEnvironment>(
//        localEnvironment: LocalEnvironment,
//        toLocalState: @escaping (State) -> LocalState,
//        fromLocalAction: @escaping (LocalAction) -> Action
//    ) -> Store<LocalState, LocalAction, LocalEnvironment> {
//        let localStore = Store<LocalState, LocalAction, LocalEnvironment>(
//            initialState: toLocalState(self.state),
//            reducer: { localState, localAction, localEnvironment in
//                self.send(fromLocalAction(localAction))
//                localState = toLocalState(self.state)
//                return nil
//            }, environment: localEnvironment)
//        self.objectWillChange.receive(on: DispatchQueue.main)
//            .sink { [weak localStore, weak self] _ in
//                if self != nil {
//                    localStore?.state = toLocalState(self!.state)
//                }
//            }.store(in: &cancellables)
//        return localStore
//    }
    
    /// scoped store that observes the parent and send changes
    public func scope<LocalState, LocalAction, LocalEnvironment>(
        localEnvironment: LocalEnvironment,
        toLocalState: @escaping (State) -> LocalState?,
        fromLocalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalState, LocalAction, LocalEnvironment> {
        let localStore = Store<LocalState, LocalAction, LocalEnvironment>(
            initialState: toLocalState(self.state)!,
            reducer: { localState, localAction, localEnvironment in
                self.send(fromLocalAction(localAction))
                if let newLocalState = toLocalState(self.state) {
                    localState = newLocalState
                }
                return nil
            }, environment: localEnvironment)
        
        self.objectWillChange.receive(on: DispatchQueue.main)
            .sink { [weak localStore, weak self] _ in
                if self != nil {
                    if let newLocalState = toLocalState(self!.state) {
                        localStore?.state = newLocalState
                    }
                }
            }.store(in: &cancellables)
        return localStore
    }
}

// MARK: Types
extension Store {
    public enum Debug {
        case none
        case some(SwiftyBeaver.Level)
    }
}
