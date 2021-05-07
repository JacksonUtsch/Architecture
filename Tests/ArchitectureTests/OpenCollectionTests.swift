//
//  OpenCollectionTests.swift
//  Architecture
//
//  Created by Jackson Utsch on 5/6/21.
//

import XCTest
@testable import Architecture

final class OpenCollectionTests: XCTestCase {
  func testOpenArray() {
    enum IdentifiableColor: String, Identifiable, Equatable {
      case red, green, blue
      var id: String { return self.rawValue }
    }
    var arr: OpenArray<IdentifiableColor> = .init([.red, .green], at: 1)
    arr.new(.blue)
    XCTAssertEqual(arr, .init([.red, .green, .blue], at: 2))
    arr.open(with: .using("red"))
    XCTAssertEqual(arr, .init([.red, .green, .blue], at: 0))
    arr.close(with: OpenArray<IdentifiableColor>.Specifier.current)
    XCTAssertEqual(arr, .init([.green, .blue], at: 0))
    arr.close(at: 1)
    XCTAssertEqual(arr, .init([.green], at: 0))
    arr.clear()
    XCTAssertEqual(arr, .init([], at: nil))
  }
  
  func testNavigationalArray() {
    enum IdentifiableNumber: String, Identifiable, Equatable {
      case zero, one, two, three, four, five, six
      var id: String { return self.rawValue }
    }
    var arr: NavigationalArray<IdentifiableNumber> = .init([.zero, .one], at: 1)
    arr.pull()
    arr.new(.two)
    arr.push()
    arr.push()
    XCTAssertEqual(arr, .init([.zero, .two], at: 1))
    arr.open(using: "zero")
    arr.close(at: 0)
    XCTAssertEqual(arr, .init([.two], at: 0))
    arr.close(using: "two")
    XCTAssertEqual(arr, .init([], at: nil))
    arr.new(.five)
    arr.new(.six)
    XCTAssertEqual(arr, .init([.five, .six], at: 1))
    arr = .init([.one, .two, .three, .four, .five], at: 1)
    arr.new(.zero)
    XCTAssertEqual(arr, .init([.one, .two, .zero], at: 2))
  }
}
