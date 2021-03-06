//
//  NSData+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 4/30/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension Data {
    ///Hex representation of the bytes in upper case hex characters
    ///
    /// - Note: You can call lowercased() on the result if you prefer lowercase.
    func hexRepresentation() -> String {
        let hexDigits = Array("0123456789ABCDEF".utf16)
        var chars: [unichar] = []
        chars.reserveCapacity(2 * count)
        for byte in self {
            chars.append(hexDigits[Int(byte / 16)])
            chars.append(hexDigits[Int(byte % 16)])
        }
        return String(utf16CodeUnits: chars, count: chars.count)
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

//MARK: - Hashing

import CryptoKit

extension Data {
    func sha256() -> String {
        return SHA256.hash(data: self).description
    }
}
