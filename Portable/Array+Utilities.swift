//
//  Array+DHV.swift
//  WebResearch
//
//  Created by David Vernon on 6/5/16.
//  Copyright © 2016 David Vernon. All rights reserved.
//

import Foundation

extension Array {
    
    /**
     Move an element of an array to another index position.
     
     - parameters:
         - fromIndex: The index of an element in the array.
         - toIndex: The index of a position in the array to which to move the element
     */

    public mutating func moveElement(fromIndex fromIndex:Int, toIndex:Int) {
        self.insert(removeAtIndex(fromIndex), atIndex: toIndex)
    }
    
    /**
     Return a copy of an array with an element moved to another index position.
     
     - parameters:
         - fromIndex: The index of an element in the array.
         - toIndex: The index of a position in the array to which to move the element
     */

    public func arrayWithElementMoved(fromIndex fromIdex:Int, toIndex:Int) -> Array {
        var result = self
        result.moveElement(fromIndex: fromIdex, toIndex: toIndex)
        return result
    }
}

extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        if let index = indexOf({ $0 == object }) {
            removeAtIndex(index)
        }
    }
}
