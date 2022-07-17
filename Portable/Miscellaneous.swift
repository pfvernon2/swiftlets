//
//  Miscellaneous.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/31/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import QuartzCore
import CoreServices
import UIKit

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

public extension Bool {
    func flipCoin() -> Bool {
        Bool.random()
    }
}

public extension Double {
    static var halfPi: Double {
        Double.pi / 2.0
    }
    
    static var π: Double {
        Double.pi
    }
    
    static var τ: Double {
        Double.pi * 2.0
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
        
    static var unity: CGFloat = 1.0
    
    static var alphaMin: CGFloat = 0.0
    static var alphaMax: CGFloat = 1.0
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

    static var unity: Float = 1.0

    static var opacityMin: Float = 0.0
    static var opacityMax: Float = 1.0
    
    func truncate(to places: Int) -> Float {
        Float(Int(pow(10, Float(places)) * self)) / pow(10, Float(places))
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
}

public extension Int {
    //TODO: should be protocol/generic on Numeric
    func rounded(toInterval interval: Int) -> Int {
        Int(Double(self).rounded(toInterval: Double(interval)))
    }
    
    //TODO: integrate this with other calls using rounding rules
    func roundedDown(toInterval interval: Int) -> Int {
        guard self > 0 else {
            return 0
        }
        
        return Int((Double(self)/Double(interval)).rounded(.down) * Double(interval))
    }
    
    //TODO: integrate this with other calls using rounding rules
    func roundedUp(toInterval interval: Int) -> Int {
        Int((Double(self)/Double(interval)).rounded(.up) * Double(interval))
    }
    
    var halved: Int {
        self / 2
    }

    var doubled : Int {
        self * 2
    }

    func rollDice(sides: Int = 6) -> Int {
        Int.random(in: 1...sides)
    }
    
    func rollDice(sides: Int = 6, count: Int = 2) -> [Int] {
        Array<Int>(count: count) { _ in rollDice(sides: sides) }
    }
}

public extension BinaryInteger {
    func percentage<T: BinaryInteger>(of whole: T) -> Float {
        guard whole != .zero else {
            return .zero
        }
        
        return Float(Double(self) / Double(whole))
    }
}

public extension FloatingPoint {
    func percentage<T: FloatingPoint>(of whole: T) -> T {
        guard whole != .zero else {
            return .zero
        }

        return self as! T / whole
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
    ///Return index of current case in allCases.
    func caseIndex() -> Self.AllCases.Index {
        //force unwrap protected by logical requirement
        // that self be in the array of allCases
        Self.allCases.firstIndex(of: self)!
    }
    
    ///Return next element in allCases or wrap to first.
    func next() -> Self {
        let nextIndex = Self.allCases.index(after: caseIndex(), wrap: true)
        return Self.allCases[nextIndex]
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
        
        //find specified type
        let type: Dictionary<String, Any>? = types.first {
            guard let dict : Dictionary<String, Any> = $0 as? Dictionary<String, Any> else {
                return false
            }
            
            return dict[kUTTypeDescriptionKey as String] as? String == desc
        } as? Dictionary<String, Any>
        
        //get tag specification
        guard let typeTag: Dictionary<String, Any> = type?[kUTTypeTagSpecificationKey as String] as? Dictionary<String, Any> else {
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

public extension IndexPath {
    static var zero: IndexPath {
        IndexPath(row: 0, section: 0)
    }
}

public extension UIControl.State {
    static var all: UIControl.State {
        [.normal, .highlighted, .disabled, .selected, .focused, .application]
    }
}

public func TimingBlock(label: String = "⏱", _ block : (() -> Void)) {
    let start = DispatchTime.now()
    defer {
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        let timeInterval = Double(nanoTime) * DecimalMagnitude.nano.rawValue
        print("\(label) - \(timeInterval) seconds")
    }
    
    block()
}
