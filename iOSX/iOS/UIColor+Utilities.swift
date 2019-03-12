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
     - htmlHex: HTML style hex description of RGB color: [#]RRGGBB[AA]
     
     - note: The leading # and trailing alpha values are optional.
     
     - returns: The color specified by the hex string or nil in the event parsing fails.
     */
    public convenience init?(htmlHex:String) {
        guard let color = htmlHex.colorForHex() else {
            return nil
        }
        
        self.init(cgColor: color.cgColor)
    }
}

extension String {
    /**
     Convenience method for creating UIColor from HTML hex formats: [#]RRGGBB[AA]

     - note: The leading # and trailing alpha values are optional.
     
     - returns: The color specified by the hex string or nil in the event parsing fails.
     */
    public func colorForHex() -> UIColor? {
        //creating temp string so we can manipulate as necessary
        var working = self
        
        //remove leading # if present
        if working.hasPrefix("#") {
            working.remove(at: startIndex)
        }
        
        //ensure string fits length requirements
        switch working.count {
        case ...5, 7, 9...:
            //ilegal lengths
            return nil
            
        case 6:
            //RRGGBB
            //add default alpha for ease of processing below
            working.append("FF")
            
        case 8:
             //RRGGBBAA
            break
            
        default:
            //just here to keep compiler happy
            return nil
        }
        
        var rgbaInt:UInt32 = 0
        guard Scanner(string: working).scanHexInt32(&rgbaInt) else {
            return nil
        }

        let bytes: [UInt8] = [
            UInt8(rgbaInt.bigEndian & 0xFF),
            UInt8(rgbaInt.bigEndian >> 8 & 0xFF),
            UInt8(rgbaInt.bigEndian >> 16 & 0xFF),
            UInt8(rgbaInt.bigEndian >> 24 & 0xFF)
        ]

        return UIColor(red: CGFloat(bytes[0])/255.0,
                       green: CGFloat(bytes[1])/255.0,
                       blue: CGFloat(bytes[2])/255.0,
                       alpha: CGFloat(bytes[3])/255.0)
    }
}
