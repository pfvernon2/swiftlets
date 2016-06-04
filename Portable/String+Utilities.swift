//
//  String+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/6/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

public extension String {
    mutating public func appendString(string: String) {
        self = self + string
    }
    
    mutating public func truncateMiddle(maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateMiddle replacement value")) {
        let length = self.characters.count
        if length > maxCharacterCount {
            replaceRange(startIndex.advancedBy(maxCharacterCount/2)..<startIndex.advancedBy(length-maxCharacterCount/2), with: replacement)
        }
    }
    
    mutating public func truncateTail(maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateTail replacement value")) {
        let length = self.characters.count
        if length > maxCharacterCount {
            replaceRange(startIndex.advancedBy(maxCharacterCount)..<endIndex, with: replacement)
        }
    }
    
    mutating public func truncateHead(maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateHead replacement value")) {
        let length = self.characters.count
        if length > maxCharacterCount {
            replaceRange(startIndex..<startIndex.advancedBy(length - maxCharacterCount), with: replacement)
        }
    }
    
    public func stringByAppendingString(string: String) -> String {
        var result = self
        result.appendString(string)
        return result
    }
    
    public func stringByTruncatingMiddle(maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateMiddle replacement value")) -> String {
        var result = self
        result.truncateMiddle(maxCharacterCount, replacement: replacement)
        return result
    }
    
    public func stringByTruncatingTail(maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateTail replacement value")) -> String {
        var result = self
        result.truncateTail(maxCharacterCount, replacement: replacement)
        return result
    }
    
    public func stringByTruncatingHead(maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateHead replacement value")) -> String {
        var result = self
        result.truncateHead(maxCharacterCount, replacement: replacement)
        return result
    }
    
    public func length() -> Int {
        return self.characters.count
    }
    
    mutating public func trimSuffix(suffix: String) {
        if hasSuffix(suffix) {
            removeRange(endIndex.advancedBy(-(suffix.length())) ..< endIndex)
        }
    }
    
    mutating public func trimPrefix(prefix: String) {
        if hasPrefix(prefix) {
            removeRange(startIndex ..< startIndex.advancedBy(prefix.length()))
        }
    }
    
    public func stringByTrimmingSuffix(suffix: String) -> String {
        var result = self
        result.trimSuffix(suffix)
        return result
    }
    
    public func stringByTrimmingPrefix(prefix: String) -> String {
        var result = self
        result.trimPrefix(prefix)
        return result
    }
}

