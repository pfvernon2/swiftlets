//
//  UIImage+Scaling.swift
//  Segues
//
//  Created by Frank Vernon on 1/19/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIImage {
    func scaleToSize(_ size:CGSize) -> UIImage? {
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()        
        let context:CGContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        if self.imageOrientation == .right
        {
            context.rotate(by: CGFloat(-M_PI_2))
            context.translateBy(x: -size.height, y: 0.0)
            draw(in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        }
        else {
            draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        let scaledImage:CGImage = context.makeImage()!
        
        let image:UIImage = UIImage(cgImage: scaledImage)
        
        return image
    }
    
    func scaleProportionalToSize(_ size:CGSize) -> UIImage? {
        var proportialSize = size
        if self.size.width > self.size.height {
            proportialSize = CGSize(width: (self.size.width/self.size.height) * proportialSize.height, height: proportialSize.height)
        }
        else {
            proportialSize = CGSize(width: proportialSize.width, height: (self.size.height/self.size.width) * proportialSize.width)
        }
        
        return scaleToSize(proportialSize)
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
    public func imageRotatedByDegrees(_ degrees: CGFloat, flip: Bool) -> UIImage? {
        func degreesToRadians(_ degrees:CGFloat) -> CGFloat {
            return degrees / 180.0 * CGFloat(M_PI)
        }

        defer {
            UIGraphicsEndImageContext()
        }

        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPoint.zero, size: size))
        rotatedViewBox.transform = CGAffineTransform(rotationAngle: degreesToRadians(degrees))
        let rotatedSize = rotatedViewBox.frame.size

        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        guard let bitmap:CGContext = UIGraphicsGetCurrentContext() else {
            return nil
        }

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0);

        // Rotate the image context
        bitmap.rotate(by: degreesToRadians(degrees));

        // Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: flip ? -1.0 : 1.0, y: -1.0)
        draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))

        let newImage:UIImage? = UIGraphicsGetImageFromCurrentImageContext()

        return newImage
    }
}
