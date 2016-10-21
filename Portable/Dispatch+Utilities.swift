//
//  Dispatch+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 8/29/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

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
