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

extension MKRouteStep {
    var distanceMiles:Double {
        return metersToMiles(distance)
    }
}

extension MKRoute {
    var distanceMiles:Double {
        return metersToMiles(distance)
    }
    
    var expectedTravelTimeLocalizedDescription:String {
        //TODO: actually localized and smarter time formatter here
        let minutes = ceil(expectedTravelTime/60.0)
        return "\(minutes.format("0.0")) Minutes"
    }
}

extension MKCoordinateRegion {
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
    func boundingRadiusMeters() -> Double {
        let (northWest, southEast) = boundingCoordinates()

        let northWestLocation:CLLocation = CLLocation(location: northWest)
        let southEastLocation:CLLocation = CLLocation(location: southEast)

        let circumfrance:Double = northWestLocation.distanceFromLocation(southEastLocation)
        return circumfrance/2.0
    }
}

extension MKMapView {
    ///The maximum length in meters of current viewport
    func maxDimensionMeters() -> Double {
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
    func metersPerPixel() -> Double {
        return MKMetersPerMapPointAtLatitude(centerCoordinate.latitude) * visibleMapRect.size.width / Double(bounds.size.width)
    }
}

extension CLLocationCoordinate2D {
    func isEqualTo(location:CLLocationCoordinate2D?) -> Bool {
        if let otherLocation = location {
            return otherLocation.latitude == self.latitude && otherLocation.longitude == self.longitude
        } else {
            return false
        }
    }

    /// Check that location is valid
    ///
    /// - note: This is a hack… 0.0;0.0 is a valid location. It is, however, also the default location
    ///  returned when coordinate acquisition fails… Apple really needs an 'invalid' flag on this class
    func isNonZero() -> Bool {
        return latitude != 0.0 && longitude != 0.0
    }


    //CLLocationCoordinate2DIsValid
}

extension CLLocation {
    public convenience init(location:CLLocationCoordinate2D) {
        self.init(latitude: location.latitude, longitude: location.longitude)
    }
    
    /// Check that location is valid
    ///
    /// - note: This is a hack… 0.0;0.0 is a valid location. It is, however, also the default location
    ///  returned when coordinate acquisition fails… Apple really needs an 'invalid' flag on this class
    func isValid() -> Bool {
        return self.coordinate.isNonZero()
    }
}

extension MKDirectionsResponse {
    public func greatCircleDistance() -> CLLocationDistance {
        if let sourceLocation = self.source.placemark.location, destinationLocation = self.destination.placemark.location {
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

