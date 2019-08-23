//
//  RoundedCornerView.swift
//  swiftlets
//
//  Created by Frank Vernon on 11/28/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import UIKit
import QuartzCore

@IBDesignable class RoundedCornerView: UIView {
    
    @IBInspectable var passthroughTouches:Bool = false
    
    @IBInspectable var borderColor:UIColor? = nil {
        didSet {
            if let borderColor = borderColor {
                layer.borderColor = borderColor.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable var borderWidth:CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var cornerRadius:CGFloat {
        set (radius) {
            self.layer.cornerRadius = radius
            self.layer.masksToBounds = radius > 0.0
        }
        get {
            self.layer.cornerRadius
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.cornerRadius = 3.0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.cornerRadius = 3.0
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView:UIView? = super.hitTest(point, with: event)
        if self.passthroughTouches {
            return hitView == self ? nil : hitView
        } else {
            return hitView
        }
    }
}

@IBDesignable class RoundImageView: UIImageView {
    
    let circlePathLayer = CAShapeLayer()
    
    @IBInspectable var borderColor:UIColor = UIColor.black {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth:CGFloat = 2.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    func makeRound() {
        let minDimension:CGFloat = min(self.bounds.width, self.bounds.height)
        
        let layer:CALayer = self.layer
        layer.masksToBounds = true
        layer.cornerRadius = minDimension/2.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.makeRound()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    func configure() {
        makeRound()
        
        circlePathLayer.frame = bounds
        circlePathLayer.lineWidth = 2.0
        circlePathLayer.fillColor = UIColor.clear.cgColor
        circlePathLayer.strokeColor = UIColor.black.cgColor
        layer.addSublayer(circlePathLayer)
    }    
}

@IBDesignable class RoundedCornerTextView: UITextView {
    
    @IBInspectable var borderColor:UIColor? = nil {
        didSet {
            if let borderColor = borderColor {
                layer.borderColor = borderColor.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable var borderWidth:CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var cornerRadius:CGFloat {
        set (radius) {
            self.layer.cornerRadius = radius
            self.layer.masksToBounds = radius > 0.0
        }
        get {
            self.layer.cornerRadius
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.cornerRadius = 3.0
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.cornerRadius = 3.0
    }
}
