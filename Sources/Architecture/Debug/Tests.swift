//
//  Tests.swift
//  Architecture
//
//  Created by Jackson Utsch on 3/21/21.
//

import Foundation
import XCTestDynamicOverlay
import CombineSchedulers
import Combine

#if DEBUG
// MARK: Assert
extension Store {
  @discardableResult
  public func assert(
    _ action: Action? = nil,
    that expectation: @escaping (State) -> Bool,
    with delay: DispatchQueue.SchedulerTimeType.Stride? = nil
  ) -> Self {
    if let action = action {
      send(action)
    }
    guard let delay = delay else {
      if expectation(self.state) == false { XCTFail() }
      return self
    }
    scheduler.schedule(after: scheduler.now.advanced(by: delay)) {
      if expectation(self.state) == false {
        XCTFail()
      }
    }
    return self
  }
  
  /// Debug only store for testing reducers with errors
  public static func erasedErrors(
    initialState: State,
    reducer: @escaping (inout State, Action, Environment) -> AnyPublisher<Action, Error>,
    environment: Environment,
    scheduler: AnySchedulerOf<DispatchQueue> = .main,
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
      environment: environment,
      scheduler: scheduler
    )
  }
}
#endif
