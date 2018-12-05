//
//  ZipFileHandler.swift
//  UbercornFrame
//
//  Created by Andy Qua on 05/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit
import ZIPFoundation

class GameFrameArchiveHandler {
    
    var foundImages : [String:[ImageFrame]] = [String:[ImageFrame]]()
    
    init( zipFileURL: URL ) {
        let fileURL : URL
        
        var createdTempFile = false
        if !zipFileURL.isFileURL {
            // TODO - FIX - Horrible - should be async as will lock up the app
            do {
                let data = try Data(contentsOf: zipFileURL)

                fileURL = createTemporaryFileURL()
                createdTempFile = true
                try? data.write(to: fileURL)
            } catch {
                print( "Failed to save \(zipFileURL) to temp file - \(error)" )
                return
            }
        } else {
            fileURL = zipFileURL
        }
        
        parseZipFile( fileURL )
        
        if createdTempFile {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    init( zipFileData : Data ) {
//        parseZipData( zipFileData )
    }
    
    private func createTemporaryFileURL() -> URL {
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(),
                                        isDirectory: true)

        let temporaryFilename = ProcessInfo().globallyUniqueString
        
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
        return temporaryFileURL

    }
    private func parseZipFile( _ zipURL : URL ) {
        // Unzip file to temp folder
        let destURL = FileManager.default.temporaryDirectory.appendingPathComponent("zipFile" )
        unzipFileToTempFolder( sourceURL:zipURL, destinationURL: destURL )
        
        // Work out what we have
        handleExtractedFiles( folder:destURL )
        
        // Remove temp folder when finished
        removeTempFolder(atUrl:destURL)
    }
    
    private func unzipFileToTempFolder( sourceURL: URL, destinationURL: URL ) {
        let fileManager = FileManager()
        do {
            if fileManager.fileExists(atPath: destinationURL.relativePath) {
                removeTempFolder( atUrl: destinationURL )
            }
            
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: sourceURL, to: destinationURL)
        } catch {
            print("Extraction of ZIP archive failed with error:\(error)")
        }
    }
    
    private func removeTempFolder( atUrl url:URL ) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to remove temp folder :\(error)")
        }
    }
    
    private func handleExtractedFiles( folder : URL ) {
        var contents : [URL] = [URL]()
        do {
            contents = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [])
        } catch {
            print( "Failed to read contents of \(folder) - \(error)" )
            return
        }
        
        let bmpFiles = contents.filter { $0.pathExtension == "bmp" }
        let folders = contents.filter { $0.pathExtension == "" }
        
        for child in folders {
            handleExtractedFiles( folder:child )
        }
        
        if bmpFiles.count > 0 {
            handleImages( imageList:bmpFiles )
        }
    }
    
    private func handleImages( imageList:[URL] )  {
        let sortedList = imageList.sorted {
            Int($0.deletingPathExtension().lastPathComponent) ?? 0 < Int($1.deletingPathExtension().lastPathComponent) ?? 0
        }
        
        let imageName = sortedList[0].deletingLastPathComponent().lastPathComponent
        var frames = [ImageFrame]()
        print( "In folder \(imageName) we have:" )
        
        if sortedList.count == 1 {
            // OK, We have a single bitmap, probably contains multiple frames
            // So, split it into single frames
            frames = splitBMPIntoFrames( url:sortedList[0] )
            
        } else {
            for imageURL in sortedList {
                print( "    \(imageURL.lastPathComponent)" )
                
                if let imageFrame = UIImage.gifImage(withURL: imageURL)?[0] {
                    frames.append( imageFrame )
                }
            }
        }

        self.foundImages[imageName] = frames
    }
    
    private func splitBMPIntoFrames( url: URL ) -> [ImageFrame] {
        guard let image = UIImage(contentsOfFile: url.path ) else { return [] }
        
        let x :CGFloat = 0
        var frames = [ImageFrame]()
        for y in stride( from:0, to:image.size.height, by:16) {
            if let croppedCGImage = image.cgImage?.cropping(to: CGRect(x: x, y: y, width: 16, height: 16)) {
                let imageFrame = UIImage.getImageAsFrame(croppedCGImage)
                frames.append(imageFrame)
            }
        }
        
        return frames
    }
}
