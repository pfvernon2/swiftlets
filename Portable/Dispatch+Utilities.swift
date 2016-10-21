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
        let microseconds:Int = Int(seconds.toMicroseconds())
        let dispatchOffset:DispatchTime = .now() + .microseconds(microseconds)
        return dispatchOffset
    }

    ///asyncAfter with TimeInterval semanics, i.e. nanosecond precision out to 10,000 years.
    func asyncAfter(secondsSinceNow seconds: TimeInterval, execute work: @escaping @convention(block) () -> Swift.Void) {
        asyncAfter(deadline: dispatchTimeSinceNow(seconds: seconds), execute: work)
    }

    ///asyncAfter with TimeInterval semanics, i.e. nanosecond precision out to 10,000 years.
    func asyncAfter(secondsSinceNow seconds: TimeInterval, execute: DispatchWorkItem) {
        asyncAfter(deadline: dispatchTimeSinceNow(seconds: seconds), execute: execute)
    }
}

public class DispatchReaderWriter {
    private var concurrentQueue:DispatchQueue = DispatchQueue(label: "com.cyberdev.Dispatch.readerWriter", attributes: .concurrent)

    public func read<T>(execute work: () throws -> T) rethrows -> T {
        return try self.concurrentQueue.sync(execute: work)
    }

    public func write(execute work: @escaping @convention(block) () -> Swift.Void) {
        self.concurrentQueue.async(flags: .barrier, execute: work)
    }
}

public class readerWriterType<T> {
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
