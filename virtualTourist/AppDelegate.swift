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
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        stack.save()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        stack.save()
    }

}

