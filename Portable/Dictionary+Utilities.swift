//
//  Dictionary+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/27/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        pairs.forEach { (key,value) in
            self[key] = value
        }
    }
    
    func mapPairs<OutKey: Hashable, OutValue>( transform: (Element) throws -> (OutKey, OutValue)) rethrows -> [OutKey: OutValue] {
        return Dictionary<OutKey, OutValue>(try map(transform))
    }
    
    func filterPairs(includeElement: (Element) throws -> Bool) rethrows -> [Key: Value] {
        return Dictionary(try filter(includeElement))
    }

    mutating func union(_ dictionary: Dictionary) {
        dictionary.forEach {
            self.updateValue($1, forKey: $0)
        }
    }

    func dictionaryAsUnionOf(_ dictionary: Dictionary) -> Dictionary {
        var result = dictionary
        result.union(self)
        return dictionary
    }
}
