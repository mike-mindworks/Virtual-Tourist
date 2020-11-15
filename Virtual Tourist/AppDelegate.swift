//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Mike Allan on 2020-10-12.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    let dataController = DataController(modelName: "VirtualTourist")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("Documents Directory: ", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last ?? "Not Found!")
        dataController.load()
        
        if let window = window {
            let navigationController = window.rootViewController as! UINavigationController
            let mapViewController = navigationController.topViewController as! MapViewController
            mapViewController.dataController = dataController
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        saveViewContext()
    }
    
    func saveViewContext() {
        try?dataController.viewContext.save()
    }

}

