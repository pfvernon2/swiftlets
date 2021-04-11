//
//  MKMapView+Zoom.swift
//  swiftlets
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
    func zoomMapViewToFit(coordinates:[CLLocationCoordinate2D]?) {
        if annotations.count == .zero {
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
        
        var region:MKCoordinateRegion = MKCoordinateRegion(mapRect)
        region.span.latitudeDelta  *= kANNOTATION_LAT_PAD_FACTOR * 2.0
        region.span.longitudeDelta *= kANNOTATION_LONG_PAD_FACTOR * 2.0
        
        //enforce min/max
        region.span.latitudeDelta = min(region.span.latitudeDelta, kMAX_DEGREES_ARC)
        region.span.longitudeDelta = min(region.span.longitudeDelta, kMAX_DEGREES_ARC)
        region.span.latitudeDelta = max(region.span.latitudeDelta, kMINIMUM_ZOOM_ARC)
        region.span.longitudeDelta = max(region.span.longitudeDelta, kMINIMUM_ZOOM_ARC)
        
        setRegion(region, animated: true)
    }
    
    func animateDrop(annotationView:MKAnnotationView, closure:@escaping ()->()) {
        guard let viewCoordinate = annotationView.annotation?.coordinate else {
            closure()
            return
        }
        
        let dropPoint:MKMapPoint = MKMapPoint(viewCoordinate)
        if self.visibleMapRect.contains(dropPoint) {
            let endRect = annotationView.frame
            var startRect = endRect
            startRect.origin.y -= self.frame.size.height
            
            annotationView.frame = startRect
            UIView .animate(withDuration: 0.5, animations: {
                annotationView.frame = endRect
            },
                            completion:
                { (finished) in
                    UIView .animate(withDuration: 0.15, animations: {
                        annotationView.transform = CGAffineTransform(scaleX: 1.0, y: 0.8)
                    },
                                    completion:
                        { (finished) in
                            annotationView.transform = CGAffineTransform.identity
                            closure()
                    })
            })
        }
    }
    
    /**
     Animate the removal of annotations from the map view.
     The animations closure gives you access to a snapshot view of the annotation for you to perform animations on
     
     ```
     mapView.animateRemoval(annotations, duration: 0.5, animations: { (view) in
     view.alpha = .alphaMin
     })
     ```
     */
    func animateRemoval(annotations: [MKAnnotation], duration: TimeInterval, animations: @escaping (_ view:UIView) -> Void, completion:@escaping ()->()) {
        let visibleAnnotations:Set = self.annotations(in: visibleMapRect)
        var animationAnnotations:[MKAnnotation] = []
        annotations.forEach { (annotation) in
            if visibleAnnotations.contains(annotation as! NSObject) {
                animationAnnotations.append(annotation)
            }
        }
        
        var snapshots:[UIView] = []
        animationAnnotations.forEach { (annotation) in
            if let annotationView:UIView = view(for: annotation),
                let snapshotView:UIView = annotationView.snapshotView(afterScreenUpdates: false) {
                snapshotView.frame = annotationView.frame
                snapshots.append(snapshotView)
                annotationView.superview?.insertSubview(snapshotView, aboveSubview: annotationView)
            }
        }
        
        UIView.animate(withDuration: duration, animations: {
            snapshots.forEach({ (view) in
                animations(view)
            })
        }) { (success) in
            snapshots.forEach({ (view) in
                view.removeFromSuperview()
            })
            completion()
        }
        
        removeAnnotations(annotations)
    }
}

