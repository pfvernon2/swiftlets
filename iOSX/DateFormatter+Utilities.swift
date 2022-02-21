//
//  NSDateFormatter+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/22/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

public extension DateFormatter {
    //MARK: - ISO 8601 Utilities
    static fileprivate var formatterCache:[String:DateFormatter] = [:]
    
    enum ISO8601ExtendedPrecision: Int, CaseIterable {
        case seconds, milliseconds, microseconds
        case java, windows
        
        public static var allCases: [ISO8601ExtendedPrecision] {
            [seconds, milliseconds, microseconds]
        }
    }
    
    /**
     Creates a date formatter for working with the ISO8601 date format.
     
     - Parameter  precision: (optional) see ISO8601ExtendedPrecision
     - returns: NSDateFormatter
     
     - note: As of iOS10 a system ISO 8601 formatter is availble. This class is (now) primarily
     useful for cases where you are dealing with formats specifying extended precision
     in the time field.
     */
    class func ISO8601DateTimeFormatter(_ precision:ISO8601ExtendedPrecision = .seconds) -> DateFormatter {
        //Create formatter; ignoring user locale
        let dateFormatterISO8601 = DateFormatter()
        dateFormatterISO8601.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale?
        
        //set format based precision specified
        switch precision {
        case .seconds:
            dateFormatterISO8601.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        case .milliseconds, .java:
            dateFormatterISO8601.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        case .microseconds, .windows:
            dateFormatterISO8601.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        }
        
        //Create Gregorian calender ignoring user locale calendar
        guard var gregorian:Calendar = NSCalendar(identifier: NSCalendar.Identifier.gregorian) as Calendar?,
              let timezone:TimeZone = NSTimeZone(abbreviation: "UMT") as TimeZone? else {
            return dateFormatterISO8601;
        }
        gregorian.timeZone = timezone
        dateFormatterISO8601.calendar = gregorian
        
        return dateFormatterISO8601
    }
    
    ///Return cached ISO8601 date formatter for thread safe operation, assumes >iOS7 || >OSX10.9+64bit
    class func cachedISO8601DateTimeFormatter(ofPrecision precision:ISO8601ExtendedPrecision = .seconds) -> DateFormatter {
        let formatterKey:String = "com.cyberdev.ISO8601Formatter.\(precision.rawValue)"
        if let formatter:DateFormatter = formatterCache[formatterKey] {
            return formatter
        } else {
            let formatter:DateFormatter = ISO8601DateTimeFormatter(precision)
            formatterCache[formatterKey] = formatter
            return formatter
        }
    }
    
    ///Attempts to parse a string to a date using one of the common variations on ISO8601 date time
    class func tryParseISO8601LikeDateString(_ date:String) -> Date? {
        for precision in ISO8601ExtendedPrecision.allCases {
            let formatter:DateFormatter = cachedISO8601DateTimeFormatter(ofPrecision: precision)
            if let result = formatter.date(from: date) {
                return result
            }
        }
        
        return nil
    }
    
    /**
     Return a localized string representation of a date and time where dates are expressed as relative to the curent date.
     
     The date is represented as either a localized representation of a relative date such as "Today" or "Tomorrow", or a localized version of the day of the week for dates within the last week (Sunday, Monday, Tuesday, etc.) For dates outside the last week the dateStyle format is used. The default is .medium: e.g.: Jan 1, 2000
     
     Time is represented in the requested format. Default is .short e.g.: 0:00 PM, or 00:00 if 24 hour time is configured on device
     
     - Parameter from: date to be represented
     - Parameter dateStyle: style for the date representation
     - Parameter timeStyle: style for the time representation
     
     - note: To avoid ambiguity the day of week representation does not use the name of the current day.
     In the Gregorian calendar, for example, this means that dates more than 6 days old are always represented as an absolute date.
     
     Examples:
     - Today 12:00 PM
     - Yesterday 23:00
     - Après-après-demain 06:00
     - Thursday 12:00 PM
     - Dec 25, 2016 6:00 AM
     */
    class func relativeDateTimeString(from date:Date, dateStyle:DateFormatter.Style = .medium, timeStyle:DateFormatter.Style = .short) -> String? {
        let calendar:Calendar = Calendar.autoupdatingCurrent
        
        let relativeDateFormatter:DateFormatter = DateFormatter()
        relativeDateFormatter.dateStyle = dateStyle
        relativeDateFormatter.timeStyle = .none
        relativeDateFormatter.doesRelativeDateFormatting = true
        
        let absoluteDateFormatter:DateFormatter =  DateFormatter()
        absoluteDateFormatter.dateStyle = dateStyle
        absoluteDateFormatter.timeStyle = .none
        absoluteDateFormatter.doesRelativeDateFormatting = false
        
        let absoluteTimeFormatter:DateFormatter = DateFormatter()
        absoluteTimeFormatter.dateStyle = .none
        absoluteTimeFormatter.timeStyle = timeStyle
        absoluteTimeFormatter.doesRelativeDateFormatting = false
        
        let relativeDateString:String = relativeDateFormatter.string(from: date)
        let absoluteDateString:String = absoluteDateFormatter.string(from: date)
        let absoluteTimeString:String = absoluteTimeFormatter.string(from: date)
        
        //Utility to append time to date as appropriate for formats specified
        func conditionalAppend(date:String, time:String, separator:String = " ") -> String? {
            switch (date.isEmpty, time.isEmpty) {
            case (true, true):
                return nil
            case (true, false):
                return time
            case (false, true):
                return date
            case (false, false):
                return date + separator + time
            }
        }
        
        //First, check to see if the relativeDateString has a value unique from the absoluteDateString.
        // note: this is a 'hack' to check to see if a language/calendar specific notion of relative date was
        // returned from the system. This may include values such as "Yesterday", "Tomorrow", "Après-après-demain", etc.
        guard absoluteDateString == relativeDateString else {
            return conditionalAppend(date: relativeDateString, time: absoluteTimeString)
        }
        
        //Get the number of days in the week for this calendar. I believe this is always 7 for all calendars but
        // this approach protects us should that assumption not hold true for all calendaring systems.
        // If this fails just return the system notion of the absolute date which is the best we can do.
        guard let lengthOfWeekInCalendar = calendar.maximumRange(of: .weekday)?.upperBound else {
            return conditionalAppend(date: absoluteDateString, time: absoluteTimeString)
        }
        
        //Assuming the current calendar has a concept of a week then get number of days between current date and the supplied date
        // so that we can determine if the date is within the length of the week as determined above.
        // If this fails just return the system notion of the absolute date which is the best we can do.
        guard let daysBetween:Int = calendar.dateComponents([.day],
                                                            from: calendar.startOfDay(for: Date()),
                                                            to: calendar.startOfDay(for: date)).day else
        {
            return conditionalAppend(date: absoluteDateString, time: absoluteTimeString)
        }
        
        //If we are inside the calendars concept of 'the last week' then return the localized day of the week for the date
        // otherwise return the absolute date
        if daysBetween < 0 && abs(daysBetween) < lengthOfWeekInCalendar {
            let dayofWeekFormatter:DateFormatter = DateFormatter()
            dayofWeekFormatter.setLocalizedDateFormatFromTemplate("EEEE")
            dayofWeekFormatter.doesRelativeDateFormatting = false
            
            let dayOfWeekString:String = dayofWeekFormatter.string(from: date)
            return conditionalAppend(date: dayOfWeekString, time: absoluteTimeString)
        } else {
            return conditionalAppend(date: absoluteDateString, time: absoluteTimeString)
        }
    }
}

public extension DateFormatter {
    static var shortDateTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter
    }
}

public class Timestamp {
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS "
        return formatter
    }()
    
    static var now: String {
        dateFormatter.string(from: Date())
    }
    
    class func then(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
}

public extension Date {
    static func daysBetween(start: Date, end: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
    
    //Get integer days between dates
    func daysBetween(date: Date) -> Int {
        Date.daysBetween(start: self, end: date)
    }
    
    //Get fractional days between dates
    func daysBetween(date: Date) -> Double {
        date.timeIntervalSince(self)/Double(Calendar.current.secondsPerDay())
    }
    
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
    
    func nextDay() -> Date? {
        Calendar.current.date(byAdding: DateComponents(day: 1),
                              to: self)
    }
    
    func startOfNextDay() -> Date? {
        nextDay()?.startOfDay()
    }
    
    func startOfNextMonth() -> Date? {
        let monthStart = Calendar.current.dateComponents([.year, .month], from: self)
        guard let monthStartDate = Calendar.current.date(from: monthStart) else {
            return nil
        }
        return Calendar.current.date(byAdding: DateComponents(month: 1),
                                     to: monthStartDate)
    }
    
    func startOfMonth() -> Date {
        let monthStart = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: monthStart) ?? self
    }
    
}

public extension Calendar {
    ///Returns veryShortWeekdaySymbols given a starting day of week.
    /// - Parameter starting: A value in range 1...week days of current calender
    func veryShortWeekdaySymbols(starting dayOfWeek: Int) -> [String] {
        guard dayOfWeek > 0 && dayOfWeek <= veryShortWeekdaySymbols.count else {
            return veryShortWeekdaySymbols
        }
        
        var symbols = veryShortWeekdaySymbols
        symbols.moveItemsToBack(from: IndexSet(0..<dayOfWeek-1))
        
        return symbols
    }
    
    ///Returns veryShortWeekdaySymbols given a ending day of week.
    /// - Parameter starting: A value in range 1...week days of current calender
    func veryShortWeekdaySymbols(ending dayOfWeek: Int) -> [String] {
        guard dayOfWeek > 0 && dayOfWeek <= veryShortWeekdaySymbols.count else {
            return veryShortWeekdaySymbols
        }
        
        var symbols = veryShortWeekdaySymbols
        symbols.moveItemsToFront(from: IndexSet(dayOfWeek..<veryShortWeekdaySymbols.count))
        
        return symbols
    }
    
    func monthOfYear(for date: Date = Date()) -> Int {
        dateComponents([.month], from: date).month ?? 0
    }
    
    ///Returns veryShortMonthSymbols given a ending month.
    /// - Parameter starting: A value in range 1...months of current calender
    func veryShortMonthSymbols(ending month: Int) -> [String] {
        guard month > 0 && month <= veryShortMonthSymbols.count else {
            return veryShortMonthSymbols
        }
        
        var symbols = veryShortMonthSymbols
        symbols.moveItemsToFront(from: IndexSet(month..<veryShortMonthSymbols.count))
        
        return symbols
        
    }
    
    func dayOfWeek(for date: Date = Date()) -> Int {
        dateComponents([.weekday], from: date).weekday ?? 0
    }
    
    func dayOfMonth(for date: Date = Date()) -> Int {
        dateComponents([.day], from: date).day ?? 0
    }
    
    func weekOfMonth(for date: Date = Date()) -> Int {
        dateComponents([.weekOfMonth], from: date).weekOfMonth ?? 0
    }
    
    func month(for date: Date = Date()) -> Int {
        dateComponents([.month], from: date).month ?? 0
    }

    func year(for date: Date = Date()) -> Int {
        dateComponents([.year], from: date).year ?? 0
    }
    
    func startOfCurrentDay() -> Date {
        startOfDay(for: Date())
    }
    
    func startOfNextDay() -> Date {
        startOfDay(for: date(byAdding: .day,
                             value: 1,
                             to: Date()) ?? Date())
    }
    
    func startOfCurrentWeek() -> Date {
        guard let weekDay = Calendar.current.dateComponents([.weekday], from: startOfCurrentDay()).weekday else {
            return startOfCurrentDay()
        }
        
        return Calendar.current.date(byAdding: DateComponents(weekday: -(weekDay-1)),
                                     to: startOfCurrentDay()) ?? startOfCurrentDay()
    }
    
    func startOfNextWeek() -> Date {
        guard let weekDay = dateComponents([.weekday], from: startOfCurrentDay()).weekday else {
            return startOfCurrentDay()
        }
        
        return date(byAdding: DateComponents(weekday: daysInWeek() - weekDay),
                    to: startOfCurrentDay()) ?? startOfCurrentDay()
    }
    
    func startOfCurrentMonth() -> Date {
        let monthStart = dateComponents([.year, .month], from: startOfCurrentDay())
        return date(from: monthStart) ?? startOfCurrentDay()
    }
    
    func startOfNextMonth() -> Date{
        date(byAdding: .month,
             value: 1,
             to: startOfCurrentMonth()) ?? startOfCurrentDay()
    }
    
    func startOfCurrentYear() -> Date {
        let year = dateComponents([.year], from: Date())
        return date(from: year) ?? startOfCurrentDay()
    }
    
    func startOfNextYear() -> Date {
        date(byAdding: .year,
             value: 1,
             to: startOfCurrentYear()) ?? startOfCurrentDay()
    }
    
    func secondsInMinute() -> Int {
        maximumRange(of: .second)?.count ?? 0
    }

    func minutesInHour() -> Int {
        maximumRange(of: .minute)?.count ?? 0
    }

    func hoursInDay() -> Int {
        maximumRange(of: .hour)?.count ?? 0
    }

    func daysInWeek() -> Int {
        maximumRange(of: .weekday)?.count ?? 0
    }
    
    func monthsInYear() -> Int {
        maximumRange(of: .month)?.count ?? 0
    }
    
    func secondsPerDay() -> Int {
        hoursInDay() * minutesInHour() * secondsInMinute()
    }
    
    func daysInMonth(for date: Date? = nil) -> Int {
        if let date = date {
            return range(of: .day, in: .month, for: date)?.count ?? 0
        } else {
            return Calendar.current.maximumRange(of: .day)?.count ?? 0
        }
    }
    
    func daysInCurrentMonth() -> Int {
        daysInMonth(for: Date())
    }
    
    //This is a tricky one... returns the number of days which
    // have elapsed in the specified month. If date is within the current month/year
    // return the current day of month. If date is in the future return 0
    func daysElapsedInMonth(for monthDate: Date) -> Int {
        let targetMonthComponents = dateComponents([.year, .month], from: monthDate)
        let currentMonthComponents = dateComponents([.year, .month], from: Date())

        let targetMonth = date(from: targetMonthComponents) ?? monthDate
        let currentMonth = date(from: currentMonthComponents) ?? Date()

        if targetMonth == currentMonth {
            return dateComponents([.day], from: Date()).day ?? 0
        } else if targetMonth > currentMonth {
            return 0
        } else {
            return range(of: .day, in: .month, for: monthDate)?.upperBound ?? 0
        }
    }
    
    func startOfMovingWeek() -> Date {
        let components = DateComponents(day: -daysInWeek())
        let startDate = startOfNextDay()
        return date(byAdding: components,
                    to: startDate) ?? Date()
    }
    
    func startOfMoving31Days() -> Date {
        let components = DateComponents(day: -31)
        let startDate = startOfNextDay()
        return date(byAdding: components,
                    to: startDate) ?? Date()
    }
    
    func startOfMovingMonth() -> Date {
        let components = DateComponents(month: -1)
        let startDate = startOfNextDay()
        return date(byAdding: components,
                    to: startDate) ?? Date()
    }
    
    func startOfMovingYear() -> Date {
        let components = DateComponents(year: -1)
        let startDate = startOfNextMonth()
        return Calendar.current.date(byAdding: components,
                                     to: startDate) ?? Date()
    }
    
    func rangeOfMovingWeek() -> (Date, Date) {
        (startOfMovingWeek(), startOfNextDay())
    }
    
    func rangeOfMovingMonth() -> (Date, Date) {
        (startOfMoving31Days(), startOfNextDay())
    }
    
    func rangeOfMovingYear() -> (Date, Date) {
        (startOfMovingYear(), startOfNextMonth())
    }
}
