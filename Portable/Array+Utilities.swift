//
//  Array+DHV.swift
//  swiftlets
//
//  Created by David Vernon on 6/5/16.
//  Copyright © 2016 David Vernon. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    @discardableResult mutating func remove(firstLike item: Element) -> Element? {
        guard let matching:Int = index(where: { $0 == item }) else {
            return nil
        }
        
        return self.remove(at: matching)
    }
    
    @discardableResult mutating func remove(firstNotLike item: Element) -> Element? {
        guard let matching:Int = index(where: { $0 != item }) else {
            return nil
        }
        
        return self.remove(at: matching)
    }

    @discardableResult mutating func remove(allLike item: Element) -> Int {
        let matching:[Int] = indexes(ofItemsLike: item)
        
        matching.reversed().forEach { (index) in
            remove(at: index)
        }
        
        return matching.count
    }
    
    @discardableResult mutating func remove(allNotLike item: Element) -> Int {
        let matching:[Int] = indexes(ofItemsNotLike: item)
        
        matching.reversed().forEach { (index) in
            remove(at: index)
        }
        
        return matching.count
    }
    
    func indexes(ofItemsLike item: Element) -> [Int]  {
        return self.enumerated().flatMap { $0.element == item ? $0.offset : nil }
    }
    
    func indexes(ofItemsNotLike item: Element) -> [Int]  {
        return self.enumerated().flatMap { $0.element != item ? $0.offset : nil }
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
