//
//  UIGraphics+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 12/28/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

/**
 Helper method to scope creation and release of a UIGraphics image context.
 
 - Parameter size: The size of the resulting image
 - Parameter opaque: Indicate if context should ignore alpha channel and return opaque image.
 - Parameter scale: The scale factor to apply to the bitmap. The default value of 0.0 uses the scale factor of the device’s main screen.
 - Parameter closure: Closure where you should perform your image creation work. The image context is provided.

 - Returns: A UIImage or nil if processing fails. 
 */
public func UIGraphicsImageContext(size:CGSize, opaque:Bool = false, scale:CGFloat = 0.0, closure: (_ context:CGContext) -> ()) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
    
    defer {
        UIGraphicsEndImageContext()
    }
    
    guard let context:CGContext = UIGraphicsGetCurrentContext() else {
        return nil
    }
    
    closure(context)
    
    return UIGraphicsGetImageFromCurrentImageContext()
}
