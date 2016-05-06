//
//  String+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/6/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension String {
    mutating func appendString(string: String) {
        self = self + string
    }
}

