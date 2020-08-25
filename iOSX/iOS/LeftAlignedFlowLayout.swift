//
//  LeftAlignedFlowLayout.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/27/20.
//  Copyright © 2020 Frank Vernon. All rights reserved.
//

import UIKit

///Custom flow layout to keep collection view cells aligned left.
/// There are a lot of assumptions in here about cell spacing and insets but this implementation
/// is simple enough that it should be adequate to subclass and override configure() for most applications.
open class LeftAlignedFlowLayout: UICollectionViewFlowLayout {
    open var spacing: CGFloat = 8.0 {
        didSet {
            configure()
        }
    }
    
    required public override init() {
        super.init();
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        configure()
    }

    ///Setup the spacing and insets.
    ///This is a likely candidate for overriding if you subclass.
    open func configure() {
        estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        minimumLineSpacing = spacing
        minimumInteritemSpacing = spacing
    }

    open override func layoutAttributesForElements( in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in:rect) else {
            return []
        }
        
        let initalX: CGFloat = sectionInset.left
        let initalY: CGFloat = sectionInset.top

        var currX: CGFloat = initalX
        var currY: CGFloat = initalY

        attributes.forEach { (attribute) in
            guard attribute.representedElementCategory == .cell else {
                return
            }

            //move back to left margin if this cell is on a new row
            if attribute.frame.origin.y >= currY {
                currX = initalX
            }
            
            //make cell left at currX position
            attribute.frame.origin.x = currX
            
            //reset for next iteration...
            // next cell X position will be this cells right side + the collection cell spacing
            currX += attribute.frame.width + minimumInteritemSpacing
            //keep track of current Y position so we can move back to left margin if necessary
            currY = attribute.frame.maxY
        }
        
        return attributes
    }
}
