//
//  NSData+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 4/30/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension Data {
    //Convert data to string with hexadecimal encoding
    func hexRepresentation() -> String {
        enumerated().map { (_, element) -> String in
            String(format: "%02.2X", element)
        }.joined()
    }
    
    //Convert string to data with utf8 encoding and append to current data
    @discardableResult mutating func appendStringAsUTF8(_ string: String) -> Bool {
        guard let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true) else {
            return false
        }
        append(data)
        return true
    }
}
