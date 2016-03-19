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
