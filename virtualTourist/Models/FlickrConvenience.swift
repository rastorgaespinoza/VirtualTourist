//
//  FlickrConvenience.swift
//  virtualTourist
//
//  Created by Rodrigo Astorga on 03-07-16.
//  Copyright © 2016 Rodrigo Astorga. All rights reserved.
//

import Foundation
import MapKit

extension FlickrClient {
    
    func getPhotosByLocation(pin: MKAnnotation){
        // create session and request

        let methodParameters = [
            FlickrClient.FlickrParameterKeys.Method: FlickrClient.FlickrParameterValues.SearchMethod,
            FlickrClient.FlickrParameterKeys.APIKey: FlickrClient.FlickrParameterValues.APIKey,
            FlickrClient.FlickrParameterKeys.BoundingBox: bboxString(pin),
            FlickrClient.FlickrParameterKeys.SafeSearch: FlickrClient.FlickrParameterValues.UseSafeSearch,
            FlickrClient.FlickrParameterKeys.Extras: FlickrClient.FlickrParameterValues.MediumURL,
            FlickrClient.FlickrParameterKeys.Format: FlickrClient.FlickrParameterValues.ResponseFormat,
            FlickrClient.FlickrParameterKeys.NoJSONCallback: FlickrClient.FlickrParameterValues.DisableJSONCallback
        ]
        
        guard let url = flickrURLFromParameters(methodParameters) else {
            return
        }
        
        taskForMethod(url) { (result, error) in
            if let result = result[FlickrResponseKeys.Photos] as? [String: AnyObject],
            let photos = result[FlickrResponseKeys.Photo] as? [ [String: AnyObject]] {
                var arrayPhotos: [[String:AnyObject] ] = []
                var indexOfPhotos: [Int] = []
                
                for _ in photos {
                    let randomPhotoIndex = Int(arc4random_uniform(UInt32(photos.count)))
                    
                    if !indexOfPhotos.contains(randomPhotoIndex) {
                        indexOfPhotos.append(randomPhotoIndex)
                    }
                    
                    if indexOfPhotos.count == 21 {
                        break
                    }
                    
                }
                
                for index in indexOfPhotos {
                    arrayPhotos.append(photos[index])
                }
                
                for photos in arrayPhotos {
                    print(photos["url_m"]!)
                }
                print("Fin")
                
            }
        }
        
    }
    
    private func bboxString(pin: MKAnnotation) -> String {
        // ensure bbox is bounded by minimum and maximums
        
        let latitude = pin.coordinate.latitude
        let longitude = pin.coordinate.longitude
        
        let minimumLon = max(longitude - FlickrClient.Flickr.SearchBBoxHalfWidth, FlickrClient.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - FlickrClient.Flickr.SearchBBoxHalfHeight, FlickrClient.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + FlickrClient.Flickr.SearchBBoxHalfWidth, FlickrClient.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + FlickrClient.Flickr.SearchBBoxHalfHeight, FlickrClient.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
}
