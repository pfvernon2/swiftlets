//
//  TimeInterval+Period.swift
//  swiftlets
//
//  Created by Frank Vernon on 8/22/19.
//  Copyright © 2019 Frank Vernon. All rights reserved.
//

import Foundation

///Enum of TimeInterval (i.e. seconds) to various calendar units.
/// This useful for getting rough order of magnitude for a TimeInterval value.
/// - note: Calendaring is complicated. Use DateComponents if you need
/// to reliably break things down. This is useful for primarily for determining order of magnitude
/// and should not be used for date calculations.
public enum TimePeriod: Double {
    public typealias RawValue = Double

    case picoSecond = 0.000000000001
    case nanoSecond = 0.000000001
    case microSecond = 0.000001
    case milliSecond = 0.001
    case second = 1.0
    case minute = 60.0
    case hour = 3600.0
    case day = 86400.0
    case week = 604800.0
    case month = 2419200.0
    case year = 31449600.0 //Gregorian calendar year
    case leapYear = 31536000.0 //Gregorian calendar leap year

    ///Convert a TimeInterval to a rough order of magnitude of calendar units.
    init(_ interval: TimeInterval) {
        switch fabs(interval) {
        case ..<60.0:
            self = .second
        case ..<3600.0:
            self = .minute
        case ..<86400.0:
            self = .hour
        case ..<604800.0:
            self = .day
        case ..<2419200.0:
            self = .week
        case ..<31449600.0:
            self = .month
        default:
            self = .year
        }
    }

    ///Convert TimeInterval to TimePeriod:
    ///  66 seconds = 1.1 minutes
    func periodForInterval(_ interval: TimeInterval) -> Double {
        interval / rawValue
    }

    ///Convert TimePeriod to TimeInterval:
    ///  1.1 minutes = 66 seconds
    func intervalForPeriod(_ period: Double) -> TimeInterval {
        rawValue * period
    }
}

public extension TimeInterval {
    ///Convenience initializer for creating TimeInterval from
    /// commonly used time periods.
    /// - note: The values passed are cumulative.
    init(days: Double = 0.0,
         hours: Double = 0.0,
         minutes: Double = 0.0,
         seconds: Double = 0.0,
         milliseconds: Double = 0.0,
         microseconds: Double = 0.0,
         nanoseconds: Double = 0.0,
         picoseconds: Double = 0.0) {
        var accumulator: TimeInterval = 0.0

        accumulator += TimePeriod.day.intervalForPeriod(days)
        accumulator += TimePeriod.hour.intervalForPeriod(hours)
        accumulator += TimePeriod.minute.intervalForPeriod(minutes)
        accumulator += TimePeriod.second.intervalForPeriod(seconds)
        accumulator += TimePeriod.milliSecond.intervalForPeriod(milliseconds)
        accumulator += TimePeriod.microSecond.intervalForPeriod(microseconds)
        accumulator += TimePeriod.nanoSecond.intervalForPeriod(nanoseconds)
        accumulator += TimePeriod.picoSecond.intervalForPeriod(picoseconds)

        self.init(accumulator)
    }

    var picoseconds: Double {
        get {
            TimePeriod.picoSecond.periodForInterval(self)
        }
        set (newValue) {
            self = TimePeriod.picoSecond.intervalForPeriod(newValue)
        }
    }

    var nanoseconds: Double {
        get {
            TimePeriod.nanoSecond.periodForInterval(self)
        }
        set (newValue) {
            self = TimePeriod.nanoSecond.intervalForPeriod(newValue)
        }
    }

    var microseconds: Double {
        get {
            TimePeriod.microSecond.periodForInterval(self)
        }
        set (newValue) {
            self = TimePeriod.microSecond.intervalForPeriod(newValue)
        }
    }

    var milliseconds: Double {
        get {
            TimePeriod.milliSecond.periodForInterval(self)
        }
        set (newValue) {
            self = TimePeriod.milliSecond.intervalForPeriod(newValue)
        }
    }

    //This is the native format for TimeInterval but included here for
    // consistency and to further the abstraction.
    var seconds: Double {
        get {
            TimePeriod.second.periodForInterval(self)
        }
        set (newValue) {
            self = TimePeriod.second.intervalForPeriod(newValue)
        }
    }

    var minutes: Double {
        get {
            TimePeriod.minute.periodForInterval(self)
        }
        set (newValue) {
            self = TimePeriod.minute.intervalForPeriod(newValue)
        }
    }

    var hours: Double {
        get {
            TimePeriod.hour.periodForInterval(self)
        }
        set (newValue) {
            self = TimePeriod.hour.intervalForPeriod(newValue)
        }
    }

    var days: Double {
        get {
            TimePeriod.day.periodForInterval(self)
        }
        set (newValue) {
            self = TimePeriod.day.intervalForPeriod(newValue)
        }
    }

    /**
     Returns a localized human readable description of the time interval.

     - note: The result is limited to Days, Hours, and Minutes and optionally includes a localized indication of approximation.

     Examples:
     * 14 minutes
     * About 1 hour, 7 minutes
     */
    func durationLocalizedDescription(approximation: Bool = false) -> String {
        let start = Date()
        let end = Date(timeInterval: self, since: start)

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.includesApproximationPhrase = approximation
        formatter.includesTimeRemainingPhrase = false
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.maximumUnitCount = 2

        return formatter.string(from: start, to: end) ?? String()
    }
    
    /**
     Returns a localized description of the time interval.

     - note: The result is limited to Days, Hours, and Minutes.
     */
    func localizedDescription(style: DateComponentsFormatter.UnitsStyle = .positional) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = style
        return formatter.string(from: self) ?? String()
    }
    
    ///Non-localized version of the time interval suitable for display as a music/video track time. This is similar to the way the music app displays track times.
    ///
    ///Examples:
    ///* 2d:4h:3m:30s = 52:03:30
    ///* 4h:3m:30s = 4:03:30
    ///* 3m:30s = 3:30
    ///* 30s = 0:30
    ///* -30s = -0:30
    func trackTimeDescription() -> String {
        guard self != .infinity else {
            return ""
        }
        
        let absInterval = abs(self)
        
        //Deconstruct TimeInterval into hours:mins:seconds
        //Not using DateComponents as I want hours to be the max value represented.
        let hours = floor(absInterval/TimePeriod.hour.rawValue)
        let minutes = floor((absInterval - (hours * TimePeriod.hour.rawValue))/TimePeriod.minute.rawValue)
        let seconds = floor(absInterval - ((minutes * TimePeriod.minute.rawValue) + (hours * TimePeriod.hour.rawValue)))

        var timeDescription: String
        if hours > 0.0 {
            timeDescription = String(format: "%d:%0.2d:%0.2d", Int(hours), Int(minutes), Int(seconds))
        } else {
            timeDescription = String(format: "%0.1d:%0.2d", Int(minutes), Int(seconds))
        }
        
        if self < 0 {
            timeDescription = "-\(timeDescription)"
        }
        
        return timeDescription
    }
}
