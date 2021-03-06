//
//  CancellationTest.swift
//  ArchitectureTests
//
//  Created by Jackson Utsch on 7/15/21.
//

import XCTest
import Combine
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
		let scheduler = DispatchQueue.test
		struct CanelID: Hashable { }
		enum LocalAction {
			case delayInc
			case inc
			case cancel
		}
		let store = Store<Int, LocalAction, AnySchedulerOf<DispatchQueue>>(
			initialState: 0,
			reducer: { s, a, e in
				switch a {
				case .delayInc:
					return Just(LocalAction.inc)
						.eraseToAnyPublisher()
						.defered(for: 5.0, on: e)
						.cancellable(id: CanelID())
				case .inc:
					s += 1
					return .none
				case .cancel:
						return .cancel(id: CanelID())
				}
			}, environment: scheduler.eraseToAnyScheduler()
		)
		
		store.send(.delayInc)
		store.send(.cancel)
		scheduler.advance(by: 5.0)
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
		let store = TestStore<Int, LocalAction, AnySchedulerOf<DispatchQueue>>(
			initialState: 0,
			reducer: { s, a, e in
				switch a {
				case .delayInc:
					return Just(LocalAction.inc)
						.eraseToAnyPublisher()
						.defered(for: 5.0, on: e)
						.cancellable(id: CanelID())
				case .inc:
					s += 1
					return .none
				case .cancel:
						return .cancel(id: CanelID())
				}
			}, environment: sch.eraseToAnyScheduler()
		)
		store.assert(.inc, mutates: { $0 += 1 })
		store.assert(.delayInc)
		store.assert(.cancel)
		sch.advance(by: 5.0)
		XCTAssertEqual(store.state, 1)
		
		store.assert(.delayInc)
		sch.advance(by: 5.0)
		store.assertReceived(.inc, mutated: { $0 += 1 })
		XCTAssertEqual(store.state, 2)
	}
}
