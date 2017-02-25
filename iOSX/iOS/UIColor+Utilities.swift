//
//  UIColor+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 4/30/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIColor {
    /**
     Convenience initializer for creating UIColor from HTML hex formats: #RRGGBB
     
     - parameters:
     - htmlHex: HTML style hex description of RGB color: #RRGGBB
     
     - note: The leading # is optional.
     
     - returns: The color specified by the hex string or the the color white in the event parsing fails.
     */
    public convenience init(htmlHex:String) {
        let hexScanner:Scanner = Scanner(string: htmlHex)
        
        //step over # if included
        if htmlHex.hasPrefix("#") {
            hexScanner.scanLocation = 1
        }
        
        //attempt scan of the string
        var rgbInt:UInt32 = 0
        guard hexScanner.scanHexInt32(&rgbInt) else {
            self.init(white: 1.0, alpha: 1.0)
            return
        }
        
        let red:CGFloat = CGFloat((rgbInt & 0xFF0000) >> 16)/255.0
        let green:CGFloat = CGFloat((rgbInt & 0x00FF00) >> 8)/255.0
        let blue:CGFloat = CGFloat((rgbInt & 0x0000FF))/255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    /**
     Convenience initializer for creating UIColor from the hex format: #RRGGBBAA
     
     - parameters:
     - hexStringWithAlpha: Hex description of RGBA color: #RRGGBBAA
     
     - note: The leading # is optional.
     
     - returns: The color specified by the hex string or the the color white in the event parsing fails.
     */
    public convenience init(hexStringWithAlpha:String) {
        let hexScanner:Scanner = Scanner(string: hexStringWithAlpha)
        
        //step over # if included
        if hexStringWithAlpha.hasPrefix("#") {
            hexScanner.scanLocation = 1
        }
        
        //attempt scan of the string
        var rgbaInt:UInt64 = 0
        guard hexScanner.scanHexInt64(&rgbaInt) else {
            self.init(white: 1.0, alpha: 1.0)
            return
        }
        
        let red = CGFloat((rgbaInt & 0xFF000000) >> 24) / 255.0
        let green:CGFloat = CGFloat((rgbaInt & 0x00FF0000) >> 16)/255.0
        let blue:CGFloat = CGFloat((rgbaInt & 0x0000FF00) >> 8)/255.0
        let alpha:CGFloat = CGFloat((rgbaInt & 0x000000FF))/255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

