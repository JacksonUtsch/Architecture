//
//  CancellationTest.swift
//  Architecture
//
//  Created by Jackson Utsch on 7/15/21.
//

import Combine
import XCTest
import CombineSchedulers

@testable import Architecture

final class CancellationTest: XCTestCase {
	struct CancelToken: Hashable {}
	var cancellables: Set<AnyCancellable> = []
	
	func testCancellation() {
		var values: [Int] = []
		
		let subject = PassthroughSubject<Int, Never>()
		let effect = subject
			.eraseToAnyPublisher()
			.cancellable(id: CancelToken())
		
		effect
			.sink { values.append($0) }
			.store(in: &self.cancellables)
		
		XCTAssertEqual(values, [])
		subject.send(1)
		XCTAssertEqual(values, [1])
		subject.send(2)
		XCTAssertEqual(values, [1, 2])
		
		AnyPublisher<Void, Never>
			.cancel(id: CancelToken())
			.sink { _ in }
			.store(in: &cancellables)
		
		subject.send(3)
		XCTAssertEqual(values, [1, 2])
	}
	
	func testCancellationFromStore() {
		let sch = DispatchQueue.test
		struct CanelID: Hashable { }
		enum LocalAction {
			case delayInc
			case inc
			case cancel
		}
		let store = Store<Int, LocalAction, Void>(
			initialState: 0,
			reducer: { s, a, _ in
				switch a {
				case .delayInc:
					return .just(value: LocalAction.inc)
						.defered(for: 5.0, on: sch)
						.cancellable(id: CanelID())
				case .inc:
					s += 1
					return .none
				case .cancel:
						return .cancel(id: CanelID())
				}
			}, environment: ()
		)
		
		store.send(.delayInc)
		store.send(.cancel)
		sch.advance(by: 5.0)
		XCTAssertEqual(store.state, 0)
	}
	
	func testCancellationFromTestStore() {
		let sch = DispatchQueue.test
		struct CanelID: Hashable { }
		enum LocalAction {
			case delayInc
			case inc
			case cancel
		}
		let store = TestStore<Int, LocalAction, Void>(
			initialState: 0,
			reducer: { s, a, _ in
				switch a {
				case .delayInc:
					return .just(value: LocalAction.inc)
						.defered(for: 5.0, on: sch)
						.cancellable(id: CanelID())
				case .inc:
					s += 1
					return .none
				case .cancel:
						return .cancel(id: CanelID())
				}
			}, environment: ()
		)
		store.assert(.inc, stateChanges: { $0 + 1 })
		
		store.assert(.delayInc)
		store.assert(.cancel)
		store.assert(.cancel)
		sch.advance(by: 5.0)
		XCTAssertEqual(store.state, 1)
	}
}
