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
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        print( url )
        do {
            let newURL = getDocsFolderURL().appendingPathComponent(url.lastPathComponent)
            try FileManager.default.copyItem(at: url, to: newURL)
            
            if let vc = (window?.rootViewController as? UINavigationController)?.topViewController as? ViewController {
                vc.loadFile(fromURL: newURL)
            }
            
        } catch {
                print( "Failed to copy file!" )
        }
        return false
    }
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let d = UserDefaults.standard
        d.register(defaults: ["hostName" : "", "port" : -1, "palette":"MSPaint"])
        
        return true
    }
    
    func testZipFileExtract() {
        if let url = Bundle.main.url(forResource: "invaders", withExtension: "zip" ) {
            print( "Extracting \(url)" )
            let zf = GameFrameArchiveHandler(zipFileURL: url)
            print( "Done" )
        }

    }
}

