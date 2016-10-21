//
//  UIImage+maskColor.swift
//  Segues
//
//  Created by Frank Vernon on 1/3/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIImage {
    func maskWithColor(color:UIColor) -> UIImage? {
        let newRect:CGRect = CGRect(origin: CGPointZero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(newRect.size, false, scale)
        let context:CGContextRef = UIGraphicsGetCurrentContext()!
        
        drawInRect(newRect)
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextSetBlendMode(context, .SourceAtop)
        CGContextFillRect(context, newRect)
        
        let result:UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
    
    func clipMaskWithColor(color:UIColor) -> UIImage? {
        let rect:CGRect = CGRect(origin: CGPointZero, size: size)
        
        UIGraphicsBeginImageContext(rect.size)
        let context:CGContextRef = UIGraphicsGetCurrentContext()!
        
        CGContextClipToMask(context, rect, self.CGImage!)
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let masked:UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();

        guard let image = masked?.CGImage else {
            return nil
        }

        let flippedImage:UIImage = UIImage(CGImage: image, scale: 1.0, orientation: .DownMirrored)
        return flippedImage
    }

    public func rotated(degrees: CGFloat) -> UIImage? {
        let rotatedView = UIView(frame: CGRect(origin: CGPointZero, size: size))
        rotatedView.transform = CGAffineTransformMakeRotation(degrees/180.0 * CGFloat(M_PI))
        let rotatedSize = rotatedView.frame.size
        
        UIGraphicsBeginImageContext(rotatedSize)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextTranslateCTM(context!, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
        CGContextRotateCTM(context!, degrees/180.0 * CGFloat(M_PI));
        CGContextDrawImage(context!, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage!)
        
        let result:UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
}
