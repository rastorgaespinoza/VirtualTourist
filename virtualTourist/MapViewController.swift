//
//  MapViewController.swift
//  virtualTourist
//
//  Created by Rodrigo Astorga on 23-06-16.
//  Copyright © 2016 Rodrigo Astorga. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    private var annotations = [MKPointAnnotation]()
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longpressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longpressGestureRecognizer)
        
        restoreMapRegion()

    }
    
    func handleLongPress(sender: UIGestureRecognizer) {
        // This is important if you only want to receive one tap and hold event
        if sender.state == .Ended || sender.state == .Changed{
            return
        }else {
            // Here we get the CGPoint for the touch and convert it to latitude and longitude coordinates to display on the map
//            mapView.removeAnnotations(annotations)
            let point: CGPoint = sender.locationInView(mapView)
            let locCoord: CLLocationCoordinate2D = mapView.convertPoint(point, toCoordinateFromView: mapView)
            // Then all you have to do is create the annotation and add it to the map
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = locCoord
            
            annotations.append(dropPin)
//            mapView.addAnnotation(dropPin)
            
            mapView.addAnnotations(annotations)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let detailPinVC = segue.destinationViewController as! DetailPinViewController
        detailPinVC.pin = (sender as! MKAnnotation)
    }
    
//    func setLocations(locations: [String]) {
//        
//        mapView.removeAnnotations(annotations)
//        annotations.removeAll()
//        for student in locations {
//            
//            let lat = CLLocationDegrees(student.latitude )
//            let long = CLLocationDegrees(student.longitude)
//            
//            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
//            
//            let first = student.firstName
//            let last = student.lastName
//            let mediaURL = student.mediaURL
//            
//            // Here we create the annotation and set its coordiate, title, and subtitle properties
//            let annotation = MKPointAnnotation()
//            annotation.coordinate = coordinate
//            annotation.title = "\(first) \(last)"
//            annotation.subtitle = mediaURL
//            
//            // Finally we place the annotation in an array of annotations.
//            annotations.append(annotation)
//        }
//        
//        // When the array is complete, we add the annotations to the map.
//        mapView.addAnnotations(annotations)
//    }

}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.redColor()
//            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView!.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        saveMapRegion()
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        let annotation = view.annotation
        performSegueWithIdentifier("showDetailPin", sender: annotation)
    }
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {

        if view.selected {
            performSegueWithIdentifier("showDetailPin", sender: nil)
        }
        if let annot = view.annotation {
            performSegueWithIdentifier("showDetailPin", sender: nil)
        }
        if control == view.rightCalloutAccessoryView {
            performSegueWithIdentifier("showDetailPin", sender: nil)
            if let urlToOpen = view.annotation?.subtitle! {
//                Helper.openURL(self, urlString: urlToOpen)
            }
        }
    }
    
    //Setting the zoom level for a MKMapView
    //StackOverFlow: http://stackoverflow.com/questions/4189621/setting-the-zoom-level-for-a-mkmapview
    //
    func saveMapRegion() {
        let mapRegion = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        NSUserDefaults.standardUserDefaults().setObject(mapRegion, forKey: "mapRegion")
    }
    
    func restoreMapRegion()
    {
        if let mapRegion = NSUserDefaults.standardUserDefaults().objectForKey("mapRegion")
        {
            
            let longitude = mapRegion["longitude"] as! CLLocationDegrees
            let latitude = mapRegion["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = mapRegion["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = mapRegion["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(savedRegion, animated: false)
        }
    }
}