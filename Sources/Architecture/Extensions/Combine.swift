//
//  Combine.swift
//  Architecture
//
//  Created by Jackson Utsch on 7/14/21.
//

import Combine

extension AnyPublisher {
	/// Nil equivalent for a publisher
	public static var none: Self {
		Empty<Self.Output, Self.Failure>(completeImmediately: true)
			.eraseToAnyPublisher()
	}
}
