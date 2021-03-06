//
//  OptionalTests.swift
//  ArchitectureTests
//
//  Created by Jackson Utsch on 5/18/21.
//

import XCTest
import Combine
import SwiftUI
@testable import Architecture

final class OptionalTests: XCTestCase {
	func testDestructive() {
		let scheduler = DispatchQueue.test
		let appStore = AppStore.init(
			initialState: AppState.init(windows: .init([WindowState.init()], at: 0)),
			reducer: appReducer(state:action:env:),
			environment: ()
		)
		
		let id = appStore.state.windows.collection.first!.id
		
		func scope(close: (() -> ())) {
			let windowStore: Store<WindowState?, WindowAction, Void> = appStore.derived(
				state: { $0.windows.collection[safe: id] ?? nil },
				action: { AppAction.window(id, $0) },
				env: { }
			)
			
			windowStore.send(.inc)
			scheduler.advance()
			XCTAssertEqual(windowStore.state?.count, 1)
			
			close()
			scheduler.advance()
			XCTAssertEqual(windowStore.state?.count, nil)
		}
		
		scope() {
			appStore.send(.close(id))
			XCTAssertEqual(appStore.state.windows, .init([], at: nil))
		}
		
		appStore.send(.name("some"))
		XCTAssertEqual(appStore.state.text, "some")
	}
}

// MARK: App

typealias AppStore = Store<AppState, AppAction, Void>

func appReducer(
	state: inout AppState,
	action: AppAction,
	env: Void
) -> AnyPublisher<AppAction, Never> {
	switch action {
	case .window(let id, let secondary):
		guard let secondaryIndex = state.windows.collection.firstIndex(where: { $0.id == id }) else { return .none }
		return windowReducer(
			state: &state.windows.collection[secondaryIndex],
			action: secondary,
			env: env
		)
		.map { AppAction.window(id, $0) }
		.eraseToAnyPublisher()
	case .close(let id):
		state.windows.close(using: id)
		return .none
	case .name(let value):
		state.text = value
		return .none
	}
}

struct AppState: Equatable {
	var windows: OpenArray<WindowState>
	var text: String?
}

enum AppAction {
	case window(WindowState.ID, WindowAction)
	case close(WindowState.ID)
	case name(String)
}

// MARK: Window

typealias WindowStore = Store<WindowState, WindowAction, Void>

func windowReducer(
	state: inout WindowState,
	action: WindowAction,
	env: Void
) -> AnyPublisher<WindowAction, Never> {
	switch action {
	case .inc:
		state.count += 1
		return .none
	}
}

struct WindowState: Equatable & Identifiable {
	let id = UUID()
	var count = 0
}

enum WindowAction {
	case inc
}
