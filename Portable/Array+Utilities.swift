//
//  Array+DHV.swift
//  WebResearch
//
//  Created by David Vernon on 6/5/16.
//  Copyright © 2016 David Vernon. All rights reserved.
//

import Foundation

extension Array {
    
    /**
     Move an element of an array to another index position.
     
     - parameters:
         - fromIndex: The index of an element in the array.
         - toIndex: The index of a position in the array to which to move the element
     */

    public mutating func moveElement(fromIndex:Int, toIndex:Int) {
        self.insert(self.remove(at: fromIndex), at: toIndex)
    }
    
    /**
     Return a copy of an array with an element moved to another index position.
     
     - parameters:
         - fromIndex: The index of an element in the array.
         - toIndex: The index of a position in the array to which to move the element
     */

    public func arrayWithElementMoved(fromIndex fromIdex:Int, toIndex:Int) -> Array {
        var result = self
        result.moveElement(fromIndex: fromIdex, toIndex: toIndex)
        return result
    }

    ///Simplified queue semantics
    public mutating func push(_ newElement: Element) {
        return append(newElement)
    }

    ///Simplified queue semantics
    public mutating func pop() -> Element? {
        if !isEmpty {
            return removeFirst()
        } else {
            return nil
        }
    }
}

extension Array where Element: Equatable {
    mutating func remove(_ object: Element) {
        if let index = index(where: { $0 == object }) {
            self.remove(at: index)
        }
    }
}

/// A first-in/first-out queue of unconstrained size
/// - Complexity: push is O(1), pop is O(`count`)
/// http://ericasadun.com/2016/03/08/swift-queue-fun/
public struct Queue<T>: ExpressibleByArrayLiteral {
    /// backing array store
    public fileprivate(set) var elements: Array<T> = []

    /// introduce a new element to the queue in O(1) time
    public mutating func push(_ value: T) { elements.append(value) }

    /// remove the front of the queue in O(`count` time
    public mutating func pop() -> T { return elements.removeFirst() }

    /// test whether the queue is empty
    public var isEmpty: Bool { return elements.isEmpty }

    /// queue size, computed property
    public var count: Int { return elements.count }

    /// offer `ArrayLiteralConvertible` support
    public init(arrayLiteral elements: T...) { self.elements = elements }
}
