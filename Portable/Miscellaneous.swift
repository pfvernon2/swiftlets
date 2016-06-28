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