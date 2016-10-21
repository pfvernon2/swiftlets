//
//  Dictionary+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/27/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension Dictionary {
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
