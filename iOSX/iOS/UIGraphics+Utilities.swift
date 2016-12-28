//
//  UIGraphics+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 12/28/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

public func UIGraphicsContext(size:CGSize, closure: (_ context:CGContext) -> ()) {
    UIGraphicsBeginImageContext(size)
    guard let context:CGContext = UIGraphicsGetCurrentContext() else {
        return
    }
    
    closure(context)
    
    UIGraphicsEndImageContext()
}
