//
//  MKMapKit+Helpers.swift
//  swiftlets
//
//  Created by Frank Vernon on 4/24/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation
import MapKit
import Contacts
import AddressBook

let mileMeterRatio = 1609.344
let meterToDegreesRatio = 111325.0

///A simple typealias to maintain explicit distance typing
typealias CLLocationDistanceMiles = CLLocationDistance

fileprivate func metersToMiles(_ meters:CLLocationDistance) -> CLLocationDistanceMiles {
    return meters / mileMeterRatio
}

fileprivate func milesToMeters(_ miles:CLLocationDistanceMiles) -> CLLocationDistance {
    return miles * mileMeterRatio
}

///This approximates degrees of travel on the surface of the earth for both latitude and longitude. It is *NOT* accurate for navigation.
func metersToApproximateDegreesLatLong(_ meters:CLLocationDistance) -> Double {
    return meters / meterToDegreesRatio
}

fileprivate func radiansToDegrees(_ radians: Double) -> Double {
    return radians * 180.0 / .pi
}

fileprivate func degreesToRadians(_ degrees: Double) -> Double {
    return degrees * .pi / 180.0
}

let kCLLocationDirectionInvalid:CLLocationDirection = -1.0
extension CLLocationDirection {
    func isValidDirection() -> Bool {
        return self >= 0.0
    }
    
    public enum CLLocationDirectionMotion {
        case clockwise, counterclockwise
        case right, left
        
        func reverse() -> CLLocationDirectionMotion {
            switch self {
            case .clockwise, .right:
                return .counterclockwise
            case .counterclockwise, .left:
                return .clockwise
            }
        }
    }
    
    ///Returns the absolute value of the smallest angle difference between two directions and an indication of the direction of change
    /// This is useful in determining both the magnitude and direction of the change of heading.
    func headingChangeTo(_ other:CLLocationDirection) -> (magnitude:CLLocationDirection, motion:CLLocationDirectionMotion) {
        guard self.isValidDirection() && other.isValidDirection() else {
            return (kCLLocationDirectionInvalid, .clockwise)
        }
        
        var angle:CLLocationDirection
        var motion:CLLocationDirectionMotion
        if self > other {
            angle = self - other
            motion = .counterclockwise
        } else {
            angle = other - self
            motion = .clockwise
        }
        
        if angle > 180.0 {
            angle = 360.0 - angle
            motion = motion.reverse()
        }
        
        return (angle, motion)
    }
    
    var radians:Double {
        get {
            return degreesToRadians(self)
        }
    }
}

extension CLLocationDistance {
    func isValidDistance() -> Bool {
        return self != CLLocationDistance.nan
    }
    
    func toMiles() -> CLLocationDistanceMiles {
        return metersToMiles(self)
    }
}

extension MKRouteStep {
    var distanceMiles:CLLocationDistanceMiles {
        return distance.toMiles()
    }
}

extension MKRoute {
    var distanceMiles:CLLocationDistanceMiles {
        return distance.toMiles()
    }
    
    /**
     Returns a localized human readable description of the time interval.
     
     - note: The result is limited to Days, Hours, and Minutes and includes a localized indication of approximation.
     
     Examples:
     * About 14 minutes
     * About 1 hour, 7 minutes
     */
    var expectedTravelTimeLocalizedDescription:String {
        return expectedTravelTime.approximateDurationLocalizedDescription()
    }
}

extension MKMapPoint {
    init(coordinate: CLLocationCoordinate2D) {
        let mapPoint = MKMapPointForCoordinate(coordinate)
        self.init()
        self.x = mapPoint.x
        self.y = mapPoint.y
    }
    
    func distanceTo(point:MKMapPoint) -> CLLocationDistance {
        return MKMetersBetweenMapPoints(self, point)
    }
    
    func bearingTo(point: MKMapPoint) -> CLLocationDirection {
        let x = point.x - self.x
        let y = point.y - self.y
        
        var result = radiansToDegrees(atan2(y, x)).truncatingRemainder(dividingBy: 360.0) + 90.0
        if result < 0.0 {
            result = 360.0 + result
        }
        
        return result
    }
    
    var coordinate:CLLocationCoordinate2D {
        get {
            return MKCoordinateForMapPoint(self)
        }
    }
}

extension MKMapPoint: Equatable {}

public func ==(lhs: MKMapPoint, rhs: MKMapPoint) -> Bool {
    return (lhs.x == rhs.x && lhs.y == rhs.y)
}

extension MKMapRect {
    func contains(point:MKMapPoint) -> Bool {
        return MKMapRectContainsPoint(self, point)
    }
    
    func contains(rect:MKMapRect) -> Bool {
        return MKMapRectContainsRect(self, rect)
    }
    
    func intersects(rect:MKMapRect) -> Bool {
        return MKMapRectIntersectsRect(self, rect)
    }
}

extension MKCoordinateRegion {
    init(centerCoordinate: CLLocationCoordinate2D,
         latitudinalMeters: CLLocationDistance,
         longitudinalMeters: CLLocationDistance) {
        let region = MKCoordinateRegionMakeWithDistance(centerCoordinate,
                                                        latitudinalMeters,
                                                        longitudinalMeters)
        
        self.init()
        self.center = region.center
        self.span = region.span
    }
    
    ///Determine if a location is within the region
    func contains(location:CLLocationCoordinate2D) -> Bool {
        return location.latitude >= center.latitude - span.latitudeDelta &&
            location.latitude <= center.latitude + span.latitudeDelta &&
            location.longitude >= center.longitude - span.longitudeDelta &&
            location.longitude <= center.longitude + span.longitudeDelta
    }
    
    func boundingCoordinates() -> (northWest:CLLocationCoordinate2D, southEast:CLLocationCoordinate2D) {
        let northWest:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: center.latitude + (span.latitudeDelta/2.0),
                                                                      longitude: center.longitude - (span.longitudeDelta/2.0))
        let southEast:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: center.latitude - (span.latitudeDelta/2.0),
                                                                      longitude: center.longitude + (span.longitudeDelta/2.0))
        
        return (northWest, southEast)
    }
    
    ///Returns the radius of the bounding box defined by the region.
    func boundingRadius() -> CLLocationDistance {
        let (northWest, southEast) = boundingCoordinates()
        
        guard let northWestLocation:CLLocation = CLLocation(location: northWest),
            let southEastLocation:CLLocation = CLLocation(location: southEast) else {
                return CLLocationDistance.nan
        }
        
        let circumference:CLLocationDistance = northWestLocation.distance(from: southEastLocation)
        return circumference/2.0
    }
}

extension MKMapView {
    ///The maximum length in meters of current viewport
    func maxDimension() -> CLLocationDistance {
        let topLeft:MKMapPoint = visibleMapRect.origin
        let topRight:MKMapPoint = MKMapPoint(x: visibleMapRect.origin.x + visibleMapRect.size.width,
                                             y: visibleMapRect.origin.y)
        let bottomRight:MKMapPoint = MKMapPoint(x: visibleMapRect.origin.x + visibleMapRect.size.width,
                                                y: visibleMapRect.origin.y + visibleMapRect.size.height)
        
        
        let horizontalMeters = MKMetersBetweenMapPoints(topLeft, topRight)
        let verticalMeters = MKMetersBetweenMapPoints(topRight, bottomRight)
        
        return max(horizontalMeters, verticalMeters)
    }
    
    ///meters per pixel for current viewport
    func metersPerPixel() -> CLLocationDistance {
        return MKMetersPerMapPointAtLatitude(centerCoordinate.latitude) * visibleMapRect.size.width / Double(bounds.size.width)
    }
}

extension MKMapItem {
    convenience init(coordinate:CLLocationCoordinate2D) {
        self.init(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
    }
    
    convenience init(location:CLLocation) {
        self.init(placemark: MKPlacemark(coordinate: location.coordinate, addressDictionary: nil))
    }
}

extension CLLocationCoordinate2D: Equatable {}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return (lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude)
}

extension CLLocationCoordinate2D {
    func isValid() -> Bool {
        //May need to implement non-zero check here as well
        return CLLocationCoordinate2DIsValid(self)
    }
    
    /// Returns absolute bearing to specified location
    /// - note: This not accurate on large scales.
    /// MKMapPoint should be used for earth projections.
    func bearingTo(_ location:CLLocationCoordinate2D) -> CLLocationDirection {
        let x = self.longitude - location.longitude
        let y = self.latitude - location.latitude
        
        return fmod(radiansToDegrees(atan2(y, x)), 360.0) + 90.0
    }
    
    func greatCircleDistance(toLocation location:CLLocationCoordinate2D) -> CLLocationDistance {
        guard self.isValid() && location.isValid() else {
            return CLLocationDistance.nan
        }
        
        let sourceLocation:CLLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let destinationLocation:CLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return sourceLocation.distance(from: destinationLocation)
    }
    
    func tween(_ location:CLLocationCoordinate2D, percent:Double) -> CLLocationCoordinate2D {
        var progressCoordinate:CLLocationCoordinate2D = self
        progressCoordinate.latitude -= (self.latitude - location.latitude) * percent
        progressCoordinate.longitude -= (self.longitude - location.longitude) * percent
        return progressCoordinate
    }
}

extension CLLocation {
    public convenience init?(location:CLLocationCoordinate2D) {
        guard location.isValid() else {
            return nil
        }
        
        self.init(latitude: location.latitude, longitude: location.longitude)
    }
    
    /// Calculate approximate relative bearing to another location, if we have a course. This not completely accurate on large scales.
    /// MKMapPoint should be used for those purposes.
    ///
    /// See CLLocationCoordinate2D for absolute bearing
    ///
    /// - note: CLLocationDirection is always specified as a positive value so result may be larger than 180
    ///
    func relativeBearingTo(location:CLLocation) -> CLLocationDirection {
        guard self.course.isValidDirection() &&
            coordinate.isValid() &&
            location.coordinate.isValid() else {
                return -1.0
        }
        
        let absoluteBearing = coordinate.bearingTo(location.coordinate)
        if absoluteBearing >= course {
            return absoluteBearing - course
        } else {
            return 360.0 - course - absoluteBearing
        }
    }
    
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        guard let otherLocation:CLLocation = CLLocation(location:coordinate) else {
            return CLLocationDistanceMax
        }
        return distance(from: otherLocation)
    }
}

extension MKDirectionsResponse {
    public func greatCircleDistance() -> CLLocationDistance {
        if let sourceLocation:CLLocation = self.source.placemark.location,
            let destinationLocation:CLLocation = self.destination.placemark.location
        {
            return sourceLocation.distance(from: destinationLocation)
        } else {
            return CLLocationDistance.nan
        }
    }
    
    public func minimumRouteDistance() -> CLLocationDistance {
        return routes.reduce(Double.infinity) { (result, route) -> CLLocationDistance in
            return min(route.distance, result)
        }
    }
    
    public func minimumRouteTravelTime() -> TimeInterval {
        return routes.reduce(Double.infinity) { (result, route) -> CLLocationDistance in
            return min(route.expectedTravelTime, result)
        }
    }
}

extension CLPlacemark {
    func postalAddressFromAddressDictionary() -> CNMutablePostalAddress {
        let postalAddress = CNMutablePostalAddress()
        
        if let addressDictionary = addressDictionary {
            //Note: As of iOS9 kABPersonAddressStreetKey is deprecated but CNPostalAddress.street is not a direct replacment
            postalAddress.street = addressDictionary["Street"] as? String ?? ""
            postalAddress.state = addressDictionary["State"] as? String ?? ""
            postalAddress.city = addressDictionary["City"] as? String ?? ""
            postalAddress.country = addressDictionary["Country"] as? String ?? ""
            postalAddress.postalCode = addressDictionary["ZIP"] as? String ?? ""
        }
        
        return postalAddress
    }
    
    func localizedStringForAddressDictionary() -> String {
        return CNPostalAddressFormatter.string(from: postalAddressFromAddressDictionary(), style: .mailingAddress)
    }
    
    ///Unwrap internal dictionary of [AnyHashable:Any] to [String:Any] required by other interfaces
    func unwrappedAddressDictionary() -> [String : Any] {
        var result:[String : Any] = [:]
        
        addressDictionary?.forEach({ (element) in
            if let keyString:String = element.key as? String {
                result[keyString] = element.value
            }
        })
        
        return result
    }
}

