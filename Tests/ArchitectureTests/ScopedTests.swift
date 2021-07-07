//
//  ScopedTests.swift
//  
//
//  Created by Jackson Utsch on 6/28/21.
//

import XCTest
@testable import Architecture
import Combine
import CombineSchedulers

/* - notes:
  Make .scoped have default values? not requiring state, action or env?
  scoped vs scope vs derived naming
 */

final class ScopedTests: XCTestCase {
  func testNonVoid() {
    let scheduler = DispatchQueue.test
    
    struct IntWrapper: Equatable {
      var count = 0
    }
    
    func reducer(s: inout IntWrapper, a: MainAction, e: Void) -> AnyPublisher<MainAction, Never>? {
//      NSLog("SHOULD INC")
      switch a {
      case .inc:
        s.count += 1
        return nil
      }
    }
    
    enum MainAction {
      case inc
    }
    
    let mainStore = Store<IntWrapper, MainAction, Void>.init(
      initialState: IntWrapper(),
      reducer: reducer,
      environment: (),
      scheduler: scheduler.eraseToAnyScheduler()
    )
    
    let substore = mainStore.derived(
      state: { $0.count },
      action: { MainAction.inc },
      env: { }
    )
    
    substore.send(())
    scheduler.advance()
    // why do we require the scheduler to advance, why is main thread not operational?
    
    XCTAssertEqual(mainStore.state.count, 1)
    XCTAssertEqual(substore.state, 1)
  }
  
  func testScopeCalls() {
    func reducer(s: inout Int, a: Void, e: Void) -> AnyPublisher<Void, Never>? {
//      NSLog("SHOULD INC")
      s += 1
      return nil
    }
    
    var scoped1: Int = 0
    var scoped2: Int = 0
    var scoped3: Int = 0
    
    let mainStore = Store.init(
      initialState: 0,
      reducer: reducer(s:a:e:),
      environment: (),
      scheduler: .main
    )
    let subStore: Store<Int, Void, Void> = mainStore
      .derived(state: { return $0 }, action: { scoped1 += 1 }, env: { })
      .derived(state: { return $0 }, action: { scoped2 += 1 }, env: { })
      .derived(state: { return $0 }, action: { scoped3 += 1 }, env: { })
    
    subStore.send(())
    subStore.send(())
    subStore.send(())
    subStore.send(())
    mainStore.send(())
    
    XCTAssertEqual(mainStore.state, 5)
    XCTAssertEqual(subStore.state, 5)
    XCTAssertEqual(scoped1, 5)
    XCTAssertEqual(scoped2, 5)
    XCTAssertEqual(scoped3, 5)
    
    subStore.send(())
    
    XCTAssertEqual(mainStore.state, 2)
    XCTAssertEqual(subStore.state, 2)
    XCTAssertEqual(scoped1, 2)
    XCTAssertEqual(scoped2, 2)
    XCTAssertEqual(scoped3, 2)
    
    subStore.send(())
  }
}
