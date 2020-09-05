//
//  Operation+Concurrency.swift
//  swiftlets
//
//  Created by Frank Vernon on 2/25/17.
//  Copyright © 2017 Frank Vernon. All rights reserved.
//

import Foundation

//MARK: - Operation extension

public extension Operation {
    func addDependencies(_ operations:[Operation]) {
        operations.forEach { (operation) in
            self.addDependency(operation)
        }
    }
    
    func removeDependencies(_ operations:[Operation]) {
        operations.forEach { (operation) in
            self.removeDependency(operation)
        }
    }
}

//MARK: -

/**
 Baseclass for implementing typical synchronous operation objects in Swift. This class,
 and it's sibling AsynchronousOperation, deal with the unfortunate ugliness of the
 KVO and state machine requirements of the Operation class.
 
 To use:
 - Implement execute() in your subclass to perform the work of your operation.
 - finish() must be called upon completion, or after cancellation.
 */
open class SynchronousOperation: Operation {
    // MARK: - Enumeration
    
    private enum OperationState: Int {
        case ready, executing, finished
    }
    
    // MARK: - Properties
    
    private let stateQueue = DispatchQueue(label: "com.cyberdev.operation.state",
                                           attributes: .concurrent)
    
    private var _state = OperationState.ready
    private var state: OperationState {
        get {
            stateQueue.sync { _state }
        }
        
        set {
            willChangeValue(forKey: "state")
            stateQueue.sync(flags: .barrier) { _state = newValue }
            didChangeValue(forKey: "state")
        }
    }
    
    // MARK: Required Operation overrides
    
    public final override var isReady: Bool {
        state == .ready && super.isReady
    }
    
    public final override var isExecuting: Bool {
        state == .executing
    }
    
    public final override var isFinished: Bool {
        state == .finished
    }
    
    // MARK: - KVO
    
    override open class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        
        switch key {
        case "isReady",
             "isExecuting",
             "isFinished":
            keyPaths = ["state"]
        default:
            break
        }
        
        return keyPaths
    }
    
    // MARK: - Operation overrides
    
    public override final func start() {
        super.start()
        
        guard !isCancelled else {
            finish()
            return
        }
        
        state = .executing
        execute()
    }
    
    /// Subclasses must override this method to perform their work.
    open func execute() {
        //finish must always be called when returning from execute
        defer {
            finish()
        }
        
        fatalError("Subclasses of SynchronousOperation must implement execute().")
    }

    /// This method must be called when execute is exiting.
    public final func finish() {
        state = .finished
    }
}

//MARK: - AsynchronousOperation

/**
 Baseclass for implementing typical asynchronous operation objects in Swift. This class,
 and it's sibling SynchronousOperation, deal with the unfortunate ugliness of the
 KVO and state machine requirements of the Operation class.
 
 - note: The 'isAsynchronous' flag being managed here is used only in cases where
 the Operation is not being passed to an OperationQueue. There is no need to prefer
 this class over SynchronousOperation when an OperationQueue is used.
 
 To use:
 - Implement execute() in your subclass to perform the work of your operation.
 - finish() must be called upon completion, or after cancellation.
 */
open class AsynchronousOperation: SynchronousOperation {
    public final override var isAsynchronous: Bool {
        true
    }
}
