//
//  DataMagnitude.swift
//  swiftlets
//
//  Created by Frank Vernon on 10/20/19.
//  Copyright © 2019 Frank Vernon. All rights reserved.
//

import Foundation

//MARK: - DecimalMagnitude

enum DecimalMagnitude: Double, CaseIterable {
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

    ///Convert value to associated order of magnitude.
    ///
    ///  Examples:
    ///  * 1500 units = 1.5 kilo-units
    ///  * 1500 kilo-units = 1.5 mega-units
    func toMagnitude(_ units: Double, fromMagnitude: DecimalMagnitude = DecimalMagnitude.uni) -> Double {
        (units * fromMagnitude.rawValue) / rawValue
    }

    ///Convert value from associated order of magnitude.
    ///
    ///  Examples:
    ///  * 1.5 kilo-units = 1500 units
    ///  * 1.5 mega-units = 1500 kilo-units
    func fromMagnitude(_ units: Double, toMagnitude: DecimalMagnitude = DecimalMagnitude.uni) -> Double {
        rawValue * (units / toMagnitude.rawValue)
    }

    ///Get nearest DecimalMagnitude enum for given value
    ///
    ///  Examples:
    ///  * 0.001 = .milli
    ///  * 1000.0 = .kilo
    ///  * 15000.0 = .kilo
    ///  * 1000000000000000000000000.0 = .yota
    static func magnitude(_ units: Double) -> DecimalMagnitude {
        //get order of magnitude of input
        let mag: Int = Int(floor(log10(units.magnitude)))

        //get index of case <= magnitude...
        // clamp to upper/lower bounds for values outside range
        var index: Int? = allMagnitudes().lastIndex(where: {$0 <= mag})
        if index == nil {
            index = units.magnitude < 1.0 ? 0 : (allCases.count - 1)
        }

        //force unwrap guarded by test for nil above
        return allCases[index!]
    }

    ///Get value converted to nearest DecimalMagnitude
    ///
    ///  Examples:
    ///  * 0.001 = (1.0, .milli)
    ///  * 1000.0 = (1.0, .kilo)
    ///  * 15000.0 = (15.0, .kilo)
    ///  * 100000000000000000000000000.0 = (100.0, .yota)
    static func toNearestMagnitude(_ units: Double) -> (Double, DecimalMagnitude) {
        let mag = magnitude(units)
        return (mag.toMagnitude(units), mag)
    }

    //Get magnitude values associated with allCases
    private static func allMagnitudes() -> [Int] {
        allCases.map {Int(log10($0.rawValue))}
    }
}

//MARK: - BinaryMagnitude

enum BinaryMagnitude: Double, CaseIterable {
    case uni  = 0x01p0
    case kibi = 0x01p10
    case mebi = 0x01p20
    case gibi = 0x01p30
    case tebi = 0x01p40
    case pebi = 0x01p50
    case exbi = 0x01p60
    case zebi = 0x01p70
    case yobi = 0x01p80

    ///Convert value to associated order of magnitude.
    ///
    ///  Example:
    ///  * 1024 units = 1 kibi-units
    func toMagnitude(_ units: Double, fromMagnitude: BinaryMagnitude = BinaryMagnitude.uni) -> Double {
        (units * fromMagnitude.rawValue) / rawValue
    }

    ///Convert value from associated order of magnitude.
    ///
    ///  Example:
    ///  * 1 kibi-units = 1024 units
    func fromMagnitude(_ units: Double, toMagnitude: BinaryMagnitude = BinaryMagnitude.uni) -> Double {
        rawValue * (units / toMagnitude.rawValue)
    }

    ///Get nearest BinaryMagnitude enum for given value
    ///
    ///  Examples:
    ///  * 1024.0 = .kibi
    ///  * 10000.0 = .kibi
    ///  * 2000000000.0 = .gibi
    static func magnitude(_ units: Double) -> BinaryMagnitude {
        //get order of magnitude of input
        let mag: Int = Int(floor(log10(units.magnitude)))

        //get index of case <= magnitude...
        // clamp to upper/lower bounds for values outside range
        var index: Int? = allMagnitudes().lastIndex(where: {$0 <= mag})
        if index == nil {
            index = units.magnitude < 1.0 ? 0 : (allCases.count - 1)
        }

        //force unwrap guarded by test for nil above
        return allCases[index!]
    }

    ///Get value converted to nearest BinaryMagnitude
    ///
    ///  Examples:
    ///  * 0.001 = (1.0, .milli)
    ///  * 1000.0 = (1.0, .kilo)
    ///  * 15000.0 = (15.0, .kilo)
    ///  * 100000000000000000000000000.0 = (100.0, .yota)
    static func toNearestMagnitude(_ units: Double) -> (Double, BinaryMagnitude) {
        let mag = magnitude(units)
        return (mag.toMagnitude(units), mag)
    }

    //Get magnitude values associated with allCases
    private static func allMagnitudes() -> [Int] {
        allCases.map {Int(log10($0.rawValue))}
    }
}
