//
//  ReduxTests.swift
//  Architecture
//
//  Created by Jackson Utsch on 5/18/21.
//

import XCTest
@testable import Architecture
import Combine
import CombineSchedulers

final class StoreTests: XCTestCase {
	let scheduler = DispatchQueue.test
	func testStateMutation() {
		let testStore = TestStore(
			initialState: ArchTestState(),
			reducer: testReducer,
			environment: scheduler.eraseToAnyScheduler()
		)
		
		testStore
			.assert(.add, mutates: { $0.number = 1 })
			.assert(.add, mutates: { $0.number = 2 })
			.assert(.subtract, mutates: { $0.number = 1 })
			.assert(.subtract, mutates: { $0.number = 0 })
	}
	
	/** - note:
	the effect does not instantly resolve
	*/
	func testEffect() {
		let testStore = TestStore(
			initialState: ArchTestState(),
			reducer: testReducer,
			environment: scheduler.eraseToAnyScheduler()
		)
				
		testStore.assert(.renameThenAdd/*ThenMinus*/, mutates: { $0.name = "custom name" })
		testStore.assert(.add, mutates: { $0.number += 1 })
		scheduler.advance()
		testStore.assertReceived(.add, mutated: { $0.number += 1 })
		XCTAssertEqual(testStore.state.number, 2)
	}
	
	/** - note:
	the observe closure is called on declaration, can get initial state
	*/
	func testObserve() {
		let testStore = TestStore(
			initialState: ArchTestState(),
			reducer: testReducer,
			environment: scheduler.eraseToAnyScheduler()
		)
		var observationCount = 0
		testStore.observe({ $0.number }) { _ in observationCount += 1 }
		testStore.assert(.add, mutates: { $0.number += 1 })
		testStore.assert(.add, mutates: { $0.number += 1 })
		testStore.assert(.add, mutates: { $0.number += 1 })
		XCTAssertEqual(observationCount, 4)
	}
	
//	func testScope() {
//		// a scoped store sends actions to the parent and doesn't resolve immediatly,
//		// hence the scheduler must advance before state assertion
//		let scopedStore = testStore.derived(
//			state: { $0.substate },
//			action: { ArchTestAction.subaction($0) },
//			env: { _ in }
//		)
//
//		scopedStore.send(.insert(Substate.IdentifiableInt(value: 5)))
//		StoreTests.scheduler.advance()
//		// scoped stores pipe actions to their parent causing a return
//		XCTAssertEqual(scopedStore.state.contents.collection.count, 2)
//		XCTAssertEqual(testStore.state.substate.contents.collection.count, 2)
//
//		// without being scoped, the changes can be asserted immediatly
//		let standaloneStore = SubstateStore(
//			initialState: Substate(contents: .init([], at: nil)),
//			reducer: substateReducer(state:action:env:),
//			environment: ()
//		)
//
////		standaloneStore.assert(
////			.insert(Substate.IdentifiableInt(value: 5)),
////			stateChanges: { $0.contents.collection[$0.contents.index!].value = 5 }
////		)
//	}
}

// MARK: Store
typealias ArchTestStore = Store<ArchTestState, ArchTestAction, Void>

// MARK: Reducer
func testReducer(state: inout ArchTestState, action: ArchTestAction, env: AnySchedulerOf<DispatchQueue>) -> AnyPublisher<ArchTestAction, Never> {
	switch action {
	case .add:
		state.number += 1
		return .none
	case .subtract:
		state.number -= 1
		return .none
	case .renameThenAdd:
		state.name = "custom name"
		return Just(ArchTestAction.add)
			.receive(on: env)
//			.delay(for: 2.0, scheduler: env)
			.eraseToAnyPublisher()
	case .subaction(let secondary):
		return substateReducer(state: &state.substate, action: secondary, env: ())
			.map(ArchTestAction.subaction)
			.eraseToAnyPublisher()
	}
}

// MARK: State
struct ArchTestState: Equatable {
	var number: Int = 0
	var name: String = "intial name"
	var substate: Substate = .init(
		contents: .init(
			[Substate.IdentifiableInt(value: 5)],
			at: 0
		)
	)
}

// MARK: Action
enum ArchTestAction: Equatable {
	case add
	case subtract
	case renameThenAdd
	case subaction(Subaction)
}

// MARK: SubstateStore
typealias SubstateStore = TestStore<Substate, Subaction, Void>

// MARK: Substate Reducer
func substateReducer(
	state: inout Substate,
	action: Subaction,
	env: Void
) -> AnyPublisher<Subaction, Never> {
	switch action {
	case .insert(let item):
		state.contents.new(item)
		return .none
	}
}

// MARK: Substate
struct Substate: Equatable {
	var contents: OpenArray<IdentifiableInt>
	
	struct IdentifiableInt: Equatable, Identifiable {
		let id = UUID()
		var value: Int
		
		static func == (lhs: IdentifiableInt, rhs: IdentifiableInt) -> Bool {
			return lhs.value == rhs.value
		}
	}
}

// MARK: Substate Action
enum Subaction: Equatable {
	case insert(Substate.IdentifiableInt)
}
