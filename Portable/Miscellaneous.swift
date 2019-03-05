//
//  Miscellaneous.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/31/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit
import QuartzCore

extension CGRect {
    var center:CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
    
    static func rectCenteredOn(center:CGPoint, radius:CGFloat) -> CGRect {
        return CGRect(x: floor(center.x - radius),
                      y: floor(center.y - radius),
                      width: floor(radius*2.0),
                      height: floor(radius*2.0))
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

extension CGPoint {
    enum pixelLocation {
        case upperLeft
        case upperRight
        case lowerLeft
        case lowerRight
        case nearest
    }
    
    ///Snap point to nearest pixel at specified location
    mutating func snap(to location:pixelLocation) {
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
}

extension CGSize {
    func maxDimension() -> CGFloat {
        return width > height ? width : height
    }
    
    func minDimension() -> CGFloat {
        return width < height ? width : height
    }
}

extension TimeInterval {
    var picoseconds: Double {
        get {
            return nanoseconds * 1000.0
        }
        set (newValue) {
           self.nanoseconds = newValue / 1000.0
        }
    }
    
    var nanoseconds: Double {
        get {
            return microseconds * 1000.0
        }
        set (newValue) {
            self.microseconds = newValue / 1000.0
        }
    }
    
    var microseconds: Double {
        get {
            return milliseconds * 1000.0
        }
        set (newValue) {
            self.milliseconds = newValue / 1000.0
        }
    }
    
    var milliseconds: Double {
        get {
            return self * 1000.0
        }
        set (newValue) {
            self = newValue / 1000.0
        }
    }
    
    var minutes: Double {
        get {
            return self/60.0
        }
        set (newValue) {
            self = newValue * 60.0
        }
    }
    
    var hours: Double {
        get {
            return minutes/60.0
        }
        set (newValue) {
            self.minutes = newValue * 60.0
        }
    }
    
    var days: Double {
        get {
            return hours/24.0
        }
        set (newValue) {
            self.hours = newValue * 24.0
        }
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
        
        return formatter.string(from: start, to: end) ?? String()
    }
}

extension UserDefaults {
    ///setObject(forKey:) where value != nil, removeObjectForKey where value == nil
    func setOrRemoveObject(_ value: Any?, forKey defaultName: String) {
        guard (value != nil) else {
            UserDefaults.standard.removeObject(forKey: defaultName)
            return
        }

        UserDefaults.standard.set(value, forKey: defaultName)
    }
}

extension CGAffineTransform {
    ///returns the current rotation of the transform in radians
    func rotationInRadians() -> Double {
        return Double(atan2f(Float(self.b), Float(self.a)))
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

extension FileManager {
    var documentsDirectoryPath:String? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path
    }

    func fileExistsInDocuments(atPath path:String) -> Bool {
        guard let documentsPath = self.documentsDirectoryPath else {
            return false
        }
        
        var pathURL:URL = URL(fileURLWithPath: documentsPath)
        pathURL.appendPathComponent(path)
        return fileExists(atPath: pathURL.path)
    }
    
    func removeItemInDocuments(atPath path:String) throws {
        guard let documentsPath = self.documentsDirectoryPath else {
            return
        }
        
        var pathURL:URL = URL(fileURLWithPath: documentsPath)
        pathURL.appendPathComponent(path)
        try removeItem(at: pathURL)
    }

    open var temporaryFile: URL {
        return temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }
}

extension NotificationCenter {
    open func post(name aName: NSNotification.Name) {
        post(name: aName, object: nil)
    }
    
    open func post(name aName: NSNotification.Name, userInfo aUserInfo: [AnyHashable : Any]?) {
        post(name: aName, object: nil, userInfo: aUserInfo)
    }
}

///Trivial UITableViewCell subclass that configures itself as hidden on creation
/// This is *very* useful for gracefully handling the return of an 'empty' cell from cellForRowAtIndexPath calls
/// Don't forget to register the class with your table first!
public class HiddenTableViewCell: UITableViewCell {
    static let reuseIdentifier:String = "com.cyberdev.UITableViewCell.HiddenTableViewCell"
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isHidden = true
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.isHidden = true
    }
}

extension Double {
    public static var π: Double {
        return .pi
    }
    
    public static var τ: Double {
        return .pi * 2.0
    }
}


