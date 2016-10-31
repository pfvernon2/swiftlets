//
//  Date+JSONTransformable.swift
//  swiftlets
//
//  Created by Frank Vernon on 10/26/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

///JSONTransformable protocol implementation for Date assuming a standard ISO8601 format is desired.
/// If you are using a non-standard ISO8601 format (for example common Java or Microsoft formats using sub-second precision)
/// then you may want to replace this implementation with your own.
extension Date: JSONTransformable {
    public func toJSONType() -> JSON {
        return JSON(ISO8601DateFormatter().string(from: self))
    }
    
    public static func fromJSONType(json:JSON) -> Date? {
        guard let jsonString:String = json.asString else {
            return nil
        }
        
        return ISO8601DateFormatter().date(from: jsonString)
    }
}

extension JSON {
    public var asDate:Date? {
        return Date.fromJSONType(json: self)
    }
}
