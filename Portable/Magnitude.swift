//
//  Magnitude.swift
//  swiftlets
//
//  Created by Frank Vernon on 10/20/19.
//  Copyright © 2019 Frank Vernon. All rights reserved.
//

import Foundation

///Types that conform to OrderOfMagnitude are typically enumerations
/// that associate a power with a symbolic representation.
/// For example ISO prefixes for decimal (base 10) orders of magnitude: 1.0e3 = k
public protocol OrderOfMagnitude: CaseIterable {
    //An array of the powers of the magnitudes
    static var powers: [Int] {get}

    //An array of the symbols associated with the magnitudes
    static var symbols: [String] {get}

    //symbol for the current magnitude
    var symbol:String {get}
}

public extension OrderOfMagnitude where Self: Equatable, Self: RawRepresentable {
    static var powers: [Int] {
        allCases.map {Int(log10($0.rawValue as! Double))}
    }

    var symbol: String {
        get {
            Self.symbols[caseIndex()]
        }
    }

    func caseIndex() -> Int {
        //force unwrap protected by logical requirement that self be in the array of allCases
        Self.allCases.firstIndex(of: self) as! Int
    }
}

///Enum of ISO prefixes for decimal (base 10) orders of magnitude
public enum DecimalMagnitude: Double, OrderOfMagnitude {
    case yocto = 1.0e-24
    case zepto = 1.0e-21
    case atto  = 1.0e-18
    case femto = 1.0e-15
    case pico  = 1.0e-12
    case nano  = 1.0e-9
    case micro = 1.0e-6
    case milli = 1.0e-3
    case centi = 1.0e-2
    case deci  = 1.0e-1
    case uni   = 1.0e0
    case deca  = 1.0e1
    case hecto = 1.0e2
    case kilo  = 1.0e3
    case mega  = 1.0e6
    case giga  = 1.0e9
    case tera  = 1.0e12
    case peta  = 1.0e15
    case exa   = 1.0e18
    case zeta  = 1.0e21
    case yota  = 1.0e24
    case hella  = 1.0e27

    public static var symbols: [String] {
        ["y", "z", "a", "f", "p", "n", "µ", "m", "c", "d",
         "",
         "㍲", "h", "k", "M", "G", "T", "P", "E", "Z", "Y", "H"]
    }
}

///Enum of IEC and IEEE 1541 prefixes for binary (base 2) orders of magnitude
public enum BinaryMagnitude: Double, OrderOfMagnitude {
    case uni  = 0x01p0
    case kibi = 0x01p10
    case mebi = 0x01p20
    case gibi = 0x01p30
    case tebi = 0x01p40
    case pebi = 0x01p50
    case exbi = 0x01p60
    case zebi = 0x01p70
    case yobi = 0x01p80
    case hebi = 0x01p90

    public static var symbols: [String] {
        ["",
         "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi", "Yi", "Hi"]
    }
}

//Protocol for converting values to and from orders of magnitude
public protocol MagnitudeConversion {
    associatedtype T: OrderOfMagnitude

    ///Convert value to associated order of magnitude.
    ///
    ///  Examples:
    ///  * 1500 units = 1.5 kilo-units
    ///  * 1500 kilo-units = 1.5 mega-units
    func toMagnitude(_ units: Double, fromMagnitude: T) -> Double

    ///Convert value from associated order of magnitude.
    ///
    ///  Examples:
    ///  * 1.5 kilo-units = 1500 units
    ///  * 1.5 mega-units = 1500 kilo-units
    func fromMagnitude(_ units: Double, toMagnitude: T) -> Double

    ///Get nearest magnitude enum for given value
    ///
    ///  Examples:
    ///  * 0.001 = .milli
    ///  * 1000.0 = .kilo
    ///  * 15000.0 = .kilo
    ///  * 1000000000000000000000000.0 = .yota
    static func magnitude(_ units: Double) -> T

    ///Get value converted to nearest OrderOfMagnitude
    ///
    ///  Examples:
    ///  * 0.001 = (1.0, .milli)
    ///  * 1000.0 = (1.0, .kilo)
    ///  * 1024.0 = (1.0, .kibi)
    ///  * 4194304.0 = (4.0, .mebi)
    static func toNearestMagnitude(_ units: Double) -> (Double, T)
}

extension MagnitudeConversion where Self: Equatable, Self: RawRepresentable, Self: CaseIterable, T: RawRepresentable, T: CaseIterable {
    public func toMagnitude(_ units: Double, fromMagnitude: T) -> Double {
        (units * (fromMagnitude.rawValue as! Double)) / (rawValue as! Double)
    }

    public func fromMagnitude(_ units: Double, toMagnitude: T) -> Double {
        (rawValue as! Double) * (units / (toMagnitude.rawValue as! Double))
    }

    public static func magnitude(_ units: Double) -> T {
        //get order of magnitude of input
        let mag: Int = Int(floor(log10(units.magnitude)))

        //get index of case <= magnitude...
        // clamp to upper/lower bounds for values outside range
//        var index: Int? = T.powers.lastIndex(where: {$0 <= mag})
//        if index == nil {
//            index = units.magnitude < 1.0 ? 0 : (allCases.count - 1)
//        }

        if let index: T.AllCases.Index = T.powers.lastIndex(where: {$0 <= mag}) as? Self.T.AllCases.Index {
            return T.allCases[index]
        } else if units.magnitude < 1.0 {
            return T.allCases.first!
        } else {
            return T.allCases[allCases.count - 1 as! Self.T.AllCases.Index]
        }
    }
}

extension DecimalMagnitude: MagnitudeConversion {
    //Cannot be generic on MagnitudeConversion due to reliance on '.uni'
    public static func toNearestMagnitude(_ units: Double) -> (Double, DecimalMagnitude) {
        let mag = magnitude(units)
        return (mag.toMagnitude(units, fromMagnitude: .uni), mag)
    }
}

extension BinaryMagnitude: MagnitudeConversion {
    //Cannot be generic on MagnitudeConversion due to reliance on '.uni'
    public static func toNearestMagnitude(_ units: Double) -> (Double, BinaryMagnitude) {
        let mag = magnitude(units)
        return (mag.toMagnitude(units, fromMagnitude: .uni), mag)
    }
}

public extension Double {
    var nearestDecimalMagnitude: (Double, DecimalMagnitude) {
        DecimalMagnitude.toNearestMagnitude(self)
    }

    var nearestBinaryMagnitude: (Double, BinaryMagnitude) {
        BinaryMagnitude.toNearestMagnitude(self)
    }
}
