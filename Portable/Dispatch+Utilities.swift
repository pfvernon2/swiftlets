//
//  Dispatch+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 8/29/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

public extension DispatchQueue {
    private func dispatchTimeFromNow(seconds: TimeInterval) -> DispatchTime {
        let microseconds:Int = Int(seconds * 1000000.0)
        let dispatchOffset:DispatchTime = .now() + .microseconds(microseconds)
        return dispatchOffset
    }
    
    ///asyncAfter with TimeInterval semanics, i.e. microsecond precision out to 10,000 years.
    func asyncAfter(secondsFromNow seconds: TimeInterval, execute work: @escaping @convention(block) () -> Swift.Void) {
        asyncAfter(deadline: dispatchTimeFromNow(seconds: seconds), execute: work)
    }
    
    ///asyncAfter with TimeInterval semanics, i.e. microsecond precision out to 10,000 years.
    func asyncAfter(secondsFromNow seconds: TimeInterval, execute: DispatchWorkItem) {
        asyncAfter(deadline: dispatchTimeFromNow(seconds: seconds), execute: execute)
    }
    
    private static var _onceTracker = [String]()
    
    /**
     Executes a block of code, associated with a unique identifier, only once. This method is thread safe and will
     only execute the code once even when called concurrently.
     
     - parameter identifier: A unique identifier such as a reverse DNS style name (com.domain.appIdentifier), or a GUID
     - parameter closure: Block of code to execute only once
     */
    public class func executeOnce(identifier: String, closure:()->Swift.Void) {
        objc_sync_enter(self)
        
        defer {
            objc_sync_exit(self)
        }

        guard !_onceTracker.contains(identifier) else {
            return
        }
        
        _onceTracker.append(identifier)
        
        closure()
    }
}

/**
 Reader Writer queue with first-in priority semantics. Reads occur concurrently and writes serially.
 
 Execution is based on first-in semantics of the queue, i.e. pending read operations will be exhausted before a write operation occurs
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
 This class is similar to a reader writer queue but with write priority semantics. Reads occur concurrently and writes serially.
 
 Execution is based on write priotity at execution time rather than the first-in semantics of the reader writter queue, i.e. pending reads
 that have not begun executing will be held off until all writes occur. This is useful in situations where race conditions
 at execution time must be minimized. While this may be useful, or even critical, for some operations please be aware that it can result
 in long delays, or even starvation, on read.
 
 - note: This object incurs significantly more overhead than the DispatchReaderWriter class. Its usefulness is likely limited to
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

///Generic DispatchReaderWriter class. Useful for thread safe access to a single memeber variable in a class, for example.
open class readerWriterType<T> {
    private var queue:DispatchReaderWriter = DispatchReaderWriter()
    private var _value:T
    
    init(value:T) {
        _value = value
    }
    
    public var value:T {
        get {
            return self.queue.read { () -> T in
                return self._value
            }
        }
        
        set (newElement) {
            self.queue.write {
                self._value = newElement
            }
        }
    }
}

///Generic DispatchWriterReader class. Useful for thread safe access to a single memeber variable in a class, for example.
open class writerReaderType<T> {
    private var queue:DispatchWriterReader = DispatchWriterReader()
    private var _value:T

    init(value:T) {
        _value = value
    }

    public var value:T {
        get {
            return self.queue.read { () -> T in
                return self._value
            }
        }
        
        set (newElement) {
            self.queue.write {
                self._value = newElement
            }
        }
    }
}

/**
 Class representing the concept of a guard in GCD. This would typically be used where
 one must limit the number of threads accessing a resource or otherwise prevent reentrancy.
 
 This class is, in essence, a semaphore with "no wait" semantics. Rather than waiting for
 the semaphore to be signaled this class returns immediately with an indication of whether
 the semaphore was successfully decremented. This is useful in cases where you do not care
 to reenter an operation that is already in flight, for example.
 
 ```
 let uiGuard:DispatchGuard = DispatchGuard()
 
 func updateUI() {
    guard uiGuard.enter() else {
        return
    }
 
    defer {
        uiGuard.exit()
    }
 
    //safely update your user interface here
 }
 
 ```
 */
open class DispatchGuard {
    private var semaphore:DispatchSemaphore
   
    //Create a DispatchGuard with the number of threads you want to allow simultaneous access.
    init(value:Int = 1) {
        semaphore = DispatchSemaphore(value: value)
    }
    
    /**
     Attempt to enter the guard.
     
     - Returns: True if entry allowed, false if not
     
     - Note: If this methods returns true you must call exit() to free the guard statement
     */
    func enter() -> Bool {
        return semaphore.wait(timeout: .now()) == .success
    }
    
    ///Exit the guard statement. This call must be balanced with successful calls to enter.
    func exit() {
        semaphore.signal()
    }
}

/**
 Class to wrap common use case of a DispatchGuard into a RAII style pattern.
 
 ```
 let uiGuard:DispatchGuard = DispatchGuard()
 
 func updateUI() {
     let custodian = DispatchGuardCustodian(uiGuard)
     guard custodian.acquired else {
         return
     }
 
     //safely update your user interface here
 }
 
 ```
 */
open class DispatchGuardCustodian {
    fileprivate var dispatchGuard:DispatchGuard
    fileprivate(set) public var acquired:Bool
    
    init(_ dispatchGuard:DispatchGuard) {
        self.dispatchGuard = dispatchGuard
        self.acquired = self.dispatchGuard.enter()
    }
    
    deinit {
        if self.acquired {
            self.dispatchGuard.exit()
        }
    }
}
