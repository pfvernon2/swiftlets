//
//  MKMapView+Zoom.swift
//  Apple Maps Demo
//
//  Created by Frank Vernon on 4/23/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation
import MapKit

let kANNOTATION_LAT_PAD_FACTOR:CLLocationDegrees = 1.1
let kANNOTATION_LONG_PAD_FACTOR:CLLocationDegrees = 1.1
let kMAX_DEGREES_ARC:CLLocationDegrees = 360.0
let kMINIMUM_ZOOM_ARC:CLLocationDegrees = 0.014 //approximately 1 mile (1 degree of arc ~= 69 miles)

extension MKMapView {
    func zoomMapViewToFitAnnotations() {
        if annotations.count == 0 {
            return
        }
        
        var coordinates:[CLLocationCoordinate2D] = []
        annotations.forEach { (annotation) in
            coordinates.append(annotation.coordinate)
        }
        
        let polygon:MKPolygon = MKPolygon(coordinates: &coordinates, count: coordinates.count)
        let mapRect:MKMapRect = polygon.boundingMapRect
        
        var region:MKCoordinateRegion = MKCoordinateRegionForMapRect(mapRect)
        region.span.latitudeDelta  *= kANNOTATION_LAT_PAD_FACTOR * 2.0
        region.span.longitudeDelta *= kANNOTATION_LONG_PAD_FACTOR * 2.0
        
        //enforce min/max
        region.span.latitudeDelta = min(region.span.latitudeDelta, kMAX_DEGREES_ARC)
        region.span.longitudeDelta = min(region.span.longitudeDelta, kMAX_DEGREES_ARC)
        region.span.latitudeDelta = max(region.span.latitudeDelta, kMINIMUM_ZOOM_ARC)
        region.span.longitudeDelta = max(region.span.longitudeDelta, kMINIMUM_ZOOM_ARC)
        
        setRegion(region, animated: true)
    }
    
    func animateAnnotationViewDrop(annotationView:MKAnnotationView, closure:()->()) {
        let dropPoint:MKMapPoint = MKMapPointForCoordinate(annotationView.annotation!.coordinate)
        if MKMapRectContainsPoint(self.visibleMapRect, dropPoint) {
            let endRect = annotationView.frame
            var startRect = endRect
            startRect.origin.y -= self.frame.size.height
            
            annotationView.frame = startRect
            UIView .animateWithDuration(0.5, animations: {
                annotationView.frame = endRect
                },
                                        completion:
                { (finished) in
                    UIView .animateWithDuration(0.15, animations: {
                        annotationView.transform = CGAffineTransformMakeScale(1.0, 0.8);
                        },
                        completion:
                        { (finished) in
                            annotationView.transform = CGAffineTransformIdentity;
                            closure()
                    })
            })
        }
        
    }
}