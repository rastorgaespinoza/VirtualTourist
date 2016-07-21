//
//  AppDelegate.swift
//  virtualTourist
//
//  Created by Rodrigo Astorga on 23-06-16.
//  Copyright © 2016 Rodrigo Astorga. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let stack = CoreDataStack(modelName: "Model")!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        stack.save()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        stack.save()
    }
    
    
    //example of background operation
    func backgroundLoad(){
        
        stack.performBackgroundBatchOperation { (workerContext) in
  
//            for i in 1...100{
//                let nb = Notebook(name: "Background notebook \(i)", context: workerContext)
//                
//                for _ in 1...100{
//                    let note = Note(text: "The path of the righteous man is beset on all sides by the iniquities of the selfish and the tyranny of evil men. Blessed is he who, in the name of charity and good will, shepherds the weak through the valley of darkness, for he is truly his brother's keeper and the finder of lost children. And I will strike down upon thee with great vengeance and furious anger those who would attempt to poison and destroy My brothers. And you will know My name is the Lord when I lay My vengeance upon thee.", context: workerContext)
//                    note.notebook = nb
//                }
//            }
//            print("==== finished background operation ====")
        }
    }

}

