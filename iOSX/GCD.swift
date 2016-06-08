//
//  GCD.swift
//  Segues
//
//  Created by Frank Vernon on 11/24/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import Foundation

//MARK: - Constants

///Swift wrapper of gcd priority constants.
/// Maps directly to GCD values according to Swift enumeration naming conventions.
public enum GCDQueuePriority {
    case High
    case Default
    case Low
    case Background
    
    public func rawValue() -> dispatch_queue_priority_t {
        switch self {
        case .High:
            return DISPATCH_QUEUE_PRIORITY_HIGH
            
        case .Default:
            return DISPATCH_QUEUE_PRIORITY_DEFAULT
            
        case .Low:
            return DISPATCH_QUEUE_PRIORITY_LOW
            
        case .Background:
            return DISPATCH_QUEUE_PRIORITY_BACKGROUND
        }
    }
}

///Swift wrapper of gcd queue attributes.
/// Maps directly to GCD values according to Swift enumeration naming conventions.
public enum GCDQueueAttribute {
    case Serial
    case Concurrent
    
    public func rawValue() -> dispatch_queue_attr_t! {
        switch self {
        case .Serial:
            return DISPATCH_QUEUE_SERIAL
            
        case .Concurrent:
            return DISPATCH_QUEUE_CONCURRENT
        }
    }
}

///Swift wrapper of GCD. See documentation of classes.
public class gcd {
    
    //MARK: - Queue Subclasses

    /**
    Class representing GCD main queue (Serial)
    ````
    gcd.mainQueue().async { () -> () in
     ...
    }
    ````
    */
    public class main: serial {
        public init() {
            super.init(queue: dispatch_get_main_queue())
        }
    }
    
    /**
    Class representing GCD global queue (Concurrent)
    ````
    gcd.globalQueue().sync { () -> () in
     ...
    }
    ````
    */
    public class global: concurrent {
        public init(priority:GCDQueuePriority = .Default) {
            super.init(queue: dispatch_get_global_queue(priority.rawValue(), 0))
        }
    }

    /**
    Class representing a GCD serial queue with optional label
    ````
    let queue:gcd.serialQueue = gcd.serialQueue(label: "com.cyberdev.queue.serial")
    queue.barrier { () -> () in
     ...
    }
    ````
    */
    public class serial: queue {
        public init(label:String? = nil) {
            super.init(attribute: .Serial, label: label)
        }
        
        private override init(queue:dispatch_queue_t) {
            super.init(queue: queue)
        }
    }
    
    /**
    Class representing a GCD concurrent queue with optional label
    ````
    let queue:gcd.concurrentQueue = gcd.concurrentQueue(label: "com.cyberdev.queue.concurrent")
    queue.after(3.0) { () -> () in
     ...
    }
    ````
    */
    public class concurrent: queue {
        public init(label:String? = nil) {
            super.init(attribute: .Concurrent, label: label)
        }
        
        private override init(queue:dispatch_queue_t) {
            super.init(queue: queue)
        }
    }

    //MARK: - Queue Baseclass

    ///Base class representing a GCD dispatch queue. You probably want to use one of the subclasses.
    public class queue {
        private var queue:dispatch_queue_t;
        
        public var label:String {
            get {
                let label:String = String.fromCString(dispatch_queue_get_label(queue))!
                return label
            }
        }
        
        internal init(queue:dispatch_queue_t) {
            self.queue = queue
        }

        internal init(attribute:GCDQueueAttribute, label:String?) {
            self.queue = dispatch_queue_create(label ?? "", attribute.rawValue())
        }
        
        public func sync(closure:()->()) {
            dispatch_sync(queue, closure)
        }

        public func async(closure:()->()) {
            dispatch_async(queue, closure)
        }
        
        public func after(delay:NSTimeInterval, closure:()->()) {
            dispatch_after(gcd.timeIntervalToDispatchTime(delay), queue, closure)
        }
        
        public func suspend() {
            dispatch_suspend(queue)
        }
        
        public func resume() {
            dispatch_resume(queue)
        }
        
        public func apply(iterations:Int, closure:(Int)->()) {
            dispatch_apply(iterations, queue, closure)
        }
        
        public func barrier_sync(closure:()->()) {
            dispatch_barrier_sync(queue, closure)
        }
        
        public func barrier_async(closure:()->()) {
            dispatch_barrier_async(queue, closure)
        }
    }
    
    //MARK: - Group

    ///Class representing a GCD group
    public class group {
        private let group: dispatch_group_t = dispatch_group_create()
        
        public func enter() {
            dispatch_group_enter(group)
        }
        
        public func leave() {
            dispatch_group_leave(group)
        }
        
        public func wait(timeout: NSTimeInterval = Double.infinity) -> Bool {
            let interval:dispatch_time_t = gcd.timeIntervalToDispatchTime(timeout)
            return dispatch_group_wait(group, interval) == 0
        }
        
        public func async(queue:gcd.queue, closure:()->()) {
            dispatch_group_async(group, queue.queue, closure)
        }
        
        public func notify(queue:gcd.queue, closure:()->()) {
            dispatch_group_notify(group, queue.queue, closure)
        }
    }
    
    //MARK: - Semaphore
    
    ///Class representing a GCD semaphore
    public class semaphore {
        let semaphore:dispatch_semaphore_t?
        
        public init(counter:Int) {
            self.semaphore = dispatch_semaphore_create(counter);
        }
        
        public func signal() -> Bool {
            return dispatch_semaphore_signal(self.semaphore!) != 0
        }
        
        public func wait(timeout: NSTimeInterval = Double.infinity) -> Bool {
            let interval:dispatch_time_t = gcd.timeIntervalToDispatchTime(timeout)
            return dispatch_semaphore_wait(self.semaphore!, interval) == 0
        }
    }
    
    //MARK: - Singleton

    /**
     Wrapper class for the common singleton pattern
     
     ```
     private let setup:gcd.singleton = gcd.singleton()
     private func initEngine () {
        setup.executeOnce { () -> () in
            self.engine.initialize()
        }
     }
     ```
     */
    public class singleton {
        private var predicate:dispatch_once_t = 0;
        
        public func executeOnce(closure:()->()) {
            dispatch_once(&predicate, closure)
        }
    }
    
    //MARK: - Reader Writer

    /**
     Wrapper class for the common GCD reader writer pattern
     
     ```
     private let queue:gcd.readerWriter = gcd.readerWriter()
     private var _foo:String = "bar"
     public var foo {
        get {
            var result:String
            queue.read {
                result = _foo
             }
            return result
        }
        set(newValue) {
            queue.write {
                _foo = newValue
             }
         }
     }
     ```
     
     - note: See class readerWriterType for helper implementation.
     */

    public class readerWriter {
        private var queue:concurrent = concurrent()
        
        public func read(closure:()->()) {
            queue.sync {
                closure()
            }
        }
        
        public func write(closure:()->()) {
            queue.barrier_async { 
                closure()
            }
        }
    }
    
    //MARK: - Utility
    
    ///Utility method to convert NSTimeInterval to dispatch_time_t used by GCD
    private class func timeIntervalToDispatchTime(timeInterval:NSTimeInterval) -> dispatch_time_t {
        if timeInterval.isInfinite {
            return DISPATCH_TIME_FOREVER
        } else {
            return dispatch_time(DISPATCH_TIME_NOW, Int64(timeInterval * NSTimeInterval(NSEC_PER_SEC)))
        }
    }
    
    /**
     Utility method to simplify the common pattern of asynchronously performing an operation on a
     background queue followed by updating the UI on the main thread.
     
     ```
     gcd.backgroundUIOperation {
        //backgound work happens here
     } {
        //UI updates happen here
     }
     ```
     - parameters:
         - global: The closure to execute asynchronously in the global concurrent queue at default priority
         - main: The closure to execute asynchronously in the main serial queue
     */
    public class func backgroundUIOperation(global:()->(), main:()->()) {
        gcd.global().async { () -> () in
            global()
            gcd.main().async(main)
        }
    }
}

//MARK: - Helper Types

///Helper wrapper for common reader writer protected access of single variable
public class readerWriterType<T> {
    private var lock:gcd.readerWriter = gcd.readerWriter()
    private var _value:T? = nil
    public var value:T? {
        get {
            var result:T?
            lock.read { 
                result = self._value
            }
            return result
        }
        
        set (newElement) {
            lock.write { 
                self._value = newElement
            }
        }
    }
}

