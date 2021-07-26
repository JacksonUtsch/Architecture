//
//  StoreTests.swift
//  ArchitectureTests
//
//  Created by Jackson Utsch on 5/18/21.
//

import XCTest
import Combine
import CombineSchedulers
@testable import Architecture

final class StoreTests: XCTestCase {
	let scheduler = DispatchQueue.test
	
	func testStateMutation() {
		let store = TestStore(
			initialState: State(),
			reducer: reducer,
			environment: scheduler.eraseToAnyScheduler()
		)
		
		store
			.assert(.add, mutates: { $0.number = 1 })
			.assert(.add, mutates: { $0.number = 2 })
			.assert(.subtract, mutates: { $0.number = 1 })
			.assert(.subtract, mutates: { $0.number = 0 })
	}
	
	/** - note:
	the effect does not instantly resolve
	*/
	func testEffect() {
		let store = TestStore(
			initialState: State(),
			reducer: reducer,
			environment: scheduler.eraseToAnyScheduler()
		)
		
		store.assert(.renameThenAdd, mutates: { $0.name = "custom name" })
		scheduler.advance()
		store.assertReceived(.add, mutated: { $0.number += 1 })
		store.assert(.add, mutates: { $0.number += 1 })
		XCTAssertEqual(store.state.number, 2)
	}
	
	/** - note:
	the observe closure is called on declaration, can get initial state
	*/
	func testObserve() {
		let store = TestStore(
			initialState: State(),
			reducer: reducer,
			environment: scheduler.eraseToAnyScheduler()
		)
		
		var observationCount = 0
		store.observe({ $0.number }) { _ in observationCount += 1 }
		store.assert(.add, mutates: { $0.number += 1 })
		store.assert(.add, mutates: { $0.number += 1 })
		store.assert(.add, mutates: { $0.number += 1 })
		XCTAssertEqual(observationCount, 4)
	}
	
//	func testDerived() {
//		let store = TestStore(
//			initialState: State(),
//			reducer: reducer,
//			environment: scheduler.eraseToAnyScheduler()
//		)
//		
//		// a scoped store sends actions to the parent and doesn't resolve immediatly,
//		// hence the scheduler must advance before state assertion
//		let scopedStore = store.derived(
//			state: { $0.substate },
//			action: { Action.subaction($0) },
//			env: { _ in }
//		)
//		scopedStore.assert(.insert(.init(id: .deadbeef, value: 0)), mutates: {
//			print($0)
//		})
////		, mutates: {
////			$0.contents.collection += [
////				.init(id: .deadbeef, value: 5)
////			]
////			$0.contents.index = 1
////		})
//		scheduler.advance()
//		// scoped stores pipe actions to their parent causing a return
//		XCTAssertEqual(scopedStore.state.contents.collection.count, 2)
//		XCTAssertEqual(store.state.substate.contents.collection.count, 2)
//		
//		// without being scoped, the changes can be asserted immediatly
//		let standaloneStore = TestStore(
//			initialState: SubState(contents: .init([], at: nil)),
//			reducer: subReducer,
//			environment: ()
//		)
//		// 		SubState.init(contents: .init([.init(id: .deadbeef, value: 0), .init(id: .deadbeef, value: 5)], at: 0))
//		//		standaloneStore.assert(
//		//			.insert(Substate.IdentifiableInt(value: 5)),
//		//			stateChanges: { $0.contents.collection[$0.contents.index!].value = 5 }
//		//		)
//	}
	
	// MARK: Reducer
	func reducer(state: inout State, action: Action, env: AnySchedulerOf<DispatchQueue>) -> AnyPublisher<Action, Never> {
		switch action {
		case .add:
			state.number += 1
			return .none
		case .subtract:
			state.number -= 1
			return .none
		case .renameThenAdd:
			state.name = "custom name"
			return Just(Action.add)
				.receive(on: env)
				// .delay(for: 2.0, scheduler: env)
				.eraseToAnyPublisher()
		case .subaction(let secondary):
			return subReducer(state: &state.substate, action: secondary, env: ())
				.map(Action.subaction)
				.eraseToAnyPublisher()
		}
	}
	
	// MARK: State
	struct State: Equatable {
		var number: Int = 0
		var name: String = "intial name"
		var substate: SubState = .init(
			contents: .init(
				[SubState.IdentifiableInt(id: .deadbeef, value: 5)],
				at: 0
			)
		)
	}
	
	// MARK: Action
	enum Action: Equatable {
		case add
		case subtract
		case renameThenAdd
		case subaction(SubAction)
	}
	
	// MARK: Substate Reducer
	func subReducer(
		state: inout SubState,
		action: SubAction,
		env: Void
	) -> AnyPublisher<SubAction, Never> {
		switch action {
		case .insert(let item):
			state.contents.new(item)
			return .none
		}
	}
	
	// MARK: Substate
	struct SubState: Equatable {
		var contents: OpenArray<IdentifiableInt>
		
		struct IdentifiableInt: Equatable, Identifiable {
			var id = UUID()
			var value: Int
			
			static func == (lhs: IdentifiableInt, rhs: IdentifiableInt) -> Bool {
				return lhs.value == rhs.value
			}
		}
	}
	
	// MARK: Substate Action
	enum SubAction: Equatable {
		case insert(SubState.IdentifiableInt)
	}
}
