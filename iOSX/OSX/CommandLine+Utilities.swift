//
//  CommandLine+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/16/18.
//  Copyright © 2018 Frank Vernon. All rights reserved.
//

import Foundation

private let FLAG_TOKEN:String = "-"

extension CommandLine {
    ///Returns the index of the flag in the arguments, nil if not found
    public static func flagIndex(flag: String) -> Int? {
        return flagIndex(aliases: [flag])
    }
    
    ///Returns the index of the first alias found in the arguments, nil if none found
    public static func flagIndex(aliases: Set<String>) -> Int? {
        return CommandLine.arguments.firstIndex(where:{aliases.contains($0)});
    }
    
    ///Returns true if the flag is found in the arguments
    public static func flagExists(flag: String) -> Bool {
        return flagExists(aliases: [flag])
    }
    
    ///Returns true if any of the flag aliases are found in the arguments
    public static func flagExists(aliases: Set<String>) -> Bool {
        return flagIndex(aliases: aliases) != nil;
    }
    
    ///Fetch the slice of arguments associated with a flag
    /// Returns nil if flag not found
    public static func flagValues(flag: String) -> ArraySlice<String>? {
        return flagValues(aliases: [flag])
    }
    
    ///Fetch the slice of arguments associated with a set of flag aliases
    /// Returns nil if none of the aliases are found
    public static func flagValues(aliases: Set<String>) -> ArraySlice<String>? {
        guard let flag = flagIndex(aliases: aliases) else {
            return nil;
        }
        
        var slice = CommandLine.arguments[flag...].dropFirst()        
        if let nextFlag = slice.firstIndex(where: {$0.hasPrefix(FLAG_TOKEN)}) {
            slice = slice.dropLast(slice.distance(from: nextFlag, to: slice.endIndex))
        }
        
        return slice
    }
    
    ///Returns the set of flags in the arguments which are not present in the set of expected flags
    /// This is a utility method to test for unexpected flags on the command line.
    public static func findUnknown(expected: Set<String>) -> Set<String> {
        return CommandLine.allFlags.subtracting(expected)
    }
    
    ///Returns the set of flags in the arguments which are not present in the set of required flags
    /// This is a utility method to test for the presence of required flags on the command line.
    public static func findMissing(required: Set<String>) -> Set<String> {
        return required.subtracting(CommandLine.allFlags)
    }
    
    ///Returns slice of arguments up to the first flag
    /// This a utility method to access any non-flag related parameters that appear at the beginning of the list
    public static func head() -> ArraySlice<String> {
        guard let firstFlag = CommandLine.arguments.firstIndex(where: {$0.hasPrefix(FLAG_TOKEN)}) else {
            return CommandLine.arguments[..<CommandLine.arguments.endIndex].dropFirst()
        }
        return CommandLine.arguments[..<firstFlag].dropFirst()
    }
    
    ///Returns slice of arguments after the last flag
    /// This a utility method to access any non-flag related parameters that appear at the end of the list
    public static func tail() -> ArraySlice<String> {
        guard let lastFlag = CommandLine.arguments.lastIndex(where: {$0.hasPrefix(FLAG_TOKEN)}) else {
            return CommandLine.arguments[..<CommandLine.arguments.endIndex].dropFirst()
        }
        return CommandLine.arguments[lastFlag...].dropFirst()
    }
    
    ///Returns the set of all flags found in the arguments.
    /// Order is not guaranteed, duplicates will be removed.
    public static var allFlags: Set<String> {
        get {
            return Set(CommandLine.arguments.filter({$0.hasPrefix(FLAG_TOKEN)}))
        }
    }
}
