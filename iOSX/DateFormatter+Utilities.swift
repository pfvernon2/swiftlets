//
//  NSDateFormatter+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/22/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension DateFormatter {
    //MARK: - ISO 8601 Utilities
    static fileprivate var formatterCache:[String:DateFormatter] = [:]
    
    enum ISO8601ExtendedPrecision:Int,CaseIterable {
        case seconds, milliseconds, microseconds
        case java, windows
        
        static var allCases: [ISO8601ExtendedPrecision] {
            return [seconds, milliseconds, microseconds]
        }
    }
    
    /**
     Creates a date formatter for working with the ISO8601 date format.
     
     The 8601 format has been widely hijacked by various platforms and used in non-conforming ways.
     The optional parameter allows you to specify one of the typical non-conforming formats if required.
     
     - parameters:
         - precision: (optional) see ISO8601ExtendedPrecision
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

        //Create Gregorian; calender ignoring user locale calendar
        let gregorian = NSCalendar(identifier: NSCalendar.Identifier.gregorian)!
        gregorian.timeZone = NSTimeZone(abbreviation: "UMT")! as TimeZone
        dateFormatterISO8601.calendar = gregorian as Calendar?
        
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
     
     The date is represented as either a language specific representation of a relative date such as "Today" or "Tomorrow", or a localized version of the day of the
     week for dates within the last week. For dates outside the last week the dateStyle format is used. The default is .medium: e.g.: Jan 1, 2000
     
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
    class func relativeDateTimeString(from date:Date, dateStyle:DateFormatter.Style = .medium, timeStyle:DateFormatter.Style = .short) -> String {
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
        
        //First, check to see if the relativeDateString has a value unique from the absoluteDateString.
        // note: this is a 'hack' to check to see if a language/calendar specific notion of relative date was
        // returned from the system. This may include values such as "Yesterday", "Tomorrow", "Après-après-demain", etc.
        guard absoluteDateString == relativeDateString else {
            return "\(relativeDateString) \(absoluteTimeString)"
        }
        
        //Get the number of days in the week for this calendar. I believe this is always 7 for all calendars but
        /// this approach protects us should that assumption not hold true for all calendaring systems.
        // If this fails just return the system notion of the absolute date which is the best we can do.
        guard let lengthOfWeekInCalendar = calendar.maximumRange(of: .weekday)?.count else {
            return "\(absoluteDateString) \(absoluteTimeString)"
        }
        
        //Assuming the current calendar has a concept of a week then get number of days between current date and the supplied date
        // so that we can determine if the date is within the length of the week as determined above.
        // If this fails just return the system notion of the absolute date which is the best we can do.
        guard let daysBetween:Int = calendar.dateComponents([.day],
                                                            from: calendar.startOfDay(for: Date()),
                                                            to: calendar.startOfDay(for: date)).day else
        {
            return "\(absoluteDateString) \(absoluteTimeString)"
        }
        
        //If we are inside the calendars concept of 'the last week' then return the localized day of the week for the date
        // otherwise return the absolute date
        if daysBetween < 0 && abs(daysBetween) < lengthOfWeekInCalendar {
            let dayofWeekFormatter:DateFormatter = DateFormatter()
            dayofWeekFormatter.setLocalizedDateFormatFromTemplate("EEEE")
            dayofWeekFormatter.doesRelativeDateFormatting = false
            
            let dayOfWeekString:String = dayofWeekFormatter.string(from: date)
            return "\(dayOfWeekString) \(absoluteTimeString)"
        } else {
            return "\(absoluteDateString) \(absoluteTimeString)"
        }
    }
}
