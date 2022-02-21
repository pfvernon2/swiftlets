//
//  CGUtilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 2/7/21.
//  Copyright © 2021 Frank Vernon. All rights reserved.
//

import QuartzCore

// MARK: - CGRect

public extension CGRect {
    var center:CGPoint {
        get {
            CGPoint(x: self.midX, y: self.midY)
        }
        set {
            origin = CGPoint(x: newValue.x - width.halved,
                             y: newValue.y - height.halved)
        }
    }
    
    static func rectCenteredOn(center:CGPoint, radius:CGFloat) -> CGRect {
        CGRect(x: floor(center.x - radius),
               y: floor(center.y - radius),
               width: floor(radius.doubled),
               height: floor(radius.doubled))
    }
    
    var top:CGFloat {
        self.origin.y
    }
    
    var bottom:CGFloat {
        top + self.size.height
    }
    
    var left:CGFloat {
        self.origin.x
    }
    
    var right:CGFloat {
        left + self.size.width
    }
    
    var midLeft: CGPoint {
        CGPoint(x: left, y: self.midY)
    }
    
    var midRight: CGPoint {
        CGPoint(x: right, y: self.midY)
    }
    
    var midTop: CGPoint {
        CGPoint(x: self.midX, y: top)
    }

    var midBottom: CGPoint {
        CGPoint(x: self.midX, y: bottom)
    }
}

// MARK: - CGPoint

public extension CGPoint {
    enum PixelLocation {
        case upperLeft
        case upperRight
        case lowerLeft
        case lowerRight
        case nearest
    }

    ///Snap point to nearest pixel at specified location
    mutating func snap(to location: PixelLocation) {
        switch location {
        case .upperLeft:
            y = ceil(y)
            x = floor(x)
            
        case .upperRight:
            y = ceil(y)
            x = ceil(x)
            
        case .lowerLeft:
            y = floor(y)
            x = floor(x)
            
        case .lowerRight:
            y = floor(y)
            x = ceil(x)
            
        case .nearest:
            y = round(y)
            x = round(x)
        }
    }
    
    func distance(to point: CGPoint) -> CGFloat {
        hypot(point.x - x, point.y - y)
    }
}

// MARK: - CGPointArray

public typealias CGPointArray = [CGPoint]
public extension CGPointArray {
    var minY: CGPoint? {
        self.min { $0.y < $1.y }
    }
    
    var maxY: CGPoint? {
        self.max { $0.y < $1.y }
    }

    var minX: CGPoint? {
        self.min { $0.x < $1.x }
    }
    
    var maxX: CGPoint? {
        self.max { $0.x < $1.x }
    }

    //return points at extents of y-axis
    func yExtents() -> (CGPoint, CGPoint)? {
        guard let min = minY, let max = maxY else {
            return nil
        }
        
        return (min, max)
    }
    
    //return points at extents of x-axis
    func xExtents() -> (CGPoint, CGPoint)? {
        guard let min = minX, let max = maxX else {
            return nil
        }
        
        return (min, max)
    }
}

// MARK: - Trendline Calculation/Conversion

//private - strictly for my own amusement
private extension CGFloat {
    var ²: CGFloat {
        pow(self, 2)
    }
}

fileprivate var kTrendlineMinSamples = 2 //3 is better?
public extension CGPointArray {
    struct Trendline {
        var slope: CGFloat
        var yIntercept: CGFloat
    }

    //https://classroom.synonym.com/calculate-trendline-2709.html
    func calculateTrendline() -> Trendline {
        //Slope
        let n = CGFloat(count)
        let a = n * reduce(.zero) {$0 + ($1.x * $1.y)}
        let b = reduce(.zero) {$0 + $1.x} * reduce(.zero) {$0 + $1.y}
        let c = n * reduce(.zero) {$0 +  $1.x.²}
        let d = reduce(.zero) {$0 + $1.x}.²
        let m = (a - b) / (c - d)
        
        //Y Intercept
        let e = reduce(.zero) {$0 + $1.y}
        let f = m * reduce(.zero) {$0 + $1.x}
        let bY = (e - f) / n
        
        return Trendline(slope: m, yIntercept: bY)
    }
    
    ///Calculate trend line points for current array, presumably a scatter plot
    /// - note: Trendlines need at least 2 points to make any practical sense
    ///        so that limit is enforced here.
    func trendPoints() -> CGPointArray? {
        guard count >= kTrendlineMinSamples else {
            return nil
        }

        let trend = calculateTrendline()
        return map {
            CGPoint(x: $0.x,
                    y: (trend.slope * $0.x) + trend.yIntercept)
        }
    }
    
    ///Convert this set of points, presumably a scatter plot, to a trend line
    /// - note: Trendlines need at least 2 points to make any practical sense
    ///        so that limit is enforced here.
    mutating func convertToTrendPoints() -> Bool {
        guard count >= kTrendlineMinSamples else {
            return false
        }
        
        let trend = calculateTrendline()
        for (index, point) in self.enumerated() {
            self[index] = CGPoint(x: point.x,
                                  y: (trend.slope * point.x) + trend.yIntercept)
        }
        
        return true
    }
}

// MARK: - CGSize

public extension CGSize {
    func maxDimension() -> CGFloat {
        max(width, height)
    }
    
    func minDimension() -> CGFloat {
        min(width, height)
    }
    
    var isWide: Bool {
        width > height
    }
    
    var isTall: Bool {
        height > width
    }
    
    //Golden Rectangle Calculations
    static var ɸ: CGFloat = 1.61803398874989484820
    
    static func goldenRectangleFor(width: CGFloat) -> CGSize {
        CGSize(width: width, height: ceil(width/ɸ))
    }
    
    static func goldenRectangleFor(height: CGFloat) -> CGSize {
        CGSize(width: ceil(height * ɸ), height: height)
    }
}

public extension CGContext {
    func draw(_ action:(_ context: CGContext)->Swift.Void) {
        saveGState()
        action(self)
        restoreGState()
    }
}
