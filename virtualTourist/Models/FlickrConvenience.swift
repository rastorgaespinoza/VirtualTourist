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
    
    func getPhotosByLocation(pin: MKAnnotation, completionPhotos: completionWithURLPhotos ){
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
                var arrayPhotoURLs = [String]()
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
                
                if arrayPhotos.isEmpty {
                    completionPhotos(success: true, photoURLs: arrayPhotoURLs, errorString: nil)
                }else{
                    arrayPhotoURLs = arrayPhotos.map({ (photoDict: [String : AnyObject]) -> String in
                        return photoDict["url_m"] as! String
                    })
                    
                    completionPhotos(success: true, photoURLs: arrayPhotoURLs, errorString: nil)
//                    for photos in arrayPhotos {
//                        arrayPhotoURLs.append(photos["url_m"] as! String)
//                    }
                }
                
                print("Fin")
                
            }
            else{
                completionPhotos(success: false, photoURLs: [String](), errorString: "not cast the data")
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
