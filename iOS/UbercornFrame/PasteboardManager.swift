//
//  PasteboardManager.swift
//  UbercornFrame
//
//  Created by Andy Qua on 01/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

func dataAsString( _ val: Any ) -> String? {
    let d = val as! Data
    return String( data:d, encoding:.utf8 )
}

extension UIPasteboard {
    func debug() {
        let pb = UIPasteboard.general
        
        let pasteboard = UIPasteboard.general
        if pasteboard.hasImages {
            if let image = pasteboard.image {
                print( "Found image - \(image.size)" )
            }
        }

        for item in pb.items {
            for (key,value) in item {
                print( "Item name - \(key)")
                
                if key == "public.utf16-external-plain-text" {
                    print( "   Value: \(value)" )
                }
                if key == "public.utf8-plain-text" {
                    print( "   Value: \(value)" )
                }
                if key == "public.text" {
                    print( "   Value: \(value)" )
                    var path = ""
                    let strArr = (value as! String).components(separatedBy: "\n")
                    if strArr.count > 1 {
                        path = strArr[1]
                    }

                    var exists = FileManager.default.fileExists(atPath: path)
                    print( "   Path - \(path)" )
                    print( "   File exists - \(exists)" )

                }
                if key == "com.apple.pasteboard.promised-file-content" {
                    print( "   Value: \(value)" )
                }
                if key == "com.apple.pasteboard.NSFilePromiseID" {
                    print( "   Value: \(dataAsString(value))" )
                    
                }
                if key == "com.apple.pasteboard.promised-file-name" {
                    print( "   Value: \(value)" )
                }
                if key == "com.apple.pasteboard.promised-file-content-type" {
                    print( "   Value: \(dataAsString(value))" )
                }
                if key == "com.apple.NSFilePromiseItemMetaData" {
                    print( "   Value: \(dataAsString(value))" )
                }
                if key == "Item name - com.apple.is-remote-clipboard" {
                    print( "   Value: \(value)" )
                }

                if key == "com.apple.icns" {
                    // GIF Image (Copy file directly from mac!)
                    print( "   Data Value length: \((value as! Data).count)" )
                }
            }
        }
        
        showTempFiles()
    }

    func showTempFiles() {
        let fileManager = FileManager.default
        
        let paths : [FileManager.SearchPathDirectory] = [.applicationDirectory, .demoApplicationDirectory, .developerApplicationDirectory, .adminApplicationDirectory, .libraryDirectory, .developerDirectory, .userDirectory, .documentationDirectory, .documentDirectory, .coreServiceDirectory, .autosavedInformationDirectory, .desktopDirectory, .cachesDirectory, .applicationSupportDirectory,
        .downloadsDirectory, .inputMethodsDirectory, .moviesDirectory, .musicDirectory, .picturesDirectory, .printerDescriptionDirectory, .sharedPublicDirectory, .preferencePanesDirectory, .itemReplacementDirectory, .allApplicationsDirectory, .allLibrariesDirectory, .trashDirectory]
        
        for path in paths {
            print( "Searching \(path)" )
            let folders = fileManager.urls(for: path, in: .userDomainMask)
            if folders.count == 0 {
                continue
            }
            let folderURL = URL(fileURLWithPath: "/var") //folders[0]
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
                
                for url in fileURLs {
                    print( "   \(url)" )
                }
                // process files
            } catch {
                print("Error while enumerating files \(folderURL.path): \(error.localizedDescription)")
            }
            break
        }
    }
}

func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
    var i = 0
    return AnyIterator {
        let next = withUnsafeBytes(of: &i) { $0.load(as: T.self) }
        if next.hashValue != i { return nil }
        i += 1
        return next
    }
}
