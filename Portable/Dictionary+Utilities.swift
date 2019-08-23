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
        pairs.forEach {
            self[$0.0] = $0.1
        }
    }
    
    func mapPairs<OutKey, OutValue>( transform: (Element) throws -> (OutKey, OutValue)) rethrows -> [OutKey: OutValue] {
        Dictionary<OutKey, OutValue>(try map(transform))
    }
    
    func filterPairs(includeElement: (Element) throws -> Bool) rethrows -> [Key: Value] {
        Dictionary(try filter(includeElement))
    }
    
    mutating func union(_ dictionary: Dictionary) {
        dictionary.forEach {
            self.updateValue($0.1, forKey: $0.0)
        }
    }
    
    func dictionaryAsUnionOf(_ dictionary: Dictionary) -> Dictionary {
        var result = dictionary
        result.union(self)
        return dictionary
    }
}
