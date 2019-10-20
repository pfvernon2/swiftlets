//
//  TimeInterval+Period.swift
//  swiftlets
//
//  Created by Frank Vernon on 8/22/19.
//  Copyright © 2019 Frank Vernon. All rights reserved.
//

import Foundation

//Enumeration to abstract converting TimeInterval to commonly used
// time periods.
enum TimePeriod: Double {
    typealias RawValue = Double

    case picoSecond = 0.000000000001
    case nanoSecond = 0.000000001
    case microSecond = 0.000001
    case milliSecond = 0.001
    case second = 1.0
    case minute = 60.0
    case hour = 3600.0
    case day = 86400.0

    //convert TimeInterval to TimePeriod:
    //  66 seconds = 1.1 minutes
    func periodForInterval(_ interval: TimeInterval) -> Double {
        interval / rawValue
    }

    //convert TimePeriod to TimeInterval:
    //  1.1 minutes = 66 seconds
    func intervalForPeriod(_ period: Double) -> TimeInterval {
        rawValue * period
    }
}

extension TimeInterval {

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
}
