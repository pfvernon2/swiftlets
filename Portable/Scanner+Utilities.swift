//
//  Scanner+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/1/17.
//  Copyright © 2017 Frank Vernon. All rights reserved.
//

import Foundation

extension Scanner {
    func scanInteger() -> Int? {
        var result: Int = Int()
        guard scanInt(&result) else {
            return nil
        }
        
        return result
    }
    
    func scanInt32() -> Int32? {
        var result: Int32 = Int32()
        guard scanInt32(&result) else {
            return nil
        }
        
        return result
    }
    
    func scanInt64() -> Int64? {
        var result: Int64 = Int64()
        guard scanInt64(&result) else {
            return nil
        }
        
        return result
    }
    
    func scanUnsignedLongLong() -> UInt64? {
        var result: UInt64 = UInt64()
        guard scanUnsignedLongLong(&result) else {
            return nil
        }
        
        return result
    }
    
    func scanFloat() -> Float? {
        var result: Float = Float()
        guard scanFloat(&result) else {
            return nil
        }
        
        return result
    }
    
    func scanDouble() -> Double? {
        var result: Double = Double()
        guard scanDouble(&result) else {
            return nil
        }
        
        return result
    }
    
    func scanHexInt32() -> UInt32? {
        var result: UInt32 = UInt32()
        guard scanHexInt32(&result) else {
            return nil
        }
        
        return result
    }
    
    func scanHexInt64() -> UInt64? {
        var result: UInt64 = UInt64()
        guard scanHexInt64(&result) else {
            return nil
        }
        
        return result
    }
    
    func scanHexFloat() -> Float? {
        var result: Float = Float()
        guard scanHexFloat(&result) else {
            return nil
        }
        
        return result
    }
    
    func scanHexDouble() -> Double? {
        var result: Double = Double()
        guard scanHexDouble(&result) else {
            return nil
        }
        
        return result
    }
    
    func scanDecimal() -> Decimal? {
        var result: Decimal = Decimal()
        guard scanDecimal(&result) else {
            return nil
        }
        
        return result
    }
    
    func scanCharacters(from set: CharacterSet) -> String? {
        var result: NSString?
        guard scanCharacters(from: set, into: &result) else {
            return nil
        }
        
        return result as String?
    }
    
    func scanUpToCharacters(from set: CharacterSet) -> String? {
        var result: NSString?
        guard scanUpToCharacters(from: set, into: &result) else {
            return nil
        }
        
        return result as String?
    }
    
    func scanString(_ string: String) -> String? {
        var result: NSString?
        guard scanString(string, into: &result) else {
            return nil
        }
        
        return result as String?
    }
    
    func scanUpTo(_ string: String) -> String? {
        var result: NSString?
        guard scanUpTo(string, into: &result) else {
            return nil
        }
        
        return result as String?
    }
}
