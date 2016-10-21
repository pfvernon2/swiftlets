//
//  UIImage+maskColor.swift
//  swiftlets
//
//  Created by Frank Vernon on 1/3/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIImage {
    func maskWithColor(_ color:UIColor) -> UIImage? {
        let newRect:CGRect = CGRect(origin: CGPoint.zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(newRect.size, false, scale)
        let context:CGContext = UIGraphicsGetCurrentContext()!
        
        draw(in: newRect)
        context.setFillColor(color.cgColor)
        context.setBlendMode(.sourceAtop)
        context.fill(newRect)
        
        let result:UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
    
    func clipMaskWithColor(_ color:UIColor) -> UIImage? {
        let rect:CGRect = CGRect(origin: CGPoint.zero, size: size)
        
        UIGraphicsBeginImageContext(rect.size)
        let context:CGContext = UIGraphicsGetCurrentContext()!
        
        context.clip(to: rect, mask: self.cgImage!)
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let masked:UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();

        guard let image = masked?.cgImage else {
            return nil
        }

        let flippedImage:UIImage = UIImage(cgImage: image, scale: 1.0, orientation: .downMirrored)
        return flippedImage
    }

    public func rotated(_ degrees: CGFloat) -> UIImage? {
        let rotatedView = UIView(frame: CGRect(origin: CGPoint.zero, size: size))
        rotatedView.transform = CGAffineTransform(rotationAngle: degrees/180.0 * CGFloat(M_PI))
        let rotatedSize = rotatedView.frame.size
        
        UIGraphicsBeginImageContext(rotatedSize)
        let context = UIGraphicsGetCurrentContext()
        
        context!.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0);
        context!.rotate(by: degrees/180.0 * CGFloat(M_PI));
        draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        
        let result:UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
}
