//
//  UIImage+maskColor.swift
//  Segues
//
//  Created by Frank Vernon on 1/3/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIImage {
    
    func imageMaskWithColor(color:UIColor) -> UIImage {
        let newRect:CGRect = CGRect(x: 0,y: 0,width: size.width, height: size.height)
        
        UIGraphicsBeginImageContextWithOptions(newRect.size, false, scale)
        let context:CGContextRef = UIGraphicsGetCurrentContext()!
        drawInRect(newRect)
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextSetBlendMode(context, .SourceAtop)
        CGContextFillRect(context, newRect)
        
        let result:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
}
