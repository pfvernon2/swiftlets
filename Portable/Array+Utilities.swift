//
//  Array+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/16/18.
//  Copyright © 2018 Frank Vernon. All rights reserved.
//

import Foundation

/// A first-in/first-out queue of unconstrained size
/// - Complexity: push is O(1), pop is O(`count`)
/// http://ericasadun.com/2016/03/08/swift-queue-fun/
public struct Queue<T>: ExpressibleByArrayLiteral {
    /// backing array store
    public fileprivate(set) var elements: Array<T> = []
    
    /// introduce a new element to the queue in O(1) time
    public mutating func push(_ value: T) { elements.append(value) }
    
    /// remove the front of the queue in O(`count` time
    public mutating func pop() -> T { elements.removeFirst() }
    
    /// test whether the queue is empty
    public var isEmpty: Bool { elements.isEmpty }
    
    /// queue size, computed property
    public var count: Int { elements.count }
    
    /// offer `ArrayLiteralConvertible` support
    public init(arrayLiteral elements: T...) { self.elements = elements }
}

public extension Array {
    ///Add element to end of array and pop elment(s) off the front
    /// when specified depth exceeded
    mutating func enqueue(_ newElement: Self.Element, maxDepth: Int) {
        removeOverflow(newCount: count + 1, maxDepth: maxDepth, location: .front)
        append(newElement)
    }
    
    ///Add elements to end of array and pop elment(s) off the front
    /// when specified depth exceeded
    mutating func enqueue<S>(contentsOf newElements: S, maxDepth: Int) where Element == S.Element, S : Sequence {
        removeOverflow(newCount: count + newElements.exactCount, maxDepth: maxDepth, location: .front)
        append(contentsOf: newElements)
    }
    
    ///Enumeration specifying location within an array. Used for performing operations at
    /// specified locations within the array.
    enum OverflowLocation {
        case front
        case middle
        case back
    }
        
    ///Remove elements from array at specified location when specified depth exceeded
    mutating func removeOverflow(newCount: Int, maxDepth: Int, location: OverflowLocation) {
        let overflow = newCount - maxDepth
        guard overflow > 0 else {
            return
        }
        
        switch location {
        case .front:
            removeFirst(overflow)
            
        case .middle:
            //Middle can be a bit ambiguous but we do what we can here.
            //One could create middleFront, middleBack enums but this works for my purposes
            let middle = ceil(Double(count)/2.0)
            let rangeStart = Int(middle - floor(Double(overflow)/2.0))
            removeSubrange(rangeStart..<rangeStart+overflow)
            
        case .back:
            removeLast(overflow)
        }
    }
}

public extension Array {
    mutating func appendIfExists(_ newElement: Self.Element?) {
        guard let newElement = newElement else {
            return
        }
        
        append(newElement)
    }
}

public extension Sequence {
    ///A  more expensive but more accurate version of underestimatedCount
    var exactCount: Int {
        self.reduce(into: 0) { count, _ in count += 1 }
    }
}
