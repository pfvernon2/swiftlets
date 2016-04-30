//
//  NSData+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 4/30/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension NSData {
    func hexRepresentation() -> String {
        let pointer = UnsafePointer<UInt8>(self.bytes)

        var result: String = String()
        for i in 0 ..< self.length {
            result += String(format: "%02.2X", pointer[i])
        }
        
        return result
    }
}
