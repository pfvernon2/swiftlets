//
//  NSDateFormatter+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/22/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension NSDateFormatter {
    static private var formatterCache:[String:NSDateFormatter] = [:]
    
    enum ISO8601ExtendedPrecision:Int {
        case conforming, milliseconds, microseconds
        case java, windows
        
        static let allValues = [conforming, milliseconds, microseconds]
    }
    
    /**
     Creates a date formatter for working with the ISO8601 date format.
     
     The 8601 format has been widely hijacked by various platforms and used in non-conforming ways.
     The optional parameter allows you to specify one of the typical non-conforming formats if required.
     
     - parameters:
         - precision: (optional) see ISO8601ExtendedPrecision
     - returns: NSDateFormatter
     */
    class func ISO8601Formatter(precision:ISO8601ExtendedPrecision = .conforming) -> NSDateFormatter {
        //Create formatter; ignoring user locale
        let dateFormatterISO8601 = NSDateFormatter()
        dateFormatterISO8601.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        //set format based precision specified
        switch precision {
        case .conforming:
            dateFormatterISO8601.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        case .milliseconds, .java:
            dateFormatterISO8601.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        case .microseconds, .windows:
            dateFormatterISO8601.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        }

        //Create Gregorian; calender ignoring user locale calendar
        let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        gregorian.timeZone = NSTimeZone(abbreviation: "GMT")!
        dateFormatterISO8601.calendar = gregorian
        
        return dateFormatterISO8601
    }
    
    ///Return cached ISO8601 date formatter for thread safe operation, assumes >iOS7 || >OSX10.9+64bit
    class func ISO8601FormatterCached(precision:ISO8601ExtendedPrecision = .conforming) -> NSDateFormatter {
        let formatterKey:String = "com.cyberdev.ISO8601Formatter.\(precision.rawValue)"
        if let formatter:NSDateFormatter = formatterCache[formatterKey] {
            return formatter
        } else {
            let formatter:NSDateFormatter = ISO8601Formatter(precision)
            formatterCache[formatterKey] = formatter
            return formatter
        }
    }
    
    ///Attempts to parse a string to a date using one of the common variations on ISO8601
    class func tryParseISO8601LikeDateString(date:String) -> NSDate? {
        for precision in ISO8601ExtendedPrecision.allValues {
            let formatter:NSDateFormatter = ISO8601FormatterCached(precision)
            if let result = formatter.dateFromString(date) {
                return result
            }
        }
        
        return nil
    }
}