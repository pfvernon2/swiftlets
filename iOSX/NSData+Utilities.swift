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
        let pointer = (self as NSData).bytes.bindMemory(to: UInt8.self, capacity: self.count)

        var result: String = String()
        for i in 0 ..< self.count {
            result += String(format: "%02.2X", pointer[i])
        }
        
        return result
    }
}

extension NSMutableData {
    func appendStringAsUTF8(_ string: String) -> Bool {
        if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true) {
            append(data)
            return true
        }
        return false
    }
}
