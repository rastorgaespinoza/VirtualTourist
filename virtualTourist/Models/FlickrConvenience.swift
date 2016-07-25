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
    
    func getPhotosByLocation(pin: MKAnnotation, withPageNumber: Int? = nil, completionPhotos: completionWithURLPhotos ){

        var methodParameters: [String: AnyObject] = [
            FlickrKeys.Method:          FlickrValues.SearchMethod,
            FlickrKeys.APIKey:          FlickrValues.APIKey,
            FlickrKeys.SafeSearch:      FlickrValues.UseSafeSearch,
            FlickrKeys.Extras:          FlickrValues.MediumURL,
            FlickrKeys.Format:          FlickrValues.ResponseFormat,
            FlickrKeys.NoJSONCallback:  FlickrValues.DisableJSONCallback,
            FlickrKeys.PerPage:         FlickrValues.PerPage,
            FlickrKeys.Page:            1,
//            FlickrKeys.BoundingBox:     bboxString(pin),
            FlickrKeys.Latitude:        pin.coordinate.latitude,
            FlickrKeys.Longitude:       pin.coordinate.longitude
            
        ]
        
        if let withPageNumber = withPageNumber {
            methodParameters[FlickrKeys.Page] = withPageNumber
        }
        
        guard let url = flickrURLFromParameters(methodParameters) else {
            return
        }
        
        taskForMethod(url) { (result, error) in
            
            if let result = result as? [String: AnyObject]{
                completionPhotos(success: true, photoURLs: result, errorString: nil)
            }else{
                completionPhotos(success: false, photoURLs: [String:AnyObject](), errorString: "not cast the data")
            }
 
//            if let result = result[FlickrResponseKeys.Photos] as? [String: AnyObject],
//            let photos = result[FlickrResponseKeys.Photo] as? [ [String: AnyObject]] {
//
//                var arrayPhotoURLs = [String]()
//
//                arrayPhotoURLs = photos.map({ (photoDict: [String : AnyObject]) -> String in
//                    return photoDict["url_m"] as! String
//                })
//                
//                completionPhotos(success: true, photoURLs: arrayPhotoURLs, errorString: nil)
//                return
//                
////                if arrayPhotos.isEmpty {
////                    completionPhotos(success: true, photoURLs: arrayPhotoURLs, errorString: nil)
////                    
////                }else{
////                    arrayPhotoURLs = arrayPhotos.map({ (photoDict: [String : AnyObject]) -> String in
////                        return photoDict["url_m"] as! String
////                    })
////                    
////                    completionPhotos(success: true, photoURLs: arrayPhotoURLs, errorString: nil)      
////                    
////                }
////                return
//                
//            }
//            else{
//                completionPhotos(success: false, photoURLs: [String](), errorString: "not cast the data")
//                return
//            }
        }
        
//        if withPageNumber == nil {
//            if let result = result[FlickrResponseKeys.Photos] as? [String: AnyObject] {
//                
//                if let totalPages = result[FlickrResponseKeys.Pages] as? Int{
//                    let pageLimit = min(totalPages, 189) // Considering (4000 photos max in query) / (21 per collectionView) == 190.476...
//                    let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
//                    
//                    dispatch_async(dispatch_get_main_queue() ) {
//                        self.getPhotosByLocation(pin, withPageNumber: randomPage, completionPhotos: { (success, photoURLs, errorString) in
//                            if let result = result[FlickrResponseKeys.Photos] as? [String: AnyObject],
//                                let photos = result[FlickrResponseKeys.Photo] as? [ [String: AnyObject]] {
//                                
//                                var arrayPhotoURLs = [String]()
//                                
//                                arrayPhotoURLs = photos.map({ (photoDict: [String : AnyObject]) -> String in
//                                    return photoDict["url_m"] as! String
//                                })
//                                dispatch_async(dispatch_get_main_queue()){
//                                    completionPhotos(success: true, photoURLs: arrayPhotoURLs, errorString: nil)
//                                }
//                                
//                                return
//                                
//                            }
//                            else{
//                                dispatch_async(dispatch_get_main_queue()){
//                                    completionPhotos(success: false, photoURLs: [String](), errorString: "not cast the data")
//                                }
//                                return
//                            }
//                        })
//                    }
//                }
//                
//            }
//        }
        
    }
    
    func getPhotosForPin(pin: MKAnnotation, completionPhotos: completionWithURLPhotos){
        
        getPhotosByLocation(pin) { (success, photoURLs, errorString) in
            guard success else {
                completionPhotos(success: false, photoURLs: [String: AnyObject](), errorString: errorString!)
                return
            }
            
            guard let photosDict = photoURLs[FlickrResponseKeys.Photos] as? [String: AnyObject] else {
                completionPhotos(success: false, photoURLs: [String: AnyObject](), errorString: "Not cast data.")
                return
            }

            guard let totalPages = photosDict[FlickrResponseKeys.Pages] as? Int else {
                completionPhotos(success: false, photoURLs: [String: AnyObject](), errorString: "Not cast data.")
                return
            }
            
            let pageLimit = min(totalPages, 189) // Considering (4000 photos max in query) / (21 per collectionView) == 190.476...
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            print("randomPage: \(randomPage)")
            dispatch_async(dispatch_get_main_queue()) {
                self.getPhotosByLocation(pin, withPageNumber: randomPage, completionPhotos: { (success, photoURLs, errorString) in
                    
                    if let result = photoURLs[FlickrResponseKeys.Photos] as? [String: AnyObject],
                        let photos = result[FlickrResponseKeys.Photo] as? [ [String: AnyObject]] {
                        
                        var arrayPhotoURLs = [String]()
                        
                        arrayPhotoURLs = photos.map({ (photoDict: [String : AnyObject]) -> String in
                            return photoDict["url_m"] as! String
                        })
                        
                        let dictURLs = ["url_m": arrayPhotoURLs ]
                        dispatch_async(dispatch_get_main_queue()){
                            completionPhotos(success: true, photoURLs: dictURLs, errorString: nil)
                        }
                        
                    }
                    else{
                        dispatch_async(dispatch_get_main_queue()){
                            completionPhotos(success: false, photoURLs: [String: AnyObject](), errorString: "not cast the data")
                        }
                    }
                    
                })
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
    
    /// Download the image from URL
    func downloadImageForPhoto(photo: Photo, completion: (imageData: NSData!, errorString: String?) -> Void) -> NSURLSessionDataTask? {
        
        guard let urlString = photo.url else {
            completion(imageData: nil, errorString: "Not exist URL")
            return nil
        }
        
        guard let url = NSURL(string: urlString) else{
            completion(imageData: nil, errorString: "Not valid url")
            return nil
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
        
        return task
        
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
