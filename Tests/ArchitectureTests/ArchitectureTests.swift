import XCTest
@testable import Architecture
import Combine
import CombineSchedulers

final class ArchitectureTests: XCTestCase {
    let testStore = TestStore(initialState: TestState(), reducer: testReducer(state:action:env:), environment: (), scheduler: .immediate)
    
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
        testStore
            .assert(.chain, that: {$0.name == "custom name" && $0.number == 1})        
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
        // a scoped store sends actions to parent and doesn't resolve immediatly, hence the test uses a delay
        let scopedStore = testStore.substore(state: { $0.substate },
                                             action: { TestAction.substate($0) },
                                             env: {_ in})
        
        scopedStore.assert(.insert(Substate.IdentifiableInt(value: 5)),
                        that: {$0.contents.collection.count == 2},
                        with: 0.01)
        
        // without being scoped, the changes can be asserted immediatly
        let standaloneStore = SubstateStore(initialState: Substate(contents: .init([], at: nil)),
                                            reducer: substateReducer(state:action:env:),
                                            environment: ())
        
        standaloneStore.assert(.insert(Substate.IdentifiableInt(value: 5)),
                               that: {$0.contents.current?.value == 5})
    }
}

// MARK: Store
typealias TestStore = Store<TestState, TestAction, Void>
extension TestStore {
    static let shared = TestStore(initialState: TestState(), reducer: testReducer(state:action:env:), environment: ())
}

// MARK: Reducer
func testReducer(state: inout TestState, action: TestAction, env: Void) -> AnyPublisher<TestAction, Never>? {
    switch action {
    case .add:
        state.number += 1
        return nil
    case .subtract:
        state.number -= 1
        return nil
    case .chain:
        state.name = "custom name"
        return Just(TestAction.add)
            .eraseToAnyPublisher()
    case .substate(let secondary):
        return substateReducer(state: &state.substate, action: secondary, env: ())?
            .map(TestAction.substate)
            .eraseToAnyPublisher()
    }
}

// MARK: State
struct TestState: Equatable {
    var number: Int = 0
    var name: String = "intial name"
    var substate: Substate = .init(contents: OpenArray<Substate.IdentifiableInt>.init([Substate.IdentifiableInt(value: 5)], at: 0))
}

// MARK: Action
enum TestAction {
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
