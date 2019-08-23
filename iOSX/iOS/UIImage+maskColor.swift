//
//  UIImage+maskColor.swift
//  swiftlets
//
//  Created by Frank Vernon on 1/3/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIImage {
    func mask(withColor color:UIColor) -> UIImage? {
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
    
    func clipMask(withColor color:UIColor) -> UIImage? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        
        let rect:CGRect = CGRect(origin: CGPoint.zero, size: size)
        
        UIGraphicsBeginImageContext(rect.size)
        defer {
            UIGraphicsEndImageContext()
        }
        
        let context:CGContext = UIGraphicsGetCurrentContext()!
        context.clip(to: rect, mask: cgImage)
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let masked:UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        
        guard let image = masked?.cgImage else {
            return nil
        }
        
        let flippedImage:UIImage = UIImage(cgImage: image, scale: 1.0, orientation: .downMirrored)
        return flippedImage
    }
}
