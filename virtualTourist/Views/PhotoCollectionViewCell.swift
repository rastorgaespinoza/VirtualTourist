//
//  PhotoCollectionViewCell.swift
//  virtualTourist
//
//  Created by Rodrigo Astorga on 11-07-16.
//  Copyright © 2016 Rodrigo Astorga. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: TaskCancelingCollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func setPhotoCell(photo: Photo) {
        if let image = photo.image {
            photoImageView.image = image
            activityIndicator.stopAnimating()
        }else{
            photoImageView.image = FlickrClient.Images.placeHolder
            activityIndicator.startAnimating()
            
            let task = FlickrClient.sharedInstance().downloadImageForPhoto(photo, completion: { (imageData, errorString) in
                guard let imageData = imageData else {
                    return
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    photo.imageData = imageData
                    self.activityIndicator.stopAnimating()
                    (UIApplication.sharedApplication().delegate as! AppDelegate).stack.save()
                }
                
                
            })
            
            taskToCancelifCellIsReused = task
        }
        
        
    }
    
}
