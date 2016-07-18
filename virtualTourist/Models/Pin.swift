//
//  Pin.swift
//  virtualTourist
//
//  Created by Rodrigo Astorga on 16-07-16.
//  Copyright © 2016 Rodrigo Astorga. All rights reserved.
//

import Foundation
import CoreData
import MapKit


class Pin: NSManagedObject, MKAnnotation {
    
    var coordinate:CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: (latitude as! CLLocationDegrees),
                                          longitude: (longitude as! CLLocationDegrees))
        }
        set(value) {
            latitude = value.latitude
            longitude = value.longitude
        }
    }
    
    convenience init(coordinate:CLLocationCoordinate2D, context: NSManagedObjectContext){
        
        if let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context){
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.coordinate = coordinate
        }else{
            fatalError("Unable to find Entity name!")
        }
        
    }

    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext){
        
        if let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context){
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.latitude = latitude
            self.longitude = longitude
//            photos: NSOrderedSet?
        }else{
            fatalError("Unable to find Entity name!")
        }
        
    }

}
