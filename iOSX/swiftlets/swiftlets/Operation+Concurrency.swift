//
//  Operation+Concurrency.swift
//  swiftlets
//
//  Created by Frank Vernon on 2/25/17.
//  Copyright © 2017 Frank Vernon. All rights reserved.
//

import Foundation

//MARK: - Operation extension

extension Operation {
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
    
    @objc private enum OperationState: Int {
        case ready, executing, finished
    }
    
    // MARK: - Properties
    
    private let stateQueue = DispatchQueue(label: "com.cyberdev.operation.state",
                                           attributes: .concurrent)
    
    private var _state = OperationState.ready
    @objc private dynamic var state: OperationState {
        get {
            return stateQueue.sync { _state }
        }
        
        set {
            willChangeValue(forKey: "state")
            stateQueue.sync(flags: .barrier) { _state = newValue }
            didChangeValue(forKey: "state")
        }
    }
    
    // MARK: Required Operation overrides
    
    public final override var isReady: Bool {
        return state == .ready && super.isReady
    }
    
    public final override var isExecuting: Bool {
        return state == .executing
    }
    
    public final override var isFinished: Bool {
        return state == .finished
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

//MARK: -

open class AsynchronousOperation: SynchronousOperation {
    public final override var isAsynchronous: Bool {
        return true
    }
}
