//
//  Formatting.swift
//  swiftlets
//
//  Created by Frank Vernon on 4/23/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension Int {
    /**
     - note: This is *not* localized! Mostly useful for debug output. See NSNumberFormatter
     
     Example:
     ~~~
     1.format("04") -> "0001"
     ~~~
     */
    func format(_ formatString: String) -> String {
        String(format: "%\(formatString)d", self)
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
    func format(_ formatString: String) -> String {
        String(format: "%\(formatString)f", self)
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
    func format(_ formatString: String) -> String {
        String(format: "%\(formatString)f", self)
    }
}

extension CGRect {
    func description() -> String {
        "x:\(origin.x), y:\(origin.y), width:\(size.width), height:\(size.height)"
    }
}
