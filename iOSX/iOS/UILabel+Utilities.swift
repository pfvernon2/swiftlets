//
//  UILabel+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/16/20.
//  Copyright © 2020 Frank Vernon. All rights reserved.
//

import UIKit

///Tirivial protocol to allow views to hide themselves when unused in the UI
public protocol SelfHiding {
    func hideIfEmpty()
}

extension UIImageView: SelfHiding {
    public func hideIfEmpty() {
        self.isHidden = self.image == nil
    }
}

extension UILabel: SelfHiding {
    public func hideIfEmpty() {
        isHidden = text?.isEmpty ?? true
    }
}

public extension UILabel {
    func toUpper() {
        text = text?.uppercased()
    }
    
    func toLower() {
        text = text?.lowercased()
    }
}

