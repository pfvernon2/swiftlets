//
//  Set+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 10/2/20.
//  Copyright © 2020 Frank Vernon. All rights reserved.
//

import Foundation

public extension Set {
    ///Utility method to create non-empty interesection when self or other
    /// may be empty. Additionally other may be nil for convenience.
    mutating func createIntersection(_ other: Self?) {
        guard let other = other else {
            return
        }
        
        //if we're empty take other
        if isEmpty {
            formUnion(other)
        }
        
        //if other is not empty then intersect
        else if !other.isEmpty {
            formIntersection(other)
        }
    }
}

