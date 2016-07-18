//
//  PhotoFrame+CoreDataProperties.swift
//  virtualTourist
//
//  Created by Rodrigo Astorga on 17-07-16.
//  Copyright © 2016 Rodrigo Astorga. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension PhotoFrame {

    @NSManaged var imageData: NSData?
    @NSManaged var photo: Photo?

}
