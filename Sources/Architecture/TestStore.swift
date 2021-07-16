//
//  TestStore.swift
//  Architecture
//
//  Created by Jackson Utsch on 7/14/21.
//

#if DEBUG
import Foundation
import Combine
import XCTestDynamicOverlay

public final class TestStore<State: Equatable, Action, Environment>: Store<State, Action, Environment> {
	//	var effects: [Action: AnyCancellable] = [:]
	
	deinit {
		// assert effects have been accounted for, need to decide how to manage long living effects..
	}
	
	public func assert(
		_ action: Action,
		that expectation: @escaping (State) -> Bool,
		file: StaticString = #file,
		line: UInt8 = #line
	) {
		let startingState = state
		let effect = reducer(&state, action, environment)
		
		if state != expectation(startingState) as! State {
			XCTFail()
		}
	}
	
	public func recieve(
		_ action: Action,
		file: StaticString = #file,
		line: UInt8 = #line
	) {
		
	}
}
#endif
