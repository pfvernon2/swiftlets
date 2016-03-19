//
//  UIImage+Scaling.swift
//  Segues
//
//  Created by Frank Vernon on 1/19/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIImage {

    func scaleToSize(size:CGSize) -> UIImage {
        let colorSpace:CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()!
        let context:CGContextRef = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), 8, 0, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)!
        CGContextClearRect(context, CGRectMake(0, 0, size.width, size.height))
        
        if self.imageOrientation == .Right
        {
            CGContextRotateCTM(context, CGFloat(-M_PI_2))
            CGContextTranslateCTM(context, -size.height, 0.0)
            CGContextDrawImage(context, CGRectMake(0, 0, size.height, size.width), self.CGImage)
        }
        else {
            CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), self.CGImage)
        }
        
        let scaledImage:CGImageRef = CGBitmapContextCreateImage(context)!
        
        let image:UIImage = UIImage(CGImage: scaledImage)
        
        return image
    }
    
    func scaleProportionalToSize(size:CGSize) -> UIImage {
        var proportialSize = size
        if self.size.width > self.size.height {
            proportialSize = CGSizeMake((self.size.width/self.size.height) * proportialSize.height, proportialSize.height)
        }
        else {
            proportialSize = CGSizeMake(proportialSize.width, (self.size.height/self.size.width) * proportialSize.width)
        }
        
        return scaleToSize(proportialSize)
    }

}
