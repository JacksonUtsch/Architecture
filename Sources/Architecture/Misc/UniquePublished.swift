//
//  UniquePublished.swift
//  
//
//  Created by Jackson Utsch on 4/24/21.
//

import Combine

@propertyWrapper
public struct UniquePublished<Value: Equatable> {
  private let storage: CurrentValueSubject<Value, Never>
  
  public init(wrappedValue value: Value) {
    self.storage = CurrentValueSubject<Value, Never>(value)
  }
  
  public var projectedValue: AnyPublisher<Value, Never> {
    storage.eraseToAnyPublisher()
  }
  
  public var wrappedValue: Value {
    get { self.storage.value }
    set { storage.send(newValue) }
  }
  
  public static subscript<T: ObservableObject>(
    _enclosingInstance instance: T,
    wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
    storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
  ) -> Value {
    get { instance[keyPath: storageKeyPath].storage.value }
    set {
      guard newValue != instance[keyPath: storageKeyPath].storage.value else { return }
      (instance.objectWillChange as? ObservableObjectPublisher)?.send()
      instance[keyPath: storageKeyPath].storage.send(newValue)
    }
  }
}
