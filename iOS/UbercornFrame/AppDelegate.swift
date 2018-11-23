//
//  AppDelegate.swift
//  UbercornFrame
//
//  Created by Andy Qua on 19/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let d = UserDefaults.standard
        d.register(defaults: ["hostName" : "", "port" : -1, "palette":"MSPaint"])

        return true
    }
}

