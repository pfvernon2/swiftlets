//
//  Miscellaneous.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/31/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import QuartzCore

extension CGRect {
    var center:CGPoint {
        CGPoint(x: self.midX, y: self.midY)
    }
    
    static func rectCenteredOn(center:CGPoint, radius:CGFloat) -> CGRect {
        CGRect(x: floor(center.x - radius),
               y: floor(center.y - radius),
               width: floor(radius*2.0),
               height: floor(radius*2.0))
    }
    
    var top:CGFloat {
        self.origin.y - self.size.height
    }
    
    var bottom:CGFloat {
        self.origin.y
    }
    
    var left:CGFloat {
        self.origin.x
    }
    
    var right:CGFloat {
        self.origin.x + self.size.width
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
        width > height ? width : height
    }
    
    func minDimension() -> CGFloat {
        width < height ? width : height
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
        urls(for: .documentDirectory, in: .userDomainMask).first?.path
    }

    func fileExistsInDocuments(atPath path:String) -> Bool {
        guard let documentsPath = documentsDirectoryPath else {
            return false
        }
        
        var pathURL:URL = URL(fileURLWithPath: documentsPath)
        pathURL.appendPathComponent(path)
        return fileExists(atPath: pathURL.path)
    }
    
    func removeItemInDocuments(atPath path:String) throws {
        guard let documentsPath = documentsDirectoryPath else {
            return
        }
        
        var pathURL:URL = URL(fileURLWithPath: documentsPath)
        pathURL.appendPathComponent(path)
        try removeItem(at: pathURL)
    }

    open var temporaryFile: URL {
        temporaryDirectory.appendingPathComponent(UUID().uuidString)
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

extension Double {
    public static var π: Double {
        .pi
    }
    
    public static var τ: Double {
        .pi * 2.0
    }

    func truncate(to places: Int) -> Double {
        Double(Int(pow(10, Double(places)) * self)) / pow(10, Double(places))
    }
}

fileprivate var bitsPerByte: Int = 8
extension FixedWidthInteger {
    ///Utility to get number of bytes in the integer
    public var byteWidth: Int {
        bitWidth/bitsPerByte
    }

    ///subscript access to bytes in big endian, i.e. network, byte order
    public subscript(index: Int) -> UInt8? {
        guard index < byteWidth else {
            return nil
        }

        let shift = index * bitsPerByte;
        return UInt8(bigEndian >> shift & 0xFF)
    }

    ///extract bytes from an integer in big endian, i.e. network, byte order
    //Should be a sequence extension?
    public var bytes:[UInt8] {
        var bytes: [UInt8] = []
        
        for i in 0..<byteWidth {
            //force unwrap guarded by byteWidth limit
            bytes.append(self[i]!)
        }

        return bytes
    }
}
