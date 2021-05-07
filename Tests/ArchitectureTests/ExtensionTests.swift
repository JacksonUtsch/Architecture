//
//  ExtensionTests.swift
//  Architecture
//
//  Created by Jackson Utsch on 5/7/21.
//

import XCTest
@testable import Architecture
import SwiftUI

final class ExtensionTests: XCTestCase {
  func testHexColor() {
    XCTAssertEqual(Color.white.hashValue, Color.init(hex: 0xFFFFFF).hashValue)
    XCTAssertEqual(Color.black.hashValue, Color.init(hex: 0x000000).hashValue)
  }
}
