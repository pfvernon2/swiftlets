//
//  MKMapKit+Helpers.swift
//  Apple Maps Demo
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

func metersToMiles(meters:Double) -> Double {
    return meters / mileMeterRatio
}

func milesToMeters(miles:Double) -> Double {
    return miles * mileMeterRatio
}

///This approximates degrees of travel on the surface of the earth for both latitude and longitude. It is *NOT* accurate for navigation.
func metersToApproximateDegreesLatLong(meters:Double) -> Double {
    return meters / meterToDegreesRatio
}

func radiansToDegrees(radians: Double) -> Double {
    return radians * 180.0 / M_PI;
}

func degreesToRadians(degrees: Double) -> Double {
    return degrees * M_PI / 180
}

let kCLLocationDirectionInvalid:CLLocationDirection = -1.0
extension CLLocationDirection {
    func isValid() -> Bool {
        return self >= 0.0
    }

    public enum CLLocationDirectionMotion {
        case clockwise, anticlockwise

        func reverse() -> CLLocationDirectionMotion {
            switch self {
            case .clockwise:
                return .anticlockwise
            case .anticlockwise:
                return .clockwise
            }
        }
    }

    ///Returns the absolute value of the smallest angle difference between two directions and an indication of the direction of change
    /// This is useful in determining both the magnitude and direction of the change of heading.
    func headingChangeTo(other:CLLocationDirection) -> (magnitude:CLLocationDirection, motion:CLLocationDirectionMotion) {
        guard self.isValid() && other.isValid() else {
            return (kCLLocationDirectionInvalid, .clockwise)
        }

        var angle:CLLocationDirection
        var motion:CLLocationDirectionMotion
        if self > other {
            angle = self - other
            motion = .anticlockwise
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
}

extension MKRouteStep {
    var distanceMiles:Double {
        return metersToMiles(distance)
    }
}

extension MKRoute {
    var distanceMiles:Double {
        return metersToMiles(distance)
    }

    /**
    Returns a localized human readable description of the time interval.

     - note: The result is limited to Days, Hours, and Minutes and includes an indication of approximation.

     Examples:
     * About 14 minutes
     * About 1 hour, 7 minutes
    */
    var expectedTravelTimeLocalizedDescription:String {
        let start = NSDate()
        let end = NSDate(timeInterval: expectedTravelTime, sinceDate: start)

        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = .Full
        formatter.includesApproximationPhrase = true
        formatter.includesTimeRemainingPhrase = false
        formatter.allowedUnits = [.Day, .Hour, .Minute]
        formatter.maximumUnitCount = 2

        return formatter.stringFromDate(start, toDate: end) ?? ""
    }
}

extension MKMapPoint {
    init(coordinate: CLLocationCoordinate2D) {
        let mapPoint = MKMapPointForCoordinate(coordinate)
        self.x = mapPoint.x
        self.y = mapPoint.y
    }

    func distanceTo(point:MKMapPoint) -> CLLocationDistance {
        return MKMetersBetweenMapPoints(self, point)
    }

    func bearingTo(otherPoint: MKMapPoint) -> CLLocationDirection {
        let x = otherPoint.x - self.x
        let y = otherPoint.y - self.y

        var result = radiansToDegrees(atan2(y, x)) % 360.0 + 90.0
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

extension MKMapRect {
    func containsPoint(point:MKMapPoint) -> Bool {
        return MKMapRectContainsPoint(self, point)
    }

    func containsRect(rect:MKMapRect) -> Bool {
        return MKMapRectContainsRect(self, rect)
    }

    func intersectsRect(rect:MKMapRect) -> Bool {
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

        self.center = region.center
        self.span = region.span
    }

    ///Determine if a location is within the region
    func locationInRegion(location:CLLocationCoordinate2D) -> Bool {
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

    ///Returns the radius (in meters) of the bounding box defined by the region.
    func boundingRadius() -> CLLocationDistance {
        let (northWest, southEast) = boundingCoordinates()

        let northWestLocation:CLLocation = CLLocation(location: northWest)
        let southEastLocation:CLLocation = CLLocation(location: southEast)

        let circumfrance:Double = northWestLocation.distanceFromLocation(southEastLocation)
        return circumfrance/2.0
    }
}

extension MKMapView {
    ///The maximum length in meters of current viewport
    func maxDimensionMeters() -> CLLocationDistance {
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

extension CLLocationCoordinate2D {
    func isEqualTo(location:CLLocationCoordinate2D?) -> Bool {
        if let location = location {
            return location.latitude == self.latitude && location.longitude == self.longitude
        } else {
            return false
        }
    }

    func isValid() -> Bool {
        //May need to implement non-zero check here as well
        return CLLocationCoordinate2DIsValid(self)
    }

    /// Returns absolute bearing to specified location
    /// - note: This not accurate on large scales.
    /// MKMapPoint should be used for earth projections.
    func bearingTo(location:CLLocationCoordinate2D) -> CLLocationDirection {
        let x = self.longitude - location.longitude;
        let y = self.latitude - location.latitude;

        return fmod(radiansToDegrees(atan2(y, x)), 360.0) + 90.0;
    }

    func greatCircleDistanceTo(location:CLLocationCoordinate2D) -> CLLocationDistance {
        guard self.isValid() && location.isValid() else {
            return CLLocationDistance.NaN
        }

        let sourceLocation:CLLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let destinationLocation:CLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return sourceLocation.distanceFromLocation(destinationLocation)
    }

    func tween(location:CLLocationCoordinate2D, percent:Double) -> CLLocationCoordinate2D {
        var progressCoordinate:CLLocationCoordinate2D = self
        progressCoordinate.latitude -= (self.latitude - location.latitude) * percent
        progressCoordinate.longitude -= (self.longitude - location.longitude) * percent
        return progressCoordinate
    }
}

extension CLLocation {
    public convenience init(location:CLLocationCoordinate2D) {
        self.init(latitude: location.latitude, longitude: location.longitude)
    }
    
    /// Calculate approximate relative bearing to another location, if we have a course. This not completely accurate on large scales.
    /// MKMapPoint should be used for those purposes.
    ///
    /// See CLLocationCoordinate2D for absolute bearing
    ///
    /// - note: CLLocationDirection is always specified as a positive value so result may be larger than 180
    ///
    func relativeBearingTo(other:CLLocation) -> CLLocationDirection {
        guard self.course.isValid() &&
            coordinate.isValid() &&
            other.coordinate.isValid() else {
            return -1.0
        }

        let absoluteBearing = coordinate.bearingTo(other.coordinate)
        if absoluteBearing >= course {
            return absoluteBearing - course
        } else {
            return 360.0 - course - absoluteBearing
        }
    }
}

extension MKDirectionsResponse {
    public func greatCircleDistance() -> CLLocationDistance {
        if let sourceLocation:CLLocation = self.source.placemark.location,
            let destinationLocation:CLLocation = self.destination.placemark.location
        {
            return sourceLocation.distanceFromLocation(destinationLocation)
        } else {
            return CLLocationDistance.NaN
        }
    }
    
    public func minimumRouteDistance() -> CLLocationDistance {
        var minDistanceMeters:CLLocationDistance = Double.infinity;
        routes.forEach { (route) in
            minDistanceMeters = min(route.distance, minDistanceMeters)
        }
        return minDistanceMeters
    }

    public func minimumRouteTravelTime() -> NSTimeInterval {
        var minTravelTime:NSTimeInterval = Double.infinity;
        routes.forEach { (route) in
            minTravelTime = min(route.expectedTravelTime, minTravelTime)
        }
        return minTravelTime
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
        return CNPostalAddressFormatter.stringFromPostalAddress(postalAddressFromAddressDictionary(), style: .MailingAddress)
    }
}

