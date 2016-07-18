//
//  PhotoFrame.swift
//  virtualTourist
//
//  Created by Rodrigo Astorga on 17-07-16.
//  Copyright © 2016 Rodrigo Astorga. All rights reserved.
//

import UIKit
import CoreData


class PhotoFrame: NSManagedObject {

    var image: UIImage? {
        get{
            if let imageData = imageData {
                return UIImage(data: imageData)
            }else{
                return nil
            }
        }
    }
    
    convenience init(imageData: NSData, context: NSManagedObjectContext){
        
        if let entity = NSEntityDescription.entityForName("PhotoFrame", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            
            self.imageData = imageData
//            photo: Photo?
            
            
        }else{
            fatalError("entity not found")
        }
    }
}
