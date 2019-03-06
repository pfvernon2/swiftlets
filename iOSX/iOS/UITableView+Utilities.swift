//
//  UITableView+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 3/6/19.
//  Copyright © 2019 Frank Vernon. All rights reserved.
//

import Foundation
import UIKit

///Trivial UITableViewCell subclass that configures itself as hidden on creation
/// This is *very* useful for gracefully handling the return of an 'empty' cell from cellForRowAtIndexPath calls
/// Don't forget to register the class with your table first!
public class HiddenTableViewCell: UITableViewCell {
    static let reuseIdentifier:String = "com.cyberdev.UITableViewCell.HiddenTableViewCell"

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isHidden = true
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.isHidden = true
    }
}

