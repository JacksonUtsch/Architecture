//
//  Tests.swift
//  Architecture
//
//  Created by Jackson Utsch on 3/21/21.
//

import Foundation
import CombineSchedulers
import Combine

#if DEBUG
import XCTestDynamicOverlay
// MARK: Assert
extension Store {
  @discardableResult
  public func assert(
    _ action: Action? = nil,
    that expectation: @escaping (State) -> Bool
  ) -> Self {
    if let action = action {
      send(action)
    }
		if expectation(self.state) == false {
			XCTFail()
		}
    return self
  }
}

//	public func assertEqual(
//		_ action: Action? = nil,
//		that expectation: @escaping (State) -> Bool
//	) -> Self {
//		assertEqual(expected: state, actual: state)
//		return self
//	}

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

