//
//  UIView+Constraints.swift
//  Apple Maps Demo
//
//  Created by Frank Vernon on 4/21/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIView {
    
    /**
     Add a subview and make it conform to our size.
     
     This is handy for programatically adding views to IB layouts.
     
     - parameters:
         - view: The view to make subview
     */
    func addSubViewAndMakeConform(view:UIView) {
        addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        let centerX = NSLayoutConstraint(item:view,
                                         attribute:.CenterX,
                                         relatedBy:.Equal,
                                         toItem:self,
                                         attribute:.CenterX,
                                         multiplier:1.0,
                                         constant:0.0);
        self.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item:view,
                                         attribute:.CenterY,
                                         relatedBy:.Equal,
                                         toItem:self,
                                         attribute:.CenterY,
                                         multiplier:1.0,
                                         constant:0.0);
        self.addConstraint(centerY)
        
        let width = NSLayoutConstraint(item:view,
                                       attribute:.Width,
                                       relatedBy:.Equal,
                                       toItem:self,
                                       attribute:.Width,
                                       multiplier:1.0,
                                       constant:0.0);
        self.addConstraint(width)
        
        let height = NSLayoutConstraint(item:view,
                                        attribute:.Height,
                                        relatedBy:.Equal,
                                        toItem:self,
                                        attribute:.Height,
                                        multiplier:1.0,
                                        constant:0.0);
        self.addConstraint(height)
    }
    
    func addSubViewAndCenter(view:UIView) {
        addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        let centerX = NSLayoutConstraint(item:view,
                                         attribute:.CenterX,
                                         relatedBy:.Equal,
                                         toItem:self,
                                         attribute:.CenterX,
                                         multiplier:1.0,
                                         constant:0.0);
        self.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item:view,
                                         attribute:.CenterY,
                                         relatedBy:.Equal,
                                         toItem:self,
                                         attribute:.CenterY,
                                         multiplier:1.0,
                                         constant:0.0);
        self.addConstraint(centerY)
    }
    
    func constrainToCurrentSize() {
        let width = NSLayoutConstraint(item:self,
                                       attribute:.Width,
                                       relatedBy:.Equal,
                                       toItem:nil,
                                       attribute:.NotAnAttribute,
                                       multiplier:1.0,
                                       constant:bounds.width);
        self.addConstraint(width)
        
        let height = NSLayoutConstraint(item:self,
                                        attribute:.Height,
                                        relatedBy:.Equal,
                                        toItem:nil,
                                        attribute:.NotAnAttribute,
                                        multiplier:1.0,
                                        constant:bounds.height);
        self.addConstraint(height)
    }
    
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
    
    func minDimension() -> CGFloat{
        return min(self.bounds.width, self.bounds.height)
    }
    
    func indexInSuperview() -> Int {
        if let index = self.superview?.subviews.indexOf(self) {
            return index
        } else {
            return -1
        }
    }
    
    func moveToFront() {
        self.superview?.bringSubviewToFront(self)
    }
    
    func moveToBack() {
        self.superview?.sendSubviewToBack(self)
    }

    func moveForward() {
        let index:Int = self.indexInSuperview()
        guard index > 0 && index <= self.superview?.subviews.count else {
            return
        }
        
        self.superview?.exchangeSubviewAtIndex(index, withSubviewAtIndex: index + 1)
    }

    func moveBackward() {
        let index:Int = self.indexInSuperview()
        guard index > 0 else {
            return
        }
        
        self.superview?.exchangeSubviewAtIndex(index, withSubviewAtIndex: index - 1)
    }

    func swapOrderWithView(otherView:UIView) {
        let myIndex = self.indexInSuperview()
        guard myIndex > 0 else {
            return
        }
        
        let otherIndex = otherView.indexInSuperview()
        guard otherIndex > 0 else {
            return
        }
        
        self.superview?.exchangeSubviewAtIndex(myIndex, withSubviewAtIndex: otherIndex)
    }
}
