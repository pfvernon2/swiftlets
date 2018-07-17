//
//  CommandLine+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/16/18.
//  Copyright © 2018 Frank Vernon. All rights reserved.
//

import Foundation

extension CommandLine {
    public static func flagIndex(flag: String) -> Int? {
        return flagIndex(aliases: [flag])
    }
    
    public static func flagIndex(aliases: [String]) -> Int? {
        return CommandLine.arguments.firstIndex(where:{aliases.contains($0)});
    }

    public static func flagExists(flag: String) -> Bool {
        return flagExists(aliases: [flag])
    }
    
    public static func flagExists(aliases: [String]) -> Bool {
        return flagIndex(aliases: aliases) != nil;
    }

    public static func flagValues(flag: String) -> [String]? {
        return flagValues(aliases: [flag])
    }

    public static func flagValues(aliases: [String]) -> [String]? {
        guard var flag = flagIndex(aliases: aliases) else {
            return nil;
        }
        
        guard var nextFlag = CommandLine.arguments.index(after: <#T##Int#>)
        
        
        
    }
}
