import Combine
import XCTest
import CombineSchedulers

@testable import Architecture

final class CustomTests: XCTestCase {
	func testTest() {
		let sch = AnySchedulerOf<DispatchQueue>.testScheduler
		var actionCounter = 0
		var substate1 = 0
		var substate2 = 0
		var subaction1 = 0
		var subaction2 = 0
		
		func reducer(s: inout Int, a: Void, e: Void) -> AnyPublisher<Void, Never> {
			actionCounter += 1
			return .none
		}
		
		let mainStore = Store.init(initialState: 0, reducer: reducer, environment: ())
		let substore = mainStore
			.derived(state: { v -> Int in substate1 += 1; return v }, action: { subaction1 += 1; }, env: { })
			.derived(state: { v -> Int in substate2 += 1; return v }, action: { subaction2 += 1; }, env: { })
		
		mainStore.send(())
		mainStore.send(())
		substore.send(())
		substore.send(())
		substore.send(())
		
		sch.advance()
		sch.advance()
		sch.advance()
		sch.advance()
		sch.advance()
		
		XCTAssertEqual(actionCounter, 5)
		XCTAssertEqual(subaction1, 3)
		XCTAssertEqual(subaction2, 3)
		//    XCTAssertEqual(substate1, 5) keep in mind equatability
		//    XCTAssertEqual(substate2, 5)
		//    mainStore.assert(that: { $0 == 5 })
		//    XCTAssertEqual(mainStore.state, 5)
		//    XCTAssertEqual(substore.state, 5)
	}
}
