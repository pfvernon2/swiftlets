//
//  RoundedCornerView.swift
//  Segues
//
//  Created by Frank Vernon on 11/28/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import UIKit
import QuartzCore

class RoundedCornerView: UIView {

    var borderColor:UIColor? = nil {
        didSet {
            if let borderColor = borderColor {
                layer.borderColor = borderColor.CGColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    var borderWidth:CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    var cornerRadius:CGFloat {
        set (radius) {
            self.layer.cornerRadius = radius
            self.layer.masksToBounds = radius > 0.0
        }
        get {
            return self.layer.cornerRadius
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.cornerRadius = 3.0
    }
}

class RoundImageView: UIImageView {
    
    let circlePathLayer = CAShapeLayer()

    var borderColor:UIColor = UIColor.blackColor() {
        didSet {
            layer.borderColor = borderColor.CGColor
        }
    }
    
    func makeRound() {
        let minDimension:CGFloat = min(self.bounds.width, self.bounds.height)
        
        let layer:CALayer = self.layer
        layer.masksToBounds = true
        layer.cornerRadius = minDimension/2.0
        
        layer.borderWidth = 2.0
//        layer.borderColor = UIColor.blackColor().CGColor
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
        circlePathLayer.fillColor = UIColor.clearColor().CGColor
        circlePathLayer.strokeColor = UIColor.blackColor().CGColor
        layer.addSublayer(circlePathLayer)
    }    
}