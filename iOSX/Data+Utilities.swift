//
//  NSData+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 4/30/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension Data {
    fileprivate static var hexDigits = Array("0123456789ABCDEF".utf16)

    ///Hex representation of the bytes in upper case hex characters
    func hexRepresentation() -> String {
        let chars = reduce(into: Array<unichar>()) {
            $0.append(Data.hexDigits[Int($1 / 16)])
            $0.append(Data.hexDigits[Int($1 % 16)])
        }
        return String(utf16CodeUnits: chars, count: chars.count)
    }
    
    ///Hex representation of the bytes in lower case hex characters
    func hexRepresentationLower() -> String {
        hexRepresentation().lowercased()
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
