//
//  CancellationTest.swift
//  Architecture
//
//  Created by Jackson Utsch on 7/15/21.
//

import Combine
import XCTest
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
}
