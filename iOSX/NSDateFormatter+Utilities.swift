//
//  NSDateFormatter+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/22/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension NSDateFormatter {
    enum ISO8601ExtendedPrecision {
        case conforming, milliseconds, microseconds
        case java, windows
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
}