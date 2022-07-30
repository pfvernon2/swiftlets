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

// MARK: - View Positioning

public extension UIView {
    
    /**
     Add a subview and make it conform to our size.
     
     This is handy for programatically adding views to IB layouts.
     
     -Parameter view: The view to make subview
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
        guard let constraints = self.superview?.constraints else {
            return
        }
        
        for constraint:NSLayoutConstraint in constraints {
            guard let firstConstraint = constraint.firstItem, let secondConstraint = constraint.secondItem else {
                return
            }

            if firstConstraint.isEqual(self) {
                self.superview?.addConstraint(NSLayoutConstraint(item: destinationView, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: secondConstraint, attribute: constraint.secondAttribute, multiplier: constraint.multiplier, constant: constraint.constant))
            } else if secondConstraint.isEqual(self) {
                self.superview?.addConstraint(NSLayoutConstraint(item: firstConstraint, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: destinationView, attribute: constraint.secondAttribute, multiplier: constraint.multiplier, constant: constraint.constant))
            }
        }
    }
    
    ///Replace our current view with a new view with the same constraints.
    /// Example: Replace a label with a text field to enable editing
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
}

// MARK: - View Sizing
public extension UIView {
    func minDimension() -> CGFloat{
        min(self.bounds.width, self.bounds.height)
    }

    func maxDimension() -> CGFloat{
        max(self.bounds.width, self.bounds.height)
    }
}

// MARK: - View Ordering in SuperView
public extension UIView {
    func indexInSuperview() -> Int {
        self.superview?.subviews.firstIndex(of: self) ?? -1
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
}

// MARK: - View Animation
public extension UIView {
    /**
     Identical to UIView.animate(withDuration:) but returns percentage of progress in closure should animation be interrupted.
     Progress will be 1.0 in the event of sucessful completion of the animation, 0.0..<1.0 in the event of cancellation.

     - note: The progress is an estimatation based on the start time, end time, and duration of the animation. There is no compensation for any curve that may have been applied.
     */
    class func animationProgress(withDuration duration: TimeInterval, delay: TimeInterval, options: UIView.AnimationOptions, animations: @escaping () -> Void, progress: ((_ progress: Double) -> Swift.Void)? = nil) {
        let startTime = Date()
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: { (success) in
            if let progress = progress {
                progress(success ? 1.0 : (Date().timeIntervalSince(startTime)/duration))
            }
        } )
    }
    
    // delay = 0.0, options = 0
    class func animationProgress(withDuration duration: TimeInterval, animations: @escaping () -> Swift.Void, progress: ((_ progress: Double) -> Swift.Void)? = nil) {
        animationProgress(withDuration: duration, delay: 0.0, options: UIView.AnimationOptions(rawValue: UInt(0)), animations: animations, progress: progress)
    }
}

// MARK: - View Appearance
public extension UIView {
    func round(cornerRadius radius: CGFloat) {
        layer.cornerRadius = radius;
        layer.masksToBounds = true;
    }

    func round(corners: CACornerMask, cornerRadius: CGFloat) {
        layer.cornerRadius = CGFloat(cornerRadius)
        clipsToBounds = true
        layer.maskedCorners = corners
    }
}

public extension UIView {
    var firstResponder: UIView? {
        guard !isFirstResponder else {
            return self
        }

        for subview in subviews {
            if let firstResponder = subview.firstResponder {
                return firstResponder
            }
        }

        return nil
    }
    
    var safeAreaFrame: CGRect {
        guard #available(iOS 11, *) else {
            return bounds
        }
        
        return safeAreaLayoutGuide.layoutFrame
    }
    
    var safeAreaBottomHeight: CGFloat {
        guard let window = window else {
            return .zero
        }
        return window.bounds.height - (safeAreaFrame.top + safeAreaFrame.height)
    }
}

public class RuleView: UIView {
    var lineWidth: CGFloat = 1.0
    var strokeColor: UIColor = .black
    
    public override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        
        if bounds.height > bounds.width {
            path.move(to: bounds.midTop)
            path.addLine(to: bounds.midBottom)
        } else {
            path.move(to: bounds.midLeft)
            path.addLine(to: bounds.midRight)
        }
        
        path.lineWidth = lineWidth
        path.close()
        
        strokeColor.setStroke()
        path.stroke()
    }
}
