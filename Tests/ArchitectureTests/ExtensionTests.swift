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
    XCTAssertEqual(Color.white, Color.init(hex: 0xFFFFFF))
    XCTAssertEqual(Color.black, Color.init(hex: 0x000000))
  }
}
