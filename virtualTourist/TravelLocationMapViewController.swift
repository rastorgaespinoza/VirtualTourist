//
//  TravelLocationMapViewController.swift
//  virtualTourist
//
//  Created by Rodrigo Astorga on 23-06-16.
//  Copyright © 2016 Rodrigo Astorga. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationMapViewController: UIViewController {
    
    // MARK: - Properties
    private var stack: CoreDataStack!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var labelForDeletePin: UILabel!
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        editing = false
        
        stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
        
        restoreMapRegion()
        
        let longpressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longpressGestureRecognizer)

        fetchPins()

    }
    
    // MARK: - Actions and Methods
    @IBAction func edit(sender: AnyObject) {
        editing = !editing
        
        editButton.title = editing ? "Done" : "Edit"
        UIView.animateWithDuration(0.3) {
            
            self.labelForDeletePin.hidden = self.editing ? false : true
        }
    }
    
    func handleLongPress(sender: UIGestureRecognizer) {
        // This is important if you only want to receive one tap and hold event
        if sender.state == .Ended || sender.state == .Changed{
            return
        }else {
            
            // Here we get the CGPoint for the touch and convert it to latitude and longitude coordinates to display on the map
            let point: CGPoint = sender.locationInView(mapView)
            let locCoord: CLLocationCoordinate2D = mapView.convertPoint(point, toCoordinateFromView: mapView)
            
            //add pin to core data
            // Then all you have to do is create the annotation and add it to the map
            let pin = Pin(coordinate: locCoord, context: stack.context )
            
            stack.save()
//            try? stack.saveContext()

//            let dropPin = MKPointAnnotation()
//            dropPin.coordinate = pin.coordinate

            mapView.addAnnotation(pin)
        }
    }
    
    func fetchPins(){
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do{
            if let pins = try stack.context.executeFetchRequest(fetchRequest) as? [Pin] {
                for pin in pins {
                    mapView.addAnnotation(pin)
                }
            }
            
        }catch{
            fatalError("Error when fetched Pin values")
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        let photoAlbumPinVC = segue.destinationViewController as! PhotoAlbumViewController
        
        // Create Fetch Request
        let fr = NSFetchRequest(entityName: "Photo")
        
        fr.sortDescriptors = [ NSSortDescriptor(key: "url", ascending: false)]
        // So far we have a search that will match ALL notes. However, we're
        // only interested in those within the current notebook:
        // NSPredicate to the rescue!

        let pin = sender as! Pin
        
        let pred = NSPredicate(format: "pin = %@", argumentArray: [pin])
        
        fr.predicate = pred
        
        // Create FetchedResultsController
        let fc = NSFetchedResultsController(fetchRequest: fr,
                                            managedObjectContext: stack.context,
                                            sectionNameKeyPath: nil,
                                            cacheName: nil)
        
        // Inject it into the photoAlbumPinVC
        photoAlbumPinVC.fetchedResultsController = fc
        
        // Inject the pin too!
        photoAlbumPinVC.pin = pin
    }

}

// MARK: - MKMapViewDelegate
extension TravelLocationMapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.redColor()
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
        
        if editing {
            let annotation = view.annotation as! Pin
            mapView.removeAnnotation(annotation)
            stack.context.deleteObject(annotation)
            
            stack.save()
//            try! stack.saveContext()
            
//            CoreDataStackManager.sharedInstance().delete(annotation.pin)
//            CoreDataStackManager.sharedInstance().saveContext()
//            mapView.removeAnnotation(annotation)
        }
        else {
            let annotation = view.annotation
            performSegueWithIdentifier("showDetailPin", sender: (annotation as! Pin) )
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