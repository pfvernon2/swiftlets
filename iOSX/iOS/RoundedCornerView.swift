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

extension CGRect {
    var center:CGPoint {
        return CGPointMake(CGRectGetMidX(self), CGRectGetMidY(self));
    }
    
    static func rectCenteredOn(center:CGPoint, radius:CGFloat) -> CGRect {
        return CGRectMake(floor(center.x - radius), floor(center.y - radius), floor(radius*2.0), floor(radius*2.0))
    }
}

class RoundImageView: UIImageView {
    
    func makeRound() {
        let minDimension:CGFloat = min(self.bounds.width, self.bounds.height)
        
        let layer:CALayer = self.layer
        layer.masksToBounds = true
        layer.cornerRadius = minDimension/2.0
        
        layer.borderWidth = 2.0
        layer.borderColor = UIColor.blackColor().CGColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.makeRound()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        makeRound()
    }

}