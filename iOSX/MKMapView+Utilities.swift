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
    func zoomMapViewToFitAnnotations(coordinates:[CLLocationCoordinate2D]?) {
        if annotations.count == 0 {
            return
        }
        
        //if no coordinates supplied then grab everything on the map
        var mapCoordinates:[CLLocationCoordinate2D] = coordinates ?? []
        if mapCoordinates.isEmpty {
            annotations.forEach { (annotation) in
                mapCoordinates.append(annotation.coordinate)
            }
        }
        
        let polygon:MKPolygon = MKPolygon(coordinates: &mapCoordinates, count: mapCoordinates.count)
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

    /**
    Animate the removal of annotations from the map view.
    The animations closure gives you access to a snapshot view of the annotation for you to perform animations on

     ```
     self.mapView.removeAnnotations(annotations, duration: 0.5, animations: { (view) in
        view.alpha = 0.0
     })
     ```
     */
    func removeAnnotations(annotations: [MKAnnotation], duration: NSTimeInterval, animations: (view:UIView) -> Void) {
        let visibleAnnotations:Set = annotationsInMapRect(visibleMapRect)
        var animationAnnotations:[MKAnnotation] = []
        annotations.forEach { (annotation) in
            if visibleAnnotations.contains(annotation as! NSObject) {
                animationAnnotations.append(annotation)
            }
        }

        var snapshots:[UIView] = []
        animationAnnotations.forEach { (annotation) in
            if let annotationView:UIView = viewForAnnotation(annotation) {
                let snapshotView:UIView = annotationView.snapshotViewAfterScreenUpdates(false)
                snapshotView.frame = annotationView.frame
                snapshots.append(snapshotView)
                annotationView.superview?.insertSubview(snapshotView, aboveSubview: annotationView)
            }
        }

        UIView.animateWithDuration(duration, animations: { 
            snapshots.forEach({ (view) in
                animations(view: view)
            })
            }) { (success) in
                snapshots.forEach({ (view) in
                    view.removeFromSuperview()
                })
        }

        removeAnnotations(annotations)
    }
}

