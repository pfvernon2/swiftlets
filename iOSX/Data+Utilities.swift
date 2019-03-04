//
//  NSData+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 4/30/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension Data {
    func hexRepresentation() -> String {
        var result: String = String()
        for byte in enumerated() {
            result += String(format: "%02.2X", byte.element)
        }
        
        return result
    }
    
    @discardableResult mutating func appendStringAsUTF8(_ string: String) -> Bool {
        guard let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true) else {
            return false
        }
        append(data)
        return true
    }
}
