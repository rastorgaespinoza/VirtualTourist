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
    
    typealias FlickrKeys = FlickrClient.FlickrParamKeys
    typealias FlickrValues = FlickrClient.FlickrParamValues
    
    func getPhotosByLocation(pin: MKAnnotation, completionPhotos: completionWithURLPhotos ){

        let methodParameters: [String: AnyObject] = [
            FlickrKeys.Method:          FlickrValues.SearchMethod,
            FlickrKeys.APIKey:          FlickrValues.APIKey,
            FlickrKeys.BoundingBox:     bboxString(pin),
            FlickrKeys.SafeSearch:      FlickrValues.UseSafeSearch,
            FlickrKeys.Extras:          FlickrValues.MediumURL,
            FlickrKeys.Format:          FlickrValues.ResponseFormat,
            FlickrKeys.NoJSONCallback:  FlickrValues.DisableJSONCallback,
            FlickrKeys.PerPage:         FlickrValues.PerPage,
            FlickrKeys.Page:            1
        ]
        
        guard let url = flickrURLFromParameters(methodParameters) else {
            return
        }
        
        taskForMethod(url) { (result, error) in
            if let result = result[FlickrResponseKeys.Photos] as? [String: AnyObject],
            let photos = result[FlickrResponseKeys.Photo] as? [ [String: AnyObject]] {

                var arrayPhotoURLs = [String]()

                
                arrayPhotoURLs = photos.map({ (photoDict: [String : AnyObject]) -> String in
                    return photoDict["url_m"] as! String
                })
                
                completionPhotos(success: true, photoURLs: arrayPhotoURLs, errorString: nil)
                return
                
//                if arrayPhotos.isEmpty {
//                    completionPhotos(success: true, photoURLs: arrayPhotoURLs, errorString: nil)
//                    
//                }else{
//                    arrayPhotoURLs = arrayPhotos.map({ (photoDict: [String : AnyObject]) -> String in
//                        return photoDict["url_m"] as! String
//                    })
//                    
//                    completionPhotos(success: true, photoURLs: arrayPhotoURLs, errorString: nil)      
//                    
//                }
//                return
                
            }
            else{
                completionPhotos(success: false, photoURLs: [String](), errorString: "not cast the data")
                return
            }
        }
        
    }

    /// Download the image from URL
    func downloadImage(url: String, completion: (imageData: NSData!, errorString: String?) -> Void) {
        
        guard let url = NSURL(string: url) else{
            completion(imageData: nil, errorString: "Not valid url")
            return
        }
        
        let task = session.dataTaskWithURL(url) { (data, response, error) in
            
            func sendError(error: String) {
                completion(imageData: nil, errorString: error)
            }
            
            guard error == nil else {
                sendError("There was an error in request. (\(error!.code)): \(error!.localizedDescription)")
                return
            }
            
            guard let data = data else {
                sendError("your request does not return data")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("your request returned an invalid state. (\((response as? NSHTTPURLResponse)?.statusCode))")
                return
            }
            
            completion(imageData: data, errorString: nil)
        }
        
        task.resume()
        
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
