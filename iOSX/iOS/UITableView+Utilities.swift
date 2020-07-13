//
//  UITableView+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 3/6/19.
//  Copyright © 2019 Frank Vernon. All rights reserved.
//

import Foundation
import UIKit

//Protocol to aid in identifying and registering reusable cells
public protocol ReuseIdentifiable: class {
    static var reuseIdentifier: String { get }
    
    static func register(with table: UITableView)
    static func register(with collection: UICollectionView)
}

public extension ReuseIdentifiable {
    static var reuseIdentifier: String {
        String(describing: self)
    }
    
    static func register(with table: UITableView) {
        table.register(self, forCellReuseIdentifier: self.reuseIdentifier)
    }
    
    static func register(with collection: UICollectionView) {
        collection.register(self, forCellWithReuseIdentifier: self.reuseIdentifier)
    }
}

///Trivial UITableViewCell subclass that configures itself as hidden on creation
/// This is useful for gracefully handling the return of an 'empty' cell from cellForRowAtIndexPath calls
/// Don't forget to register the class with your table first!
public class HiddenTableViewCell: UITableViewCell, ReuseIdentifiable {
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isHidden = true
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.isHidden = true
    }
}
