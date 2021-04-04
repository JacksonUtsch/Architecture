//
//  Tests.swift
//  Architecture
//
//  Created by Jackson Utsch on 3/21/21.
//

import Foundation

// MARK: Assert
public extension Store {
    @discardableResult
    func assert
    (
        _ action: Action? = nil,
        that expectation: @escaping (State) -> Bool,
        with delay: Double? = nil
    ) -> Self {
        if let action = action {
            send(action)
        }
        
        guard let delay = delay else {
            if expectation(self.state) == false {
                _XCTFail()
            }
            return self
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if expectation(self.state) == false {
                _XCTFail()
            }
        }
        return self
    }
}

// MARK: XCTest Incorporation
// https://forums.swift.org/t/dynamically-call-xctfail-in-spm-module-without-importing-xctest/36375
// NB: Dynamically load XCTest to prevent leaking its symbols into our library code.
private func _XCTFail(_ message: String = "", file: StaticString = #file, line: UInt = #line) {
  guard
    let _XCTFailureHandler = _XCTFailureHandler,
    let _XCTCurrentTestCase = _XCTCurrentTestCase
  else {
    assertionFailure(
      """
      Couldn't load XCTest. Are you using a test store in application code?"
      """,
      file: file,
      line: line
    )
    return
  }

  _XCTFailureHandler(_XCTCurrentTestCase(), true, "\(file)", line, message, nil)
}

private typealias XCTCurrentTestCase = @convention(c) () -> AnyObject
private typealias XCTFailureHandler = @convention(c) (
  AnyObject, Bool, UnsafePointer<CChar>, UInt, String, String?
) -> Void

private let _XCTest = NSClassFromString("XCTest")
  .flatMap(Bundle.init(for:))
  .flatMap({ $0.executablePath })
  .flatMap({ dlopen($0, RTLD_NOW) })

private let _XCTFailureHandler =
  _XCTest
  .flatMap { dlsym($0, "_XCTFailureHandler") }
  .map({ unsafeBitCast($0, to: XCTFailureHandler.self) })

private let _XCTCurrentTestCase =
  _XCTest
  .flatMap { dlsym($0, "_XCTCurrentTestCase") }
  .map({ unsafeBitCast($0, to: XCTCurrentTestCase.self) })
