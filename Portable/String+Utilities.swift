//
//  String+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/6/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

public extension String {
    mutating func appendString(_ string: String) {
        self = self + string
    }
    
    mutating func truncateMiddle(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateMiddle replacement value")) {
        if count > maxCharacterCount {
            replaceSubrange(index(startIndex, offsetBy: maxCharacterCount/2)..<index(startIndex, offsetBy: count-maxCharacterCount/2), with: replacement)
        }
    }
    
    mutating func truncateTail(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateTail replacement value")) {
        if count > maxCharacterCount {
            replaceSubrange(index(startIndex, offsetBy: maxCharacterCount)..., with: replacement)
        }
    }
    
    mutating func truncateHead(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateHead replacement value")) {
        if count > maxCharacterCount {
            replaceSubrange(..<index(startIndex, offsetBy: count - maxCharacterCount), with: replacement)
        }
    }
    
    func stringByAppendingString(_ string: String) -> String {
        var result = self
        result.appendString(string)
        return result
    }
    
    func stringByTruncatingMiddle(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateMiddle replacement value")) -> String {
        var result = self
        result.truncateMiddle(maxCharacterCount, replacement: replacement)
        return result
    }
    
    func stringByTruncatingTail(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateTail replacement value")) -> String {
        var result = self
        result.truncateTail(maxCharacterCount, replacement: replacement)
        return result
    }
    
    func stringByTruncatingHead(_ maxCharacterCount:Int, replacement:String = NSLocalizedString("…", comment: "String.truncateHead replacement value")) -> String {
        var result = self
        result.truncateHead(maxCharacterCount, replacement: replacement)
        return result
    }
    
    mutating func strip(charactersInSet characterSet:CharacterSet) {
        self = self.components(separatedBy: characterSet).joined()
    }
    
    func stringByStripping(charactersInSet characterSet:CharacterSet) -> String {
        var result = self
        result.strip(charactersInSet: characterSet)
        return result
    }
    
    mutating func trimSuffix(_ suffix: String) {
        if hasSuffix(suffix) {
            removeSubrange(index(endIndex, offsetBy: -(suffix.count))...)
        }
    }
    
    mutating func trimPrefix(_ prefix: String) {
        if hasPrefix(prefix) {
            removeSubrange(..<index(startIndex, offsetBy: prefix.count))
        }
    }
    
    func stringByTrimmingSuffix(_ suffix: String) -> String {
        var result = self
        result.trimSuffix(suffix)
        return result
    }
    
    func stringByTrimmingPrefix(_ prefix: String) -> String {
        var result = self
        result.trimPrefix(prefix)
        return result
    }
    
    func stringByTrimmingWhiteSpace() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func isAllDigits() -> Bool {
        containsOnly(CharacterSet.decimalDigits)
    }
    
    func isAllHexDigits() -> Bool {
        self.uppercased().containsOnly(CharacterSet.hexCharacters)
    }
    
    func containsOnly(_ charset: CharacterSet) -> Bool {
        rangeOfCharacter(from: charset.inverted) == nil
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
        self.contains("@")
    }
    
    func isLikeIPAddress() -> Bool {
        isLikeIPV4Address() || isLikeIPV6Address();
    }
    
    //exactly four set of integers, in the range 0...255, separated by periods
    func isLikeIPV4Address() -> Bool {
        //tokenize on period, omit empty components for quick exclusion
        let components = self.split(separator: ".", omittingEmptySubsequences: true)
        guard components.count == 4 else {
            return false
        }
        
        //test components for valid numbers in the range 0...255
        if let _ = components.first(where: {UInt8($0) == nil}) {
            return false
        }
        
        return true
    }
    
    //set of up to eight (16 bit) hex values in the range 0...65535 separated by colons
    // edge cases:
    //  components with leading zeros may have only a two digit hex value
    //  components with a zero value can be represented by a single digit hex value: 0
    //  runs of components with zero values can be coalesced into a single empty component
    //  there can be at most one coalesced component
    func isLikeIPV6Address() -> Bool {
        //tokenize on colon, keep empty components so we can validate formatting
        let components = self.split(separator: ":", omittingEmptySubsequences: false)
        guard components.count <= 8 else {
            return false
        }
        
        //test for multiple empty components
        guard components.filter({$0.isEmpty}).count <= 1 else {
            return false
        }
        
        //test non-empty components for valid hex values in the range 0...65535
        if let _ = components.filter({!$0.isEmpty}).first(where: {UInt16($0, radix: 16) == nil}) {
            return false
        }
        
        return true
    }
    
    var isNotEmpty:Bool {
        !isEmpty
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
    
    var lines: [String] {
        return self.components(separatedBy: "\n")
    }
}

///Convert four char codes to/from strings
extension FourCharCode: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        guard value.utf16.count == 4 else {
            self = 0x3F3F3F3F // '????'
            return
        }
        self = value.utf16.reduce(0, {$0 << 8 + FourCharCode($1)});
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self = FourCharCode(stringLiteral: value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        self = FourCharCode(stringLiteral: value)
    }
    
    public init(_ value: String) {
        self = FourCharCode(stringLiteral: value)
    }
    
    public var string: String? {
        //convert to bytes ensuring correct endianess
        let bytes: [UInt8] = [
            UInt8(bigEndian & 0xFF),
            UInt8(bigEndian >> 8 & 0xFF),
            UInt8(bigEndian >> 16 & 0xFF),
            UInt8(bigEndian >> 24 & 0xFF)
        ]
        return String(bytes: bytes, encoding: .ascii)
    }
}

extension CharacterSet {
    public static var hexCharacters: CharacterSet = { CharacterSet(charactersIn: "1234567890ABCDEF") }()
}
