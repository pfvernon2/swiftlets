//
//  Formatting.swift
//  Apple Maps Demo
//
//  Created by Frank Vernon on 4/23/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation
import UIKit

extension Int {
    /**
     - note: This is *not* localized! Mostly useful for debug output. See NSNumberFormatter
     
     Example:
     ~~~
     1.format("04") -> "0001"
     ~~~
     */
    func format(formatString: String) -> String {
        return String(format: "%\(formatString)d", self)
    }
    
    static func randomNumberFrom(from: Range<Int>) -> Int {
        return from.startIndex + Int(arc4random_uniform(UInt32(from.endIndex - from.startIndex)))
    }
}

extension Double {
    /**
     - note: This is *not* localized! Mostly useful for debug output. See NSNumberFormatter

     Examples:
     ~~~
    0.12345.format("0.2") -> "0.12"
    0.12345.format(".4") -> ".1234"
    0.12345.format("0.0") -> "0"
     ~~~
    */
    func format(formatString: String) -> String {
        return String(format: "%\(formatString)f", self)
    }
}

extension Float {
    /**
     - note: This is *not* localized! Mostly useful for debug output. See NSNumberFormatter

     Examples:
     ~~~
     0.12345.format("0.2") -> "0.12"
     0.12345.format(".4") -> ".1234"
     0.12345.format("0.0") -> "0"
     ~~~
     */
    func format(formatString: String) -> String {
        return String(format: "%\(formatString)f", self)
    }
}

extension CGRect {
    func description() -> String {
        return "x:\(origin.x), y:\(origin.y), width:\(size.width), height:\(size.height)"
    }
}