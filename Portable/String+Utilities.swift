//
//  String+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/6/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

public extension String {
    mutating public func appendString(_ string: String) {
        self = self + string
    }
    
    mutating public func truncateMiddle(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateMiddle replacement value")) {
        if count > maxCharacterCount {
            replaceSubrange(index(startIndex, offsetBy: maxCharacterCount/2)..<index(startIndex, offsetBy: count-maxCharacterCount/2), with: replacement)
        }
    }
    
    mutating public func truncateTail(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateTail replacement value")) {
        if count > maxCharacterCount {
            replaceSubrange(index(startIndex, offsetBy: maxCharacterCount)..., with: replacement)
        }
    }
    
    mutating public func truncateHead(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateHead replacement value")) {
        if count > maxCharacterCount {
            replaceSubrange(..<index(startIndex, offsetBy: count - maxCharacterCount), with: replacement)
        }
    }
    
    public func stringByAppendingString(_ string: String) -> String {
        var result = self
        result.appendString(string)
        return result
    }
    
    public func stringByTruncatingMiddle(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateMiddle replacement value")) -> String {
        var result = self
        result.truncateMiddle(maxCharacterCount, replacement: replacement)
        return result
    }
    
    public func stringByTruncatingTail(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateTail replacement value")) -> String {
        var result = self
        result.truncateTail(maxCharacterCount, replacement: replacement)
        return result
    }
    
    public func stringByTruncatingHead(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateHead replacement value")) -> String {
        var result = self
        result.truncateHead(maxCharacterCount, replacement: replacement)
        return result
    }

    public mutating func strip(charactersInSet characterSet:CharacterSet) {
        self = self.components(separatedBy: characterSet).joined()
    }

    public func stringByStripping(charactersInSet characterSet:CharacterSet) -> String {
        var result = self
        result.strip(charactersInSet: characterSet)
        return result
    }
    
    mutating public func trimSuffix(_ suffix: String) {
        if hasSuffix(suffix) {
            removeSubrange(index(endIndex, offsetBy: -(suffix.count))...)
        }
    }
    
    mutating public func trimPrefix(_ prefix: String) {
        if hasPrefix(prefix) {
            removeSubrange(..<index(startIndex, offsetBy: prefix.count))
        }
    }
    
    public func stringByTrimmingSuffix(_ suffix: String) -> String {
        var result = self
        result.trimSuffix(suffix)
        return result
    }
    
    public func stringByTrimmingPrefix(_ prefix: String) -> String {
        var result = self
        result.trimPrefix(prefix)
        return result
    }

    func isAllDigits() -> Bool {
        let nonNumbers = CharacterSet.decimalDigits.inverted
        guard let _:Range = rangeOfCharacter(from: nonNumbers) else {
            return true
        }
        
        return false
    }

    func isLikeZipCode() -> Bool {
        //trivial case
        if self.count == 5 && self.isAllDigits() {
            return true
        }
        
        //zip+4
        else if self.count == 10 {
            let plusFours: [String] = self.split(separator: "-").map { String($0) }
            return plusFours.count == 2
                && plusFours[0].count == 5 && plusFours[0].isAllDigits()
                && plusFours[1].count == 4 && plusFours[1].isAllDigits()
        }
        
        return false
    }

    func isLikeEmailAddress() -> Bool {
        //Per Apple recommendation WWDC16 - https://developer.apple.com/videos/play/wwdc2016/714/
        return self.contains("@")
    }
    
    func isLikeIPV4Address() -> Bool {
        let components = self.split(separator: ".")
        guard components.count == 4 else {
            return false
        }
        
        if let _ = components.first(where: {(!String($0).isAllDigits()) || (UInt($0) ?? UInt.max > 255)}) {
            return false
        }
        
        return true
    }

    var isNotEmpty:Bool {
        return !isEmpty
    }

    func convertNSRange(range:NSRange) -> Range<String.Index>? {
        guard range.location != NSNotFound,
        let utfStart = utf16.index(utf16.startIndex, offsetBy: range.location, limitedBy: utf16.endIndex),
        let utfEnd = utf16.index(utfStart, offsetBy:range.length, limitedBy: utf16.endIndex),
        let start = String.Index(utfStart, within: self),
        let end = String.Index(utfEnd, within: self) else {
            return nil
        }
        
        return start ..< end
    }
    
    static func fourCCToString(_ value: FourCharCode) -> String {
        let utf16 = [
            UInt16((value >> 24) & 0xFF),
            UInt16((value >> 16) & 0xFF),
            UInt16((value >> 8) & 0xFF),
            UInt16((value & 0xFF)) ]
        return String(utf16CodeUnits: utf16, count: 4)
    }
}

