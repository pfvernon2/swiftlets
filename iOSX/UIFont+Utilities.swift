//
//  UIFont+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/11/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIFont {
    ///Find the size of a string when drawn with the current font at the supplied width/height
    func sizeOfString (_ string: String, constrainedToWidth width:CGFloat = CGFloat.greatestFiniteMagnitude, constrainedToHeight height:CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize {
        return NSString(string: string).boundingRect(with: CGSize(width: width, height: height),
                                                             options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                                             attributes: [NSAttributedString.Key.font: self],
                                                             context: nil).size
    }
}
