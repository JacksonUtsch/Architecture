//
//  OptionalStateTests.swift
//  Architecture
//
//  Created by Jackson Utsch on 5/18/21.
//

import XCTest
@testable import Architecture
import Combine
import SwiftUI

final class OptionalTests: XCTestCase {
  
  func testA() {
    XCTAssertEqual(0, 0)
  }
//  let store = WindowStore(
//    initialState: WindowState.init(),
//    reducer: {
//      if $0 != nil {
//        return windowReducer(state: &($0!), action: $1, env: $2)
//      }
//      return nil
//    },
//    environment: ()
//  )
//
//  func testOptionalState() {
//    store.unwrapped()
//    CConditionalStoreView.init(
//      store: store,
//      content: { _ in EmptyView() },
//      elseContent: { EmptyView() }
//    )
//  }
}

typealias WindowStore = Store<WindowState?, WindowAction, Void>

func windowReducer(state: inout WindowState, action: WindowAction, env: Void) -> AnyPublisher<WindowAction, Never>? {
  return nil
}

struct WindowState: Equatable, Identifiable {
  let id = UUID()
}

enum WindowAction {
  case close
}
