//
//  PhotoCollectionViewCell.swift
//  virtualTourist
//
//  Created by Rodrigo Astorga on 11-07-16.
//  Copyright © 2016 Rodrigo Astorga. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func setPhotoCell(photo: Photo) {
        if let image = photo.image {
            photoImageView.image = image
            activityIndicator.stopAnimating()
        }else{
            photoImageView.image = FlickrClient.Images.placeHolder
            activityIndicator.startAnimating()
        }
    }
    
//    override func prepareForReuse() {
//        
//        super.prepareForReuse()
//        
//        if photoImageView.image == nil {
//            activityIndicator.startAnimating()
//        }else {
//            activityIndicator.stopAnimating()
//        }
//    }
    
}
