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
//extension Store {
//	@discardableResult
//	public func assert(
//		_ action: Action? = nil,
//		that expectation: @escaping (State) -> Bool
//	) -> Self {
//		if let action = action {
//			send(action)
//		}
//		if expectation(self.state) == false {
//			XCTFail()
//		}
//		return self
//	}
//}

//	public func assertEqual(
//		_ action: Action? = nil,
//		that expectation: @escaping (State) -> Bool
//	) -> Self {
//		assertEqual(expected: state, actual: state)
//		return self
//	}


#endif

