//
//  MulticastDelegate.swift
//  swiftlets
//
//  Created by Frank Vernon on 9/6/20.
//  Copyright © 2020 Frank Vernon. All rights reserved.
//
// Based on: http://www.gregread.com/2016/02/23/multicast-delegates-in-swift/

import Foundation

open class MulticastDelegate <T> {
    private var delegates: [DelegateHolder]
    
    public func add(delegate: T) {
        delegates.append(DelegateHolder(value: delegate as AnyObject))
    }
    
    public func remove(delegate: T) {
        let object = delegate as AnyObject
        delegates.removeAll() { $0.value === object }
    }
    
    public func announce(invocation: (T) -> ()) {
        //by working on a slice of the entire array we can
        // remove dead delegates at will
        delegates.fullSlice().forEach { (wrapped) in
            guard let delegate = wrapped.value as? T else {
                remove(delegate: wrapped.value as! T)
                return
            }
            
            invocation(delegate)
        }
    }
    
    public init() {
        delegates = []
    }
}

public func += <T: AnyObject> (left: MulticastDelegate<T>, right: T) {
    left.add(delegate: right)
}

public func -= <T: AnyObject> (left: MulticastDelegate<T>, right: T) {
    left.remove(delegate: right)
}

fileprivate class DelegateHolder {
    weak var value: AnyObject?
    
    init(value: AnyObject) {
        self.value = value
    }
}
