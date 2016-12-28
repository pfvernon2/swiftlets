//
//  Dispatch+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 8/29/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

public extension DispatchQueue {
    private func dispatchTimeSinceNow(seconds: TimeInterval) -> DispatchTime {
        let microseconds:Int = Int(seconds * 1000000)
        let dispatchOffset:DispatchTime = .now() + .microseconds(microseconds)
        return dispatchOffset
    }

    ///asyncAfter with TimeInterval semanics, i.e. microsecond precision out to 10,000 years.
    func asyncAfter(secondsSinceNow seconds: TimeInterval, execute work: @escaping @convention(block) () -> Swift.Void) {
        asyncAfter(deadline: dispatchTimeSinceNow(seconds: seconds), execute: work)
    }

    ///asyncAfter with TimeInterval semanics, i.e. microsecond precision out to 10,000 years.
    func asyncAfter(secondsSinceNow seconds: TimeInterval, execute: DispatchWorkItem) {
        asyncAfter(deadline: dispatchTimeSinceNow(seconds: seconds), execute: execute)
    }
}

/**
 Reader Writer queue with first-in priority semantics. Reads occur concurrently and writes serially.
 
 Execution is based on first-in semantics of the queue. i.e. Pending read operations will be exhausted before a write operation occurs
 and subsequent read operations will be held off until a write completes.
 
 - note: Pending read operations may cause unexpected race conditions. If you must ensure that the data
 read is as fresh as possible you may want to consider using the DispatchWriterReader class. The DispatchWriterReader class ensures
 that reads return the most recent data based on their execution time as apposed to their queue order.
 */
open class DispatchReaderWriter {
    private var concurrentQueue:DispatchQueue = DispatchQueue(label: "com.cyberdev.Dispatch.readerWriter", attributes: .concurrent)

    public func read<T>(execute work: () throws -> T) rethrows -> T {
        return try self.concurrentQueue.sync(execute: work)
    }

    public func write(execute work: @escaping @convention(block) () -> Swift.Void) {
        self.concurrentQueue.async(flags: .barrier, execute: work)
    }
}

/**
 Reader Writer queue with write priority semantics. Reads occur concurrently and writes serially.
 
 Execution is based on write priotity at execution time rather than queue insertion order. i.e. Pending reads 
 that have not begun executing will be held off until all writes occur. This is useful in situations where race conditions
 at execution time must be minimized.
 
 - note: This object incurs more overhead than the DispatchReaderWriter class. Its usefulness is likely limited to
 cases where it is crucial to minimize race conditions when accessing the data.
 */
open class DispatchWriterReader {
    private var writeQueue:DispatchQueue = DispatchQueue(label: "com.cyberdev.Dispatch.writerReader.write")
    private var readQueue:DispatchQueue = DispatchQueue(label: "com.cyberdev.Dispatch.writerReader.read", attributes: .concurrent)
    private var readGroup:DispatchGroup = DispatchGroup()

    public func read<T>(execute work: () throws -> T) rethrows -> T {
        return try self.readQueue.sync {
            self.readGroup.enter()
            let result:T = try work()
            self.readGroup.leave()
            return result
        }
    }
    
    public func write(execute work: @escaping @convention(block) () -> Swift.Void) {
        readQueue.suspend()
        self.readGroup.wait()
        self.writeQueue.async {
            work()
            self.readQueue.resume()
        }
    }
}

///Templated DispatchReaderWriter class. Useful for thread safe access to a single memeber variable in a class, for example.
open class readerWriterType<T> {
    private var queue:DispatchReaderWriter = DispatchReaderWriter()
    private var _value:T? = nil
    public var value:T? {
        get {
            var result:T?
            self.queue.read {
                result = self._value
            }
            return result
        }

        set (newElement) {
            self.queue.write {
                self._value = newElement
            }
        }
    }
}

///Templated DispatchWriterReader class. Useful for thread safe access to a single memeber variable in a class, for example.
open class writerReaderType<T> {
    private var queue:DispatchWriterReader = DispatchWriterReader()
    private var _value:T? = nil
    public var value:T? {
        get {
            var result:T?
            self.queue.read {
                result = self._value
            }
            return result
        }
        
        set (newElement) {
            self.queue.write {
                self._value = newElement
            }
        }
    }
}
