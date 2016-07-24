//
//  FlickrClient.swift
//  virtualTourist
//
//  Created by Rodrigo Astorga on 03-07-16.
//  Copyright © 2016 Rodrigo Astorga. All rights reserved.
//

import UIKit

class FlickrClient {
    
    typealias completionData = (result: AnyObject!, error: NSError?) -> Void
    typealias completionForViewController = (success: Bool, errorString: String?) -> Void
    typealias completionWithURLPhotos = (success: Bool, photoURLs: [String], errorString: String?) -> Void
    
    let session: NSURLSession!
    let stack: CoreDataStack!
    
    init(){
        session = NSURLSession.sharedSession()
        stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
    }
    
    // MARK: - Shared Instance
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static let instance = FlickrClient()
        }
        
        return Singleton.instance
    }
    

    func taskForMethod(method: NSURL, completionHandler: completionData ) {
        
        // 1. Configuración del request
        let request = NSMutableURLRequest()
        request.URL = method
        request.HTTPMethod = HTTPMethods.GET
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            self.validateData(data, response: response, error: error, completionForValidation: completionHandler)
        }
        
        task.resume()
        
    }

    /// Helper for Creating a URL from Parameters
    func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL? {
        
        let components = NSURLComponents()
        components.scheme = Flickr.APIScheme
        components.host = Flickr.APIHost
        components.path = Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL
    }
    
    /// Helper: Given raw JSON, return a usable Foundation object
    private func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : " JSON data from server could not be parsed. This is caused by a JSON formatting error: '\(data)'"]
            completionHandler(result: nil, error: NSError(domain: "parseJSONWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandler(result: parsedResult, error: nil)
    }
    
    /// validate Data
    private func validateData(data: NSData?, response: NSURLResponse?, error: NSError?, completionForValidation: (result: AnyObject!, error: NSError?) -> Void){
        
        func sendError(error: String) {
            let userInfo = [NSLocalizedDescriptionKey: error]
            completionForValidation(result: nil, error: NSError(domain: "validateData", code: 2, userInfo: userInfo) )
        }
        
        /* GUARD: Was there an error? */
        guard (error == nil) else {
            sendError("There was an error in request. (\(error!.code))")
            return
        }
        
        /* GUARD: Was there any data returned? */
        guard let data = data else {
            sendError("your request does not return data")
            return
        }
        
        /* GUARD: Did we get a successful 2XX response? */
        guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
            sendError("your request returned an invalid state. (\((response as? NSHTTPURLResponse)?.statusCode))")
            return
        }
        
        parseJSONWithCompletionHandler(data, completionHandler: completionForValidation)
    }
    
    
}
