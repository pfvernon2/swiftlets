//
//  UIImage+Scaling.swift
//  Segues
//
//  Created by Frank Vernon on 1/19/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIImage {

    func scaleToSize(size:CGSize) -> UIImage? {
        guard let colorSpace:CGColorSpaceRef = CGColorSpaceCreateDeviceRGB() else {
            return nil
        }
        
        let context:CGContextRef = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), 8, 0, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)!
        CGContextClearRect(context, CGRectMake(0, 0, size.width, size.height))
        
        if self.imageOrientation == .Right
        {
            CGContextRotateCTM(context, CGFloat(-M_PI_2))
            CGContextTranslateCTM(context, -size.height, 0.0)
            CGContextDrawImage(context, CGRectMake(0, 0, size.height, size.width), self.CGImage!)
        }
        else {
            CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), self.CGImage!)
        }
        
        let scaledImage:CGImageRef = CGBitmapContextCreateImage(context)!
        
        let image:UIImage = UIImage(CGImage: scaledImage)
        
        return image
    }
    
    func scaleProportionalToSize(size:CGSize) -> UIImage? {
        var proportialSize = size
        if self.size.width > self.size.height {
            proportialSize = CGSizeMake((self.size.width/self.size.height) * proportialSize.height, proportialSize.height)
        }
        else {
            proportialSize = CGSizeMake(proportialSize.width, (self.size.height/self.size.width) * proportialSize.width)
        }
        
        return scaleToSize(proportialSize)
    }

    func circular() -> UIImage? {
        let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
        imageView.contentMode = .ScaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        imageView.layer.renderInContext(context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result
    }

    //https://gist.github.com/ffried/0cbd6366bb9cf6fc0208
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage? {
        func degreesToRadians(degrees:CGFloat) -> CGFloat {
            return degrees / 180.0 * CGFloat(M_PI)
        }

        defer {
            UIGraphicsEndImageContext()
        }

        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
        rotatedViewBox.transform = CGAffineTransformMakeRotation(degreesToRadians(degrees))
        let rotatedSize = rotatedViewBox.frame.size

        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        guard let bitmap:CGContext = UIGraphicsGetCurrentContext() else {
            return nil
        }

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);

        // Rotate the image context
        CGContextRotateCTM(bitmap, degreesToRadians(degrees));

        // Now, draw the rotated/scaled image into the context
        CGContextScaleCTM(bitmap, flip ? -1.0 : 1.0, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage!)

        let newImage:UIImage? = UIGraphicsGetImageFromCurrentImageContext()

        return newImage
    }

}
