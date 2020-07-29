//
//  UIFont+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/11/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

public extension UIFont {
    ///Find the size of a string when drawn with the current font at the supplied width/height
    func sizeOfString (_ string: String, constrainedToWidth width:CGFloat = CGFloat.greatestFiniteMagnitude, constrainedToHeight height:CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize {
        NSString(string: string).boundingRect(with: CGSize(width: width, height: height),
                                              options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                              attributes: [NSAttributedString.Key.font: self],
                                              context: nil).size
    }
}

//Down and dirty way to get variations on fonts
public extension UIFont {
    func boldVariant() -> UIFont? {
        return variantWithTrait(.traitBold)
    }
    
    func variantWithTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> UIFont? {
        let fontDescriptor = self.fontDescriptor
        let fontDescriptorSymbolicTraits: UIFontDescriptor.SymbolicTraits = [fontDescriptor.symbolicTraits, trait]

        guard let boldFontDesc = fontDescriptor.withSymbolicTraits(fontDescriptorSymbolicTraits) else {
            return nil
        }

        return UIFont(descriptor: boldFontDesc, size: pointSize)
    }
    
    ///Returns variant of current font that will fit within the given height
    /// - note: This makes the assumption that font heights scale mostly linearly
    ///  with respect to point size. That may not always be the case especially
    ///  at the extremes of point sizes.
    func fittingHeight(_ height: CGFloat) -> UIFont {
        withSize(floor(height * (pointSize / lineHeight)))
    }
}
