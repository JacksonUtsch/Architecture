import XCTest
@testable import Architecture
import Combine
import CombineSchedulers

final class ArchitectureTests: XCTestCase {
    static let scheduler = DispatchQueue.test
    let testStore = Store(initialState: ArchTestState(), reducer: testReducer(state:action:env:), environment: (), scheduler: scheduler.eraseToAnyScheduler())
    
    func testBasic() {
        testStore
            .assert(.add, that: {$0.number == 1})
            .assert(.add, that: {$0.number == 2})
            .assert(.subtract, that: {$0.number == 1})
            .assert(.subtract, that: {$0.number == 0})
    }
    
    /** - note:
     the effect does not instantly resolve
     */
    func testEffect() {
        testStore.send(.chain)
        XCTAssertEqual(testStore.state.name, "custom name")
        ArchitectureTests.scheduler.advance()
        XCTAssertEqual(testStore.state.number, 1)
    }
    
    /** - note:
     the closure is called on declaration
     */
    func testObserve() {
        var observationCount = 0
        testStore.observe(get: {$0.number}) { _ in
            observationCount += 1
        }
        testStore.send(.add)
        testStore.send(.add)
        testStore.send(.add)
        XCTAssert(observationCount == 4)
    }
    
    func testScope() {
        // scoped store send actions to the parent and doesn't resolve immediatly,
        // hence the scheduler must advance before assertion
        let scopedStore = testStore.substore(state: { $0.substate },
                                             action: { ArchTestAction.substate($0) },
                                             env: {_ in})
        
        scopedStore.send(.insert(Substate.IdentifiableInt(value: 5)))
        ArchitectureTests.scheduler.advance()
        // scoped stores pipe actions to their parent causing a return
        XCTAssertEqual(scopedStore.state.contents.collection.count, 2)
        
        // without being scoped, the changes can be asserted immediatly
        let standaloneStore = SubstateStore(initialState: Substate(contents: .init([], at: nil)),
                                            reducer: substateReducer(state:action:env:),
                                            environment: (), scheduler: ArchitectureTests.scheduler.eraseToAnyScheduler())
        
        standaloneStore.assert(.insert(Substate.IdentifiableInt(value: 5)),
                               that: {$0.contents.current?.value == 5})
    }
}

// MARK: Store
typealias ArchTestStore = Store<ArchTestState, ArchTestAction, Void>

// MARK: Reducer
func testReducer(state: inout ArchTestState, action: ArchTestAction, env: Void) -> AnyPublisher<ArchTestAction, Never>? {
    switch action {
    case .add:
        state.number += 1
        return nil
    case .subtract:
        state.number -= 1
        return nil
    case .chain:
        state.name = "custom name"
        return Just(ArchTestAction.add)
            .eraseToAnyPublisher()
    case .substate(let secondary):
        return substateReducer(state: &state.substate, action: secondary, env: ())?
            .map(ArchTestAction.substate)
            .eraseToAnyPublisher()
    }
}

// MARK: State
struct ArchTestState: Equatable {
    var number: Int = 0
    var name: String = "intial name"
    var substate: Substate = .init(contents: OpenArray<Substate.IdentifiableInt>.init([Substate.IdentifiableInt(value: 5)], at: 0))
}

// MARK: Action
enum ArchTestAction {
    case add
    case subtract
    case chain
    case substate(SubstateAction)
}


// MARK: SubstateStore
typealias SubstateStore = Store<Substate, SubstateAction, Void>

// MARK: Substate Reducer
func substateReducer(state: inout Substate, action: SubstateAction, env: Void) -> AnyPublisher<SubstateAction, Never>? {
    switch action {
    case .insert(let item):
        state.contents.new(item)
        return nil
    }
}

// MARK: Substate
struct Substate: Equatable {
    var contents: OpenArray<IdentifiableInt>

    struct IdentifiableInt: Equatable, Identifiable {
        let id = UUID()
        let value: Int

        static func == (lhs: IdentifiableInt, rhs: IdentifiableInt) -> Bool {
            return lhs.value == rhs.value
        }
    }
}

// MARK: Substate Action
enum SubstateAction {
    case insert(Substate.IdentifiableInt)
}
