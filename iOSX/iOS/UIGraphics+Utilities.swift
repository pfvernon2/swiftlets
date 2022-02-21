//
//  UIGraphics+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 12/28/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

/**
 Helper method to scope creation and release of a UIGraphics image context.
 
 - Parameter size: The size of the resulting image
 - Parameter opaque: Indicate if context should ignore alpha channel and return opaque image.
 - Parameter scale: The scale factor to apply to the bitmap. The default value of 0.0 uses the scale factor of the device’s main screen.
 - Parameter closure: Closure where you should perform your image creation work. The image context is provided.
 
 - Returns: A UIImage or nil if processing fails. 
 */
public func UIGraphicsImageContext(size:CGSize, opaque:Bool = false, scale:CGFloat = .zero, closure: (_ context:CGContext) -> ()) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
    
    defer {
        UIGraphicsEndImageContext()
    }
    
    guard let context:CGContext = UIGraphicsGetCurrentContext() else {
        return nil
    }
    
    closure(context)
    
    return UIGraphicsGetImageFromCurrentImageContext()
}

public extension UIBezierPath {
    ///Draws a vertical line at the given x, y for the given height
    func addVerticalLine(at point: CGPoint, ofLength height: CGFloat) {
        move(to: point)
        addLine(to: CGPoint(x: point.x, y: point.y + height))
    }
    
    ///Draws a horizontal line at the given x, y for the given width
    func addHorizontalLine(at point: CGPoint, ofLength width: CGFloat) {
        move(to: point)
        addLine(to: CGPoint(x: point.x + width, y: point.y))
    }
    
    ///Draws a vertical line at the given x, y for the given height
    func addVerticalLine(ofLength height: CGFloat) {
        addLine(to: CGPoint(x: currentPoint.x, y: currentPoint.y + height))
    }
    
    ///Draws a horizontal line at the given x, y for the given width
    func addHorizontalLine(ofLength width: CGFloat) {
        addLine(to: CGPoint(x: currentPoint.x + width, y: currentPoint.y))
    }

    
    convenience init(star rect: CGRect, points: Int = 5) {
        self.init()

        let center = rect.center

        let numberOfPoints: CGFloat = 5.0
        let numberOfLineSegments = Int(numberOfPoints * 2.0)
        let theta = .pi / numberOfPoints

        let circumscribedRadius = center.x
        let outerRadius = circumscribedRadius * 1.039
        let excessRadius = outerRadius - circumscribedRadius
        let innerRadius = CGFloat(outerRadius * 0.382)

        let leftEdgePointX = (center.x + cos(4.0 * theta) * outerRadius) + excessRadius
        let horizontalOffset = leftEdgePointX / 2.0

        // Apply a slight horizontal offset so the star appears to be more
        // centered visually
        let offsetCenter = CGPoint(x: center.x - horizontalOffset, y: center.y)

        // Alternate between the outer and inner radii while moving evenly along the
        // circumference of the circle, connecting each point with a line segment
        for i in 0..<numberOfLineSegments {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius

            let pointX = offsetCenter.x + cos(CGFloat(i) * theta) * radius
            let pointY = offsetCenter.y + sin(CGFloat(i) * theta) * radius
            let point = CGPoint(x: pointX, y: pointY)

            if i == .zero {
                move(to: point)
            } else {
                addLine(to: point)
            }
        }

        close()
    }
    
    convenience init(polgygonIn rect: CGRect, sides: Int) {
        self.init()

        let radius = min(rect.width, rect.height)/2.0
        for segment in 0..<sides {
            let seg = CGFloat(segment)
            let side = CGFloat(sides)
            let point = CGPoint(x: rect.origin.x + (rect.width/2.0 + radius * cos(seg * 2.0 * CGFloat.pi/side)),
                                y: rect.origin.y + (rect.width/2.0 + radius * sin(seg * 2.0 * CGFloat.pi/side)))
            if segment == 0 {
                move(to: point)
            } else {
                addLine(to: point)
            }
        }
        
        close()
    }

}

public extension UIEdgeInsets {
    init(inset: CGFloat) {
        self.init(top: inset, left: inset, bottom: inset, right: inset)
    }
}

extension CGAffineTransform {
    ///returns the current rotation of the transform in radians
    func rotationInRadians() -> Double {
        Double(atan2f(Float(self.b), Float(self.a)))
    }
    
    ///returns the current rotation of the transform in degrees 0.0 - 360.0
    func rotationInDegrees() -> Double {
        var result = Double(rotationInRadians()) * (180.0/Double.pi)
        if result < 0.0 {
            result = 360.0 - result
        }
        return result
    }
}

extension CACornerMask {
    public static var topLeft: CACornerMask = { layerMinXMinYCorner }()
    public static var lowerLeft: CACornerMask = { layerMinXMaxYCorner }()
    public static var topRight: CACornerMask = { layerMaxXMinYCorner }()
    public static var lowerRight: CACornerMask = { layerMaxXMaxYCorner }()
}
