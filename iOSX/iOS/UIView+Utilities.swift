//
//  UIView+Constraints.swift
//  swiftlets
//
//  Created by Frank Vernon on 4/21/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


extension UIView {
    
    /**
     Add a subview and make it conform to our size.
     
     This is handy for programatically adding views to IB layouts.
     
     - parameters:
         - view: The view to make subview
     */
    func addSubViewAndMakeConform(_ view:UIView) {
        addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        let centerX = NSLayoutConstraint(item:view,
                                         attribute:.centerX,
                                         relatedBy:.equal,
                                         toItem:self,
                                         attribute:.centerX,
                                         multiplier:1.0,
                                         constant:0.0)
        self.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item:view,
                                         attribute:.centerY,
                                         relatedBy:.equal,
                                         toItem:self,
                                         attribute:.centerY,
                                         multiplier:1.0,
                                         constant:0.0)
        self.addConstraint(centerY)
        
        let width = NSLayoutConstraint(item:view,
                                       attribute:.width,
                                       relatedBy:.equal,
                                       toItem:self,
                                       attribute:.width,
                                       multiplier:1.0,
                                       constant:0.0)
        self.addConstraint(width)
        
        let height = NSLayoutConstraint(item:view,
                                        attribute:.height,
                                        relatedBy:.equal,
                                        toItem:self,
                                        attribute:.height,
                                        multiplier:1.0,
                                        constant:0.0)
        self.addConstraint(height)
    }
    
    func addSubViewAndCenter(_ view:UIView) {
        addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        let centerX = NSLayoutConstraint(item:view,
                                         attribute:.centerX,
                                         relatedBy:.equal,
                                         toItem:self,
                                         attribute:.centerX,
                                         multiplier:1.0,
                                         constant:0.0)
        self.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item:view,
                                         attribute:.centerY,
                                         relatedBy:.equal,
                                         toItem:self,
                                         attribute:.centerY,
                                         multiplier:1.0,
                                         constant:0.0)
        self.addConstraint(centerY)
    }

    func addSubViewInset(_ view:UIView, insets:UIEdgeInsets) {
        addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false

        let top = NSLayoutConstraint(item:view,
                                     attribute:.top,
                                     relatedBy:.equal,
                                     toItem:self,
                                     attribute:.top,
                                     multiplier:1.0,
                                     constant:insets.top)
        self.addConstraint(top)

        
        let bottom = NSLayoutConstraint(item:self,
                                     attribute:.bottom,
                                     relatedBy:.equal,
                                     toItem:view,
                                     attribute:.bottom,
                                     multiplier:1.0,
                                     constant:insets.bottom)
        self.addConstraint(bottom)

        let left = NSLayoutConstraint(item:view,
                                        attribute:.left,
                                        relatedBy:.equal,
                                        toItem:self,
                                        attribute:.left,
                                        multiplier:1.0,
                                        constant:insets.left)
        self.addConstraint(left)
        
        let right = NSLayoutConstraint(item:self,
                                      attribute:.right,
                                      relatedBy:.equal,
                                      toItem:view,
                                      attribute:.right,
                                      multiplier:1.0,
                                      constant:insets.right)
        self.addConstraint(right)
    }

    func constrainToCurrentSize() {
        let width = NSLayoutConstraint(item:self,
                                       attribute:.width,
                                       relatedBy:.equal,
                                       toItem:nil,
                                       attribute:.notAnAttribute,
                                       multiplier:1.0,
                                       constant:bounds.width)
        self.addConstraint(width)

        let height = NSLayoutConstraint(item:self,
                                        attribute:.height,
                                        relatedBy:.equal,
                                        toItem:nil,
                                        attribute:.notAnAttribute,
                                        multiplier:1.0,
                                        constant:bounds.height)
        self.addConstraint(height)
    }
    
    func copyConstraintsToView(_ destinationView:UIView) {
        for constraint:NSLayoutConstraint in self.superview!.constraints {
            if constraint.firstItem.isEqual(self) {
                self.superview?.addConstraint(NSLayoutConstraint(item: destinationView, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: constraint.secondItem, attribute: constraint.secondAttribute, multiplier: constraint.multiplier, constant: constraint.constant))
            } else if constraint.secondItem != nil && constraint.secondItem!.isEqual(self) {
                self.superview?.addConstraint(NSLayoutConstraint(item: constraint.firstItem, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: destinationView, attribute: constraint.secondAttribute, multiplier: constraint.multiplier, constant: constraint.constant))
            }
        }
    }
    
    func substitueViewWithView(_ destinationView:UIView) {
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
        if let index = self.superview?.subviews.index(of: self) {
            return index
        } else {
            return -1
        }
    }
    
    func moveToFront() {
        self.superview?.bringSubview(toFront: self)
    }
    
    func moveToBack() {
        self.superview?.sendSubview(toBack: self)
    }

    func moveForward() {
        let index:Int = self.indexInSuperview()
        guard index > 0 && index <= self.superview?.subviews.count else {
            return
        }
        
        self.superview?.exchangeSubview(at: index, withSubviewAt: index + 1)
    }

    func moveBackward() {
        let index:Int = self.indexInSuperview()
        guard index > 0 else {
            return
        }
        
        self.superview?.exchangeSubview(at: index, withSubviewAt: index - 1)
    }

    func swapOrderWithView(_ otherView:UIView) {
        let myIndex = self.indexInSuperview()
        guard myIndex > 0 else {
            return
        }
        
        let otherIndex = otherView.indexInSuperview()
        guard otherIndex > 0 else {
            return
        }
        
        self.superview?.exchangeSubview(at: myIndex, withSubviewAt: otherIndex)
    }

    /**
     Identical to UIView.animate(withDuration:) but returns percentage of progress in closure should animation be interrupted.
     Progress will be 1.0 in the event of sucessful completion of the animation, 0.0..<1.0 in the event of cancellation.

     - note: The progress is an estimatation based on the start time, end time, and duration of the animation. There is no compensation for any curve that may have been applied.
     */
    open class func animationProgress(withDuration duration: TimeInterval, delay: TimeInterval, options: UIViewAnimationOptions, animations: @escaping () -> Void, progress: ((_ progress: Double) -> Swift.Void)? = nil) {
        let startTime = Date()
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: { (success) in
            if let progress = progress {
                progress(success ? 1.0 : (Date().timeIntervalSince(startTime)/duration))
            }
        } )
    }
    
    // delay = 0.0, options = 0
    open class func animationProgress(withDuration duration: TimeInterval, animations: @escaping () -> Swift.Void, progress: ((_ progress: Double) -> Swift.Void)? = nil) {
        animationProgress(withDuration: duration, delay: 0.0, options: UIViewAnimationOptions(rawValue: UInt(0)), animations: animations, progress: progress)
    }
}
