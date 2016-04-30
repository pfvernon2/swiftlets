//
//  UIColor+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 4/30/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension UIColor {
    /**
     Convenience initializer for creating UIColor from HTML hex formats: #RRGGBB
     
     - parameters:
       - htmlHex: HTML style hex description of RGB color: #RRGGBB
    */
    public convenience init(htmlHex:String) {
        let hexScanner:NSScanner = NSScanner(string: htmlHex)
        
        //step over # if included
        if htmlHex.hasPrefix("#") {
            hexScanner.scanLocation = 1
        }
        var rgbInt:UInt32 = 0
        hexScanner.scanHexInt(&rgbInt)
        
        let red:CGFloat = CGFloat((rgbInt & 0xFF0000) >> 16)/255.0
        let green:CGFloat = CGFloat((rgbInt & 0xFF00) >> 8)/255.0
        let blue:CGFloat = CGFloat((rgbInt & 0xFF))/255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}