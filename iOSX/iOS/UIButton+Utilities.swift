//
//  UIButton+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 2/24/21.
//  Copyright © 2021 Frank Vernon. All rights reserved.
//

import UIKit

public extension UIButton {
    func centerTitleImage(withSpacing spacing: CGFloat = 10.0) {
        imageEdgeInsets = UIEdgeInsets(top: .zero, left: .zero, bottom: .zero, right: spacing)
        titleEdgeInsets = UIEdgeInsets(top: .zero, left: spacing, bottom: .zero, right: .zero)
    }

    func resetInsets() {
        imageEdgeInsets = UIEdgeInsets.zero
        titleEdgeInsets = UIEdgeInsets.zero
    }
}
