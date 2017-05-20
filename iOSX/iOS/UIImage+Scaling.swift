//
//  UIImage+Scaling.swift
//  swiftlets
//
//  Created by Frank Vernon on 1/19/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIImage {
    ///Scale image to the size supplied. If screen resolution is desired, pass scale == 0.0
    func scale(toSize size:CGSize, flip:Bool = false, scale:CGFloat = 1.0) -> UIImage? {
        let newRect:CGRect = CGRect(x:0, y:0, width:size.width, height:size.height).integral
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        defer {
            UIGraphicsEndImageContext()
        }
        
        guard let context:CGContext = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        
        // Set the quality level to use when rescaling
        context.interpolationQuality = CGInterpolationQuality.high
        
        //flip if requested
        if flip {
            let flipVertical:CGAffineTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)
            context.concatenate(flipVertical)
        }
        
        // Draw into the context; this scales the image
        draw(in: newRect)
        
        // Get the resized image from the context and a UIImage
        guard let newImageRef:CGImage = context.makeImage() else {
            return nil
        }
        
        let newImage:UIImage = UIImage(cgImage: newImageRef)
        
        
        return newImage;
    }
    
    func scaleProportional(toSize size:CGSize, scale:CGFloat = 1.0) -> UIImage? {
        var proportialSize = size
        if self.size.width > self.size.height {
            proportialSize = CGSize(width: (self.size.width/self.size.height) * proportialSize.height, height: proportialSize.height)
        }
        else {
            proportialSize = CGSize(width: proportialSize.width, height: (self.size.height/self.size.width) * proportialSize.width)
        }
        
        return self.scale(toSize: proportialSize)
    }
    
    func circular() -> UIImage? {
        let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
        imageView.contentMode = .scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
    
    //https://gist.github.com/ffried/0cbd6366bb9cf6fc0208
    public func imageRotated(byDegrees degrees: CGFloat, flip: Bool) -> UIImage? {
        func degreesToRadians(_ degrees:CGFloat) -> CGFloat {
            return degrees / 180.0 * CGFloat(Double.pi)
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPoint.zero, size: size))
        rotatedViewBox.transform = CGAffineTransform(rotationAngle: degreesToRadians(degrees))
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        
        defer {
            UIGraphicsEndImageContext()
        }
        
        guard let bitmap:CGContext = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)
        
        // Rotate the image context
        bitmap.rotate(by: degreesToRadians(degrees))
        
        // Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: flip ? -1.0 : 1.0, y: -1.0)
        draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        
        let newImage:UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        
        return newImage
    }
}
