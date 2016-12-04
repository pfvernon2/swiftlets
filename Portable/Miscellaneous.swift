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
        return CGPoint(x: self.midX, y: self.midY)
    }
    
    static func rectCenteredOn(center:CGPoint, radius:CGFloat) -> CGRect {
        return CGRect(x: floor(center.x - radius), y: floor(center.y - radius), width: floor(radius*2.0), height: floor(radius*2.0))
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

extension TimeInterval {
    func toPicoseconds() -> Double {
        return toNanoseconds() * 1000.0
    }

    func toNanoseconds() -> Double {
        return toMicroseconds() * 1000.0
    }

    func toMicroseconds() -> Double {
        return toMilliseconds() * 1000.0
    }

    func toMilliseconds() -> Double {
        return self * 1000.0
    }

    func toMinutes() -> Double {
        return self/60.0
    }
    
    func toHours() -> Double {
        return toMinutes()/60.0
    }
    
    func toDays() -> Double {
        return toHours()/24.0
    }

    /**
     Returns a localized human readable description of the time interval.

     - note: The result is limited to Days, Hours, and Minutes and includes a localized indication of approximation.

     Examples:
     * About 14 minutes
     * About 1 hour, 7 minutes
     */
    func approximateDurationLocalizedDescription() -> String {
        let start = Date()
        let end = Date(timeInterval: self, since: start)

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.includesApproximationPhrase = true
        formatter.includesTimeRemainingPhrase = false
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.maximumUnitCount = 2
        
        return formatter.string(from: start, to: end) ?? ""
    }
}

extension UserDefaults {
    ///setObject(forKey:) where value != nil, removeObjectForKey where value == nil
    func setOrRemoveObject(_ value: Any?, forKey defaultName: String) {
        if value != nil {
            UserDefaults.standard.set(value, forKey: defaultName)
        } else {
            UserDefaults.standard.removeObject(forKey: defaultName)
        }
    }
}

extension CGAffineTransform {
    ///returns the current rotation of the transform in radians
    func rotationInRadians() -> Double {
        return Double(atan2f(Float(self.b), Float(self.a)))
    }

    ///returns the current rotation of the transform in degrees 0.0 - 360.0
    func rotationInDegrees() -> Double {
        var result = Double(rotationInRadians()) * (180.0/M_PI)
        if result < 0.0 {
            result = 360.0 - result
        }
        return result
    }
}

///Trivial indexing generator that wraps back to startIndex when reaching endIndex
class WrappingIndexingGenerator<C: Collection>: IteratorProtocol {
    var _collection: C
    var _index: C.Index
    
    func next() -> C.Iterator.Element? {
        var item:C.Iterator.Element?
        if _index == _collection.endIndex {
            _index = _collection.startIndex
        }
        item = _collection[_index]
        _index = _collection.index(after: _index)
        return item
    }
    
    init(_ collection: C) {
        _collection = collection
        _index = _collection.startIndex
    }
}

/// Protocol for enums providing a count of its cases.
///
/// To conform to this protocol implement the caseCount var as:
///
/// ~~~
///  static let caseCount = MyEnum.countCases()
/// ~~~
///
/// - note: The countCases() func is implemented in default extension. You need only implement the caseCount var as described above.
protocol CountableCases {
    static func countCases() -> Int
    static var caseCount:Int { get }
}

/// Default implementation of CountableCases providing generic solution for counting cases in the enum
extension CountableCases where Self : RawRepresentable, Self.RawValue == Int {
    static func countCases() -> Int {
        var count = 0
        while let _ = Self(rawValue: count) { count += 1 }
        return count
    }
}
