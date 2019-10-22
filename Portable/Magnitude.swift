//
//  DataMagnitude.swift
//  swiftlets
//
//  Created by Frank Vernon on 10/20/19.
//  Copyright © 2019 Frank Vernon. All rights reserved.
//

import Foundation

enum DecimalMagnitude: Double {
    case yocto = 0.000000000000000000000001
    case zepto = 0.000000000000000000001
    case atto = 0.000000000000000001
    case femto = 0.000000000000001
    case pico = 0.000000000001
    case nano = 0.000000001
    case micro = 0.000001
    case milli = 0.001
    case centi = 0.01
    case deci = 0.1
    case uni = 1.0
    case deca = 10.0
    case hecto = 100.0
    case kilo = 1000.0
    case mega = 1000000.0
    case giga = 1000000000.0
    case tera = 1000000000000.0
    case peta = 1000000000000000.0
    case exa = 1000000000000000000.0
    case zeta = 1000000000000000000000.0
    case yota = 1000000000000000000000000.0

    ///Convert value to associated order of magnitude.
    ///  Example: 1500 units = 1.5 kilo-units
    func toMagnitude(_ units: Double, fromMagnitude: DecimalMagnitude = DecimalMagnitude.uni) -> Double {
        (units * fromMagnitude.rawValue) / rawValue
    }

    ///Convert value from associated order of magnitude.
    ///  Example: 1.5 kilo-units = 1500 units
    func fromMagnitude(_ units: Double, toMagnitude: DecimalMagnitude = DecimalMagnitude.uni) -> Double {
        rawValue * (units / toMagnitude.rawValue)
    }
}

enum BinaryMagnitude: Double {
    case uni = 1.0
    case kibi = 1024.0
    case mebi = 1048576.0
    case gibi = 1073741824.0
    case tebi = 1099511627776.0
    case pebi = 1125899906842624.0
    case exbi = 1152921504606846976.0
    case zebi = 1180591620717411303424.0
    case yobi = 1208925819614629174706176.0

    ///Convert value to associated order of magnitude.
    ///  Example: 1024 units = 1 kibi-units
    func toMagnitude(_ units: Double, fromMagnitude: BinaryMagnitude = BinaryMagnitude.uni) -> Double {
        (units * fromMagnitude.rawValue) / rawValue
    }

    ///Convert value from associated order of magnitude.
    ///  Example: 1 kibi-units = 1024 units
    func fromMagnitude(_ units: Double, toMagnitude: BinaryMagnitude = BinaryMagnitude.uni) -> Double {
        rawValue * (units / toMagnitude.rawValue)
    }
}
