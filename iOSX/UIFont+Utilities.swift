//
//  UIFont+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/11/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

public extension UIFont {
    ///Get system fonts at specified weights
    static func preferredFont(for style: TextStyle, weight: Weight) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)
        return metrics.scaledFont(for: font)
    }

    ///Find the size of a string when drawn with the current font at the supplied width/height
    func sizeOfString (_ string: String, constrainedToWidth width:CGFloat = CGFloat.greatestFiniteMagnitude, constrainedToHeight height:CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize {
        NSString(string: string).boundingRect(with: CGSize(width: width, height: height),
                                              options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                              attributes: [NSAttributedString.Key.font: self],
                                              context: nil).size
    }

    
    ///Down and dirty way to get variations on fonts
    func variantWithTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits([fontDescriptor.symbolicTraits, trait]) else {
            return self
        }

        return UIFont(descriptor: descriptor, size: pointSize)
    }
    
    var boldVariant: UIFont {
        return variantWithTrait(.traitBold)
    }

    ///Returns variant of current font that will fit within the given height
    /// - note: This makes the assumption that font heights scale mostly linearly
    ///  with respect to point size. That may not always be the case especially
    ///  at the extremes of point sizes.
    func fittingHeight(_ height: CGFloat) -> UIFont {
        withSize(floor(height * (pointSize / lineHeight)))
    }
    
    func variantWithDesign(_ design: UIFontDescriptor.SystemDesign) -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(design) else {
            return self
        }

        return UIFont(descriptor: descriptor, size: pointSize)
    }
    
    var roundedVariant: UIFont {
        return variantWithDesign(.rounded)
    }
}
