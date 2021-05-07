//
//  Tests.swift
//  Architecture
//
//  Created by Jackson Utsch on 3/21/21.
//

import Foundation
import XCTestDynamicOverlay

#if DEBUG
// MARK: Assert
public extension Store {
  @discardableResult
  func assert(
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
}
#endif
