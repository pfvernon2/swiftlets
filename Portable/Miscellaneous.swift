//
//  Miscellaneous.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/31/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import QuartzCore
import CoreServices

public extension UIBezierPath {
    ///Draws a vertical line at the given x, y for the given height
    func addVerticalLine(at point: CGPoint, ofHeight height: CGFloat) {
        move(to: point)
        addLine(to: CGPoint(x: point.x, y: point.y + height))
    }
    
    ///Draws a horizontal line at the given x, y for the given width
    func addHorizontalLine(at point: CGPoint, ofWidth width: CGFloat) {
        move(to: point)
        addLine(to: CGPoint(x: point.x + width, y: point.y))
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

            if i == 0 {
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
        self.size.height
    }
    
    var left:CGFloat {
        self.origin.x
    }
    
    var right:CGFloat {
        self.size.width
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

public extension CGPoint {
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

public extension CGSize {
    func maxDimension() -> CGFloat {
        max(width, height)
    }
    
    func minDimension() -> CGFloat {
        min(width, height)
    }
    
    static var ɸ: CGFloat = 1.61803398874989484820
    
    static func goldenRectangleFor(width: CGFloat) -> CGSize {
        CGSize(width: width, height: ceil(width/ɸ))
    }
    
    static func goldenRectangleFor(height: CGFloat) -> CGSize {
        CGSize(width: ceil(height * ɸ), height: height)
    }
}

public extension UserDefaults {
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

extension CACornerMask {
    public static var topLeft: CACornerMask = { layerMinXMinYCorner }()
    public static var lowerLeft: CACornerMask = { layerMinXMaxYCorner }()
    public static var topRight: CACornerMask = { layerMaxXMinYCorner }()
    public static var lowerRight: CACornerMask = { layerMaxXMaxYCorner }()
}

///Trivial indexing generator that wraps back to startIndex when reaching endIndex
public class WrappingIndexingGenerator<C: Collection>: IteratorProtocol {
    var _collection: C
    var _index: C.Index
    
    public func next() -> C.Iterator.Element? {
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

public extension FileManager {
    var documentsDirectory: URL {
        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
          fatalError("unable to locate system document directory")
        }
        
        return docURL
    }
    
    var cacheDirectory: URL {
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
          fatalError("unable to locate system cache directory")
        }
        
        return cacheURL
    }
    
    var appSupportDirectory: URL {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
          fatalError("unable to locate system cache directory")
        }
        
        return appSupport

    }
    
    func fileExistsInDocuments(atPath path: String) -> Bool {
        let pathURL: URL = documentsDirectory.appendingPathComponent(path)
        return fileExists(atPath: pathURL.path)
    }
    
    func removeItemInDocuments(atPath path: String) throws {
        let pathURL: URL = documentsDirectory.appendingPathComponent(path)
        try removeItem(at: pathURL)
    }

    var temporaryFile: URL {
        temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }
    
    ///Creates a unique file name in the given directory using the Apple convention of appending
    /// numbers to the end of the file name.
    func uniqueURL(in dir: URL, name: String, type: String) -> URL {
        var result = dir.appendingPathComponent(name).appendingPathExtension(type)
        
        var attempt = 0
        while fileExists(atPath: result.path) {
            attempt += 1
            result = dir.appendingPathComponent("\(name) \(attempt)").appendingPathExtension(type)
        }
        
        return result
    }
}

public extension URL {
    ///returns tuple of (file name, file extension) or nil if URL is a directory
    var filenameExtension: (String, String)? {
        guard !hasDirectoryPath else {
            return nil
        }
        return (deletingPathExtension().lastPathComponent, pathExtension)
    }
}

public extension NotificationCenter {
    func post(name aName: NSNotification.Name) {
        post(name: aName, object: nil)
    }
    
    func post(name aName: NSNotification.Name, userInfo aUserInfo: [AnyHashable : Any]?) {
        post(name: aName, object: nil, userInfo: aUserInfo)
    }
}

public extension Double {
    static var halfPi: Double {
        .pi / 2.0
    }
    
    static var π: Double {
        .pi
    }
    
    static var τ: Double {
        π.doubled
    }

    func truncate(to places: Int) -> Double {
        Double(Int(pow(10, Double(places)) * self)) / pow(10, Double(places))
    }
}

public extension CGFloat {
    //TODO: should be protocol/generic on Numeric
    func rounded(toInterval interval:CGFloat) -> CGFloat {
        let closest = interval * (self / interval).rounded()
        return closest
    }
    var halved: CGFloat {
          self / 2.0
      }

      var doubled : CGFloat {
          self * 2.0
      }

      func percentage(of whole: CGFloat) -> CGFloat {
          return self / whole
    }
}

public extension Float {
    //TODO: should be protocol/generic on Numeric
    func rounded(toInterval interval:Float) -> Float {
        let closest = interval * (self / interval).rounded()
        return closest
    }
    
    var halved: Float {
        self / 2.0
    }

    var doubled : Float {
        self * 2.0
    }

    func percentage(of whole: Float) -> Float {
        return self / whole
    }

}

public extension Double {
    //TODO: should be protocol/generic on Numeric
    func rounded(toInterval interval:Double) -> Double {
        let closest = interval * (self / interval).rounded()
        return closest
    }
    
    var halved: Double {
        self / 2.0
    }

    var doubled : Double {
        self * 2.0
    }

    func percentage(of whole: Double) -> Double {
        return self / whole
    }

}

public extension Int {
    //TODO: should be protocol/generic on Numeric
    func rounded(toInterval interval:Int) -> Int {
        Int(Double(self).rounded(toInterval: Double(interval)))
    }
    
    //TODO: integrate this with other calls using rouding rules
    func roundedDown(toInterval interval:Int) -> Int {
        Int((Double(self)/Double(interval)).rounded(.down) * Double(interval))
    }
    
    var halved: Int {
        self / 2
    }

    var doubled : Int {
        self * 2
    }

    func percentage(of whole: Int) -> Double {
        return Double(self) / Double(whole)
    }
}

fileprivate var bitsPerByte: Int = 8
public extension FixedWidthInteger {
    ///Utility to get number of bytes in the integer
    var byteWidth: Int {
        bitWidth/bitsPerByte
    }

    ///subscript access to bytes in big endian, i.e. network, byte order
    subscript(index: Int) -> UInt8? {
        guard index < byteWidth else {
            return nil
        }

        let shift = index * bitsPerByte;
        return UInt8(bigEndian >> shift & 0xFF)
    }

    ///extract bytes from an integer in big endian, i.e. network, byte order
    //Should be a sequence extension?
    var bytes:[UInt8] {
        var bytes: [UInt8] = []
        
        for i in 0..<byteWidth {
            //force unwrap guarded by byteWidth limit
            bytes.append(self[i]!)
        }

        return bytes
    }
}

public extension CaseIterable where Self: Equatable {
    ///return index of current case in allCases
    func caseIndex() -> Self.AllCases.Index {
        //force unwrap protected by logical requirement that self
        // be in the array of allCases
        Self.allCases.firstIndex(of: self)!
    }
}

public extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

public extension Strideable where Stride: SignedInteger {
    func clamped(to limits: CountableClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

public extension Bundle {
    func fileExtension(forType desc:String) -> String? {
        fileExtensions(forType: desc)?.first
    }

    func fileExtensions(forType desc:String) -> [String]? {
        //get exported type declarations
        guard let types: Array<Any> = object(forInfoDictionaryKey: kUTExportedTypeDeclarationsKey as String) as? Array<Any> else {
            return nil
        }
        
        //find playlist element
        let playlistType: Dictionary<String, Any>? = types.first {
            guard let dict : Dictionary<String, Any> = $0 as? Dictionary<String, Any> else {
                return false
            }
            
            return dict[kUTTypeDescriptionKey as String] as? String == desc
        } as? Dictionary<String, Any>
        
        //get tag specification
        guard let typeTag: Dictionary<String, Any> = playlistType?[kUTTypeTagSpecificationKey as String] as? Dictionary<String, Any> else {
            return nil
        }
        
        //get array of types
        guard let extensions: Array<String> = typeTag["public.filename-extension"] as? Array<String> else {
            return nil
        }

        return extensions
    }

}

public extension UIScreen {
    class var externalDisplays: [UIScreen] {
       UIScreen.screens.filter { $0 != UIScreen.main }
    }
    
    class var availableDisplays: [UIScreen] {
        externalDisplays.filter { !$0.isCaptured }
    }
}
