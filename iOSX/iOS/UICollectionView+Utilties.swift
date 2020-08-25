//
//  UICollectionView+Utilties.swift
//  swiftlets
//
//  Created by Frank Vernon on 8/25/20.
//  Copyright © 2020 Frank Vernon. All rights reserved.
//

import Foundation
import UIKit

open class CollectionSection: Hashable {
    var id = UUID()
    
    public init() {
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: CollectionSection, rhs: CollectionSection) -> Bool {
        lhs.id == rhs.id
    }
}

