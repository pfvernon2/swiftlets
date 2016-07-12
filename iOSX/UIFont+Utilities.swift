//
//  UIFont+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/11/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension UIFont {
    ///Find the size of a string when drawn with the current font at the supplied width/height
    func sizeOfString (string: String, constrainedToWidth width:CGFloat = CGFloat.max, constrainedToHeight height:CGFloat = CGFloat.max) -> CGSize {
        return NSString(string: string).boundingRectWithSize(CGSize(width: width, height: height),
                                                             options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                                                             attributes: [NSFontAttributeName: self],
                                                             context: nil).size
    }
}
