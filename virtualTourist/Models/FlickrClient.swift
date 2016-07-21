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
    
    /**
     Realiza todo el proceso necesario para realizar un request al servidor.
     - Author: Rodrigo Astorga.
     - Parameters:
     - method: Un `NSURL` que contiene la url del objeto que se desea obtener o guardar (ej: NSURL(string: "https://baas.kinvey.com")  )
     - HTTPMethod: un `String` que contiene el método HTTP que se va a ejecutar: "GET", "POST", "PUT" o "DELETE" (se sugiere utilizar el `struct` HTTPMethods. A modo de ejemplo: HTTPMethods.GET ). Por defecto es "GET".
     - HTTPBody: un Diccionario `[String: AnyObject]` con información que se desea enviar al servidor. Esto forma parte del body. Es opcional y por defecto es `nil`.
     - returns: un callback llamado completionHandler compuesto por el resultado obtenido luego de haber realizado el request y un error en caso de que exista.
     */
    func taskForMethod(method: NSURL, HTTPMethod: String = HTTPMethods.GET, HTTPBody: [String: AnyObject]? = nil, completionHandler: completionData ) {
        
        // 1. Configuración del request
        let request = NSMutableURLRequest()
        request.URL = method
        request.HTTPMethod = HTTPMethod
        
        // Si es un método POST o PUT, configurar el cuerpo del mensaje
        switch HTTPMethod {
        case HTTPMethods.POST, HTTPMethods.PUT:
            
//            request.addValue(ParameterKeys.AppJSon, forHTTPHeaderField: ParameterKeys.ContentTypeJSon)
            
            guard let body = HTTPBody where NSJSONSerialization.isValidJSONObject(body) else {
                return
            }
            
            let bodyData: NSData!
            do {
                bodyData = try NSJSONSerialization.dataWithJSONObject(body, options: [])
            }catch {
                let userInfo = [NSLocalizedDescriptionKey: "Error al intentar formatear el mensaje a enviar"]
                completionHandler(result: nil, error: NSError(domain: "taskSerializationBody", code: 1, userInfo: userInfo))
                return
            }
            
            request.HTTPBody = bodyData
            
        default:
            break
        }
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            self.validateData(domain: "taskForMethod", data: data, response: response, error: error, completionForValidation: completionHandler)
        }
        
        task.resume()
        
    }
    
    
    
    // MARK: Helper for Creating a URL from Parameters
    
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
    
    /** Helper: Given raw JSON, return a usable Foundation object */
    private func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandler(result: nil, error: NSError(domain: "parseJSONWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandler(result: parsedResult, error: nil)
    }
    
    
    func validateData(domain domain: String, data: NSData?, response: NSURLResponse?, error: NSError?, completionForValidation: (result: AnyObject!, error: NSError?) -> Void){
        
        func sendError(error: String) {
            let userInfo = [NSLocalizedDescriptionKey: error]
            completionForValidation(result: nil, error: NSError(domain: domain, code: 1, userInfo: userInfo) )
        }
        
        /* GUARD: Was there an error? */
        guard (error == nil) else {
            sendError("Ocurrió un error durante su solicitud: (\(error!.code))")
            return
        }
        
        /* GUARD: Was there any data returned? */
        guard let data = data else {
            sendError("Su solicitud no retornó datos")
            return
        }
        
        /* GUARD: Did we get a successful 2XX response? */
        guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
            sendError("Error in response.")
            return
        }
        
        parseJSONWithCompletionHandler(data, completionHandler: completionForValidation)
    }
    
    
}
