//
//  UIView+Constraints.swift
//  Apple Maps Demo
//
//  Created by Frank Vernon on 4/21/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIView {
    
    func copyConstraintsToView(destinationView:UIView) {
        for constraint:NSLayoutConstraint in self.superview!.constraints {
            if constraint.firstItem.isEqual(self) {
                self.superview?.addConstraint(NSLayoutConstraint(item: destinationView, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: constraint.secondItem, attribute: constraint.secondAttribute, multiplier: constraint.multiplier, constant: constraint.constant))
            } else if constraint.secondItem != nil && constraint.secondItem!.isEqual(self) {
                self.superview?.addConstraint(NSLayoutConstraint(item: constraint.firstItem, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: destinationView, attribute: constraint.secondAttribute, multiplier: constraint.multiplier, constant: constraint.constant))
            }
        }
    }
    
    func substitueViewWithView(destinationView:UIView) {
        //add new view right behind us
        if let mySuperView = self.superview {
            mySuperView.insertSubview(destinationView, belowSubview:self)
            
            //copy configuration
            destinationView.frame = self.frame
            destinationView.sizeToFit()
            destinationView.translatesAutoresizingMaskIntoConstraints = false
            self.copyConstraintsToView(destinationView)
            
            //remove ourselves
            self.removeFromSuperview()
            
            //force layout adjustments
            mySuperView.layoutIfNeeded()
        }
    }
    
}
