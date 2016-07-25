//
//  Photo.swift
//  virtualTourist
//
//  Created by Rodrigo Astorga on 16-07-16.
//  Copyright © 2016 Rodrigo Astorga. All rights reserved.
//

import UIKit
import CoreData


class Photo: NSManagedObject {
    
    var image: UIImage? {
        get{
            if let imageData = imageData{
                return UIImage(data: imageData)
            }else{
                return nil
            }
        }
        set{
            if let newValue = newValue {
                imageData = UIImagePNGRepresentation(newValue)
            }else{
                imageData = nil
            }
        }
        
    }
    
    convenience init(url: String, context: NSManagedObjectContext){
        
        if let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            
            self.url = url
            
        }else{
            fatalError("entity not found")
        }
    }
    
    

}
