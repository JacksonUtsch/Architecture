//
//  Combine.swift
//  Architecture
//
//  Created by Jackson Utsch on 7/14/21.
//

import Foundation
import Combine

// MARK: None
extension AnyPublisher {
	/// Nil equivalent for a publisher
	public static var none: Self {
		Empty<Self.Output, Self.Failure>(completeImmediately: true)
			.eraseToAnyPublisher()
	}
}

// MARK: Normalize
extension Optional where Wrapped == AnyPublisher<Any, Error> {
	/// Erases an optional publisher to an empty
	public var normalize: Wrapped {
		if let publisher = self {
			return publisher
		} else {
			return .none
		}
	}
}

extension Optional where Wrapped: Combine.Publisher {
	/// Erases an optional publisher to an empty
	public var normalize: AnyPublisher<Wrapped.Output, Wrapped.Failure> {
		if let publisher = self {
			return publisher
				.eraseToAnyPublisher()
		} else {
			return Empty<Wrapped.Output, Wrapped.Failure>()
				.eraseToAnyPublisher()
		}
	}
}

extension AnyPublisher {
	public static func just<T>(value: T) -> AnyPublisher<T, Never> {
		Just(value).eraseToAnyPublisher()
	}
}

// MARK: Deferred
extension AnyPublisher {
	public func defered<S: Scheduler>(
		for duration: S.SchedulerTimeType.Stride,
		on scheduler: S,
		options: S.SchedulerOptions? = nil
	) -> Self {
		Just(())
			.setFailureType(to: Failure.self)
			.delay(for: duration, tolerance: nil, scheduler: scheduler, options: options)
			.flatMap { self }
			.eraseToAnyPublisher()
	}
}

// MARK: Cancellable
extension AnyPublisher {
	public func cancellable(id: AnyHashable, overrides: Bool = false) -> AnyPublisher {
		cancellablesLock.lock()
		defer { cancellablesLock.unlock() }
		
		let subject = PassthroughSubject<Output, Failure>()
		let cancellable = self.subscribe(subject)
		
		var cancellationCancellable: AnyCancellable!
		cancellationCancellable = AnyCancellable {
			cancellablesLock.sync {
				subject.send(completion: .finished)
				cancellable.cancel()
				cancellationCancellables[id]?.remove(cancellationCancellable)
				if cancellationCancellables[id]?.isEmpty == .some(true) {
					cancellationCancellables[id] = nil
				}
			}
		}
		
		cancellationCancellables[id, default: []].insert(cancellationCancellable)
		
		return subject.handleEvents(
			receiveCompletion: { _ in cancellationCancellable.cancel() },
			receiveCancel: cancellationCancellable.cancel
		).eraseToAnyPublisher()
	}
	
	public static func cancel(id: AnyHashable) -> AnyPublisher {
		cancellablesLock.sync {
			cancellationCancellables[id]?.forEach { $0.cancel() }
		}
		return .none
	}
}

extension NSRecursiveLock {
	@inlinable @discardableResult
	func sync<R>(work: () -> R) -> R {
		self.lock()
		defer { self.unlock() }
		return work()
	}
}

internal var cancellationCancellables: [AnyHashable: Set<AnyCancellable>] = [:]
internal let cancellablesLock = NSRecursiveLock()
