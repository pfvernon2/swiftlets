//
//  Miscellaneous.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/31/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation
import QuartzCore

extension CGRect {
    var center:CGPoint {
        return CGPointMake(CGRectGetMidX(self), CGRectGetMidY(self));
    }
    
    static func rectCenteredOn(center:CGPoint, radius:CGFloat) -> CGRect {
        return CGRectMake(floor(center.x - radius), floor(center.y - radius), floor(radius*2.0), floor(radius*2.0))
    }

    var top:CGFloat {
        return self.origin.y - self.size.height
    }

    var bottom:CGFloat {
        return self.origin.y
    }

    var left:CGFloat {
        return self.origin.x
    }

    var right:CGFloat {
        return self.origin.x + self.size.width
    }
}

extension CGSize {
    func maxDimension() -> CGFloat {
        return width > height ? width : height
    }

    func minDimension() -> CGFloat {
        return width > height ? height : width
    }
}

extension NSTimeInterval {
    func toPicoseconds() -> Double {
        return self * 1000.0 * 1000.0 * 1000.0 * 1000.0
    }

    func toNanoseconds() -> Double {
        return self * 1000.0 * 1000.0 * 1000.0
    }

    func toMicroseconds() -> Double {
        return self * 1000.0 * 1000.0
    }

    func toMilliseconds() -> Double {
        return self * 1000.0
    }

    func toMinutes() -> Double {
        return self/60.0
    }
    
    func toHours() -> Double {
        return self/60.0/60.0
    }
    
    func toDays() -> Double {
        return self/60.0/60.0/24.0
    }

    /**
     Returns a localized human readable description of the time interval.

     - note: The result is limited to Days, Hours, and Minutes and includes an indication of approximation.

     Examples:
     * About 14 minutes
     * About 1 hour, 7 minutes
     */
    func approximateDurationLocalizedDescription() -> String {
        let start = NSDate()
        let end = NSDate(timeInterval: self, sinceDate: start)

        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = .Full
        formatter.includesApproximationPhrase = true
        formatter.includesTimeRemainingPhrase = false
        formatter.allowedUnits = [.Day, .Hour, .Minute]
        formatter.maximumUnitCount = 2
        
        return formatter.stringFromDate(start, toDate: end) ?? ""
    }
}

extension NSUserDefaults {
    ///setObject(forKey:) where value != nil, removeObjectForKey where value == nil
    func setOrRemoveObject(value: AnyObject?, forKey defaultName: String) {
        if value != nil {
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: defaultName)
        } else {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(defaultName)
        }
    }
}

///Trivial indexing generator that wraps back to startIndex when reaching endIndex
class WrappingIndexingGenerator<C: CollectionType>: GeneratorType {
    var _colletion: C
    var _index: C.Index
    func next() -> C.Generator.Element? {
        var item:C.Generator.Element?
        if _index == _colletion.endIndex {
            _index = _colletion.startIndex
        }
        item = _colletion[_index]
        _index = _index.successor()
        return item
    }
    init(_ colletion: C) {
        _colletion = colletion;
        _index = _colletion.startIndex
    }
}
