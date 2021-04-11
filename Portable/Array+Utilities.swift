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

//MARK: - Array

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
    /// Method to append an optional. If optional is nil append does not occur.
    mutating func safeAppend(_ newElement: Self.Element?) {
        guard let newElement = newElement else {
            return
        }
        
        append(newElement)
    }
    
    /// Method to convert array into array of arrays with the given number of elements.
    /// - note: Does not use slices, may result in copies elements.
    func split(by numElements: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: numElements).map {
            Array(self[$0 ..< Swift.min($0 + numElements, count)])
        }
    }

    ///Convenience init to populate array with unique instances of Element.
    ///
    /// let foo: [Int] = Array(100) { $0 * 10 } //populates array with ints [0, 10, 20, ...]
    /// let bar: [IndexPath] = Array(5) { IndexPath(row: $0, section: 0) } //populates array with IndexPaths for rows 0...4 in section 0
    init(count: Int, repeating: (_ index: Int)->Element) {
        self.init()
        append(count: count, repeating: repeating)
    }
    
    ///Method to append a run of unique instances of Element to array.
    ///
    /// var foo: [Int] = []
    /// …
    /// foo.append(10) {$0 * 10} //appends elements: [0, 10, 20, ...]
    mutating func append(count: Int, repeating: (_ index: Int)->Element) {
        for index in 0..<count {
            append(repeating(index))
        }
    }
    
    ///Method to remove multiple elements at given indices.
    ///
    /// - note: The elements may not be returned in the order specified in the array of indices.
    ///      Elements are returned in the order the appeared in array.
    mutating func remove(at indices:[Int]) -> [Element] {
        var elements: [Element] = []
        for index in indices.sorted().reversed() {
            elements.append(remove(at: index))
        }
        return elements.reversed()
    }
    
    ///Return a slice representing the entire array
    /// This is useful for obtaining a shallow copy of the array which
    /// you can iterate while adding/deleting elements to the backing array
    func fullSlice() -> ArraySlice<Element> {
        self[0...]
    }
    
    @inlinable var isNotEmpty: Bool { !isEmpty }    
}

//MARK: - Set

public extension Set {
    struct SetDifferences {
        public var added: Set<Element>
        public var removed: Set<Element>
    }
    
    ///Method to identify differences between two sets in a single operation.
    ///
    ///Returns a struct containing sets of the elements that were either added or removed.
    func differences(from other: Set<Element>) -> SetDifferences {
        let added = self.subtracting(other)
        let removed = other.subtracting(self)
        return SetDifferences(added: added, removed: removed)
    }
}

//MARK: - Sequence

public extension Sequence {
    ///A  more accurate, but more expensive, version of underestimatedCount
    var exactCount: Int {
        self.reduce(into: .zero) { count, _ in count += 1 }
    }
    
    func sum<T: AdditiveArithmetic>(_ predicate: (Element) -> T) -> T {
        reduce(.zero) { $0 + predicate($1) }
    }
}

public extension Sequence where Element: AdditiveArithmetic {
    func sum() -> Element {
        reduce(.zero, +)
    }
}

public extension Sequence where Element: StringProtocol {
    func localizedStandardSort(_ order: ComparisonResult = .orderedAscending) -> [Element] {
        return sorted { $0.localizedStandardCompare($1) == order }
    }
}

//MARK: - Collection

//Average with predicate for complex types
public extension Collection {
    func average<T: BinaryInteger>(_ predicate: (Element) -> T) -> T {
        isEmpty ? .zero : T(sum(predicate) / T(count))
    }

    func average<T: BinaryInteger, F: BinaryFloatingPoint>(_ predicate: (Element) -> T) -> F {
        isEmpty ? .zero : (F(sum(predicate)) / F(count))
    }

    func average<T: BinaryFloatingPoint>(_ predicate: (Element) -> T) -> T {
        isEmpty ? .zero : sum(predicate) / T(count)
    }

    func average(_ predicate: (Element) -> Decimal) -> Decimal {
        isEmpty ? .zero : sum(predicate) / Decimal(count)
    }
}

//Average for primitive types
public extension Collection where Element: BinaryInteger {
    func average() -> Element {
        isEmpty ? .zero : sum() / Element(count)
    }
    func average<T: FloatingPoint>() -> T {
        isEmpty ? .zero : T(sum()) / T(count)
    }
}

//Average for primitive types
public extension Collection where Element: BinaryFloatingPoint {
    func average() -> Element {
        isEmpty ? .zero : Element(sum()) / Element(count)
    }
}

public extension Collection {
    ///Extension of index(after:) to allow wrap rather than 'past end' semantics
    func index(after i: Index, wrap: Bool) -> Index {
        var next = index(after: i)
        if wrap && next == endIndex {
            next = startIndex
        }
        return next
    }
}

///Trivial indexing generator that wraps back to startIndex when reaching endIndex
public class WrappingIndexingGenerator<C: Collection>: IteratorProtocol {
    private var _collection: C
    private var _index: C.Index
    
    public func next() -> C.Iterator.Element? {
        var item:C.Iterator.Element?
        if _index == _collection.endIndex {
            _index = _collection.startIndex
        }
        item = _collection[_index]
        _index = _collection.index(after: _index)
        return item
    }
    
    init(_ collection: C) {
        _collection = collection
        _index = _collection.startIndex
    }
}

//MARK: - RangeReplaceableCollection

public extension RangeReplaceableCollection where Self.Indices.Element == Int {
    ///Extract specified elements while preserving order of elements of indexSet.
    @discardableResult
    mutating func extractItems(in indexSet: IndexSet) -> [Self.Element] {
        precondition(indexSet.isStrictSubset(of: IndexSet(indices)))

        let result: [Self.Element] = {
            var extracts = [Self.Element]()
            extracts.reserveCapacity(indexSet.count)
            indexSet.forEach {
                extracts.append(self[$0])
            }
            return extracts
        }()
        
        //gotta be a better way?
        indexSet.sorted().reversed().forEach {
            self.remove(at: $0)
        }

        return result
    }
    
    ///Move items specified to specified location while preserving order of elements of indexSet.
    ///If destination is out of range after extractions items are placed at end.
    mutating func moveItems(from indexSet: IndexSet, to destinationIndex: Index) {
        precondition(indexSet.isStrictSubset(of: IndexSet(indices)))
        self.insert(contentsOf: self.extractItems(in: indexSet),
                    at: Swift.min(destinationIndex, endIndex))
    }
    
    ///Move items specified to back while preserving order of elements of indexSet.
    mutating func moveItemsToBack(from indexSet: IndexSet) {
        precondition(indexSet.isStrictSubset(of: IndexSet(indices)))
        self.append(contentsOf: self.extractItems(in: indexSet))
    }
    
    ///Move items specified to front while preserving order of elements of indexSet.
    mutating func moveItemsToFront(from indexSet: IndexSet) {
        precondition(indexSet.isStrictSubset(of: IndexSet(indices)))
        self.insert(contentsOf: self.extractItems(in: indexSet), at: startIndex)
    }
}
