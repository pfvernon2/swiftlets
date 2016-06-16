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

let mileMeterRatio = 1609.344
let meterToDegreesRatio = 111000.0

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
    func isValid() -> Bool {
        return latitude != 0.0 && longitude != 0.0
    }
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
        return self.coordinate.isValid()
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
            postalAddress.street = addressDictionary[CNPostalAddressStreetKey] as? String ?? ""
            postalAddress.state = addressDictionary[CNPostalAddressStateKey] as? String ?? ""
            postalAddress.city = addressDictionary[CNPostalAddressCityKey] as? String ?? ""
            postalAddress.country = addressDictionary[CNPostalAddressCountryKey] as? String ?? ""
            postalAddress.postalCode = addressDictionary[CNPostalAddressPostalCodeKey] as? String ?? ""
        }
        
        return postalAddress
    }
    
    func localizedStringForAddressDictionary() -> String {
        return CNPostalAddressFormatter.stringFromPostalAddress(postalAddressFromAddressDictionary(), style: .MailingAddress)
    }
}

