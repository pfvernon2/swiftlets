//
//  UITableView+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 3/6/19.
//  Copyright © 2019 Frank Vernon. All rights reserved.
//

import Foundation
import UIKit

///Protocol to aid in identifying and registering reusable cells
public protocol ReuseIdentifiable: AnyObject {
    static var reuseIdentifier: String { get }
}

public extension ReuseIdentifiable {
    static var reuseIdentifier: String {
        String(describing: self)
    }
}

public extension UITableView {
    func dequeueReusableCell<C: ReuseIdentifiable>(ofClass cell: C.Type, for indexPath: IndexPath) -> C {
        guard let cell = dequeueReusableCell(withIdentifier: C.reuseIdentifier, for: indexPath) as? C else {
            fatalError("UITableViewCell '\(String(describing: C.self))' not found")
        }
        
        return cell
    }
    
    func registerCell<C: ReuseIdentifiable>(ofClass cell: C.Type) {
        register(cell, forCellReuseIdentifier: C.reuseIdentifier)
    }
}

public extension UICollectionView {
    func dequeueReusableCell<C: ReuseIdentifiable>(ofClass cell: C.Type, for indexPath: IndexPath) -> C {
        guard let cell = dequeueReusableCell(withReuseIdentifier: C.reuseIdentifier, for: indexPath) as? C else {
            fatalError("UICollectionViewCell '\(String(describing: C.self))' not found")
        }
        
        return cell
    }
    
    func registerCell<C: ReuseIdentifiable>(ofClass cell: C.Type) {
        register(cell, forCellWithReuseIdentifier: C.reuseIdentifier)
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

public extension UITableView {
    func sizeHeaderToFit() {
        guard let header = tableHeaderView else {
            return
        }
        makeFit(header)
        tableHeaderView = header
    }
    
    func sizeFooterToFit() {
        guard let footer = tableFooterView else {
            return
        }
        makeFit(footer)
        tableFooterView = footer
    }
    
    private func makeFit(_ view: UIView) {
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        let height = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var frame = view.frame
        frame.size.height = height
        view.frame = frame
    }
}
