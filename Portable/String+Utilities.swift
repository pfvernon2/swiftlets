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
        let length = self.characters.count
        if length > maxCharacterCount {
            replaceSubrange(index(startIndex, offsetBy: maxCharacterCount/2)..<index(startIndex, offsetBy: length-maxCharacterCount/2), with: replacement)
        }
    }
    
    mutating public func truncateTail(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateTail replacement value")) {
        let length = self.characters.count
        if length > maxCharacterCount {
            replaceSubrange(index(startIndex, offsetBy: maxCharacterCount)..<endIndex, with: replacement)
        }
    }
    
    mutating public func truncateHead(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateHead replacement value")) {
        let length = self.characters.count
        if length > maxCharacterCount {
            replaceSubrange(startIndex..<index(startIndex, offsetBy: length - maxCharacterCount), with: replacement)
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

    public func length() -> Int {
        return self.characters.count
    }
    
    mutating public func trimSuffix(_ suffix: String) {
        if hasSuffix(suffix) {
            removeSubrange(index(endIndex, offsetBy: -(suffix.length())) ..< endIndex)
        }
    }
    
    mutating public func trimPrefix(_ prefix: String) {
        if hasPrefix(prefix) {
            removeSubrange(startIndex ..< index(startIndex, offsetBy: prefix.length()))
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
        if let _:Range = rangeOfCharacter(from: nonNumbers) {
            return false
        } else {
            return true
        }
    }

    func isLikeZipCode() -> Bool {
        return self.characters.count == 5 && self.isAllDigits()
    }

    func isEmailAddress() -> Bool {
        //Per Apple recommendation WWDC16 - https://developer.apple.com/videos/play/wwdc2016/714/
        return self.contains("@")
    }

    var isNotEmpty:Bool {
        return !isEmpty
    }

}

