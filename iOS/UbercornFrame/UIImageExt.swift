//
//  UIImageExt.swift
//  UbercornFrame
//
//  Created by Andy Qua on 21/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit
import MobileCoreServices

enum PixelFormat
{
    case abgr
    case argb
    case bgra
    case rgba
}

extension CGBitmapInfo
{
    public static var byteOrder16Host: CGBitmapInfo {
        return CFByteOrderGetCurrent() == Int(CFByteOrderLittleEndian.rawValue) ? .byteOrder16Little : .byteOrder16Big
    }
    
    public static var byteOrder32Host: CGBitmapInfo {
        return CFByteOrderGetCurrent() == Int(CFByteOrderLittleEndian.rawValue) ? .byteOrder32Little : .byteOrder32Big
    }
}

extension CGBitmapInfo
{
    var pixelFormat: PixelFormat? {
        
        // AlphaFirst – the alpha channel is next to the red channel, argb and bgra are both alpha first formats.
        // AlphaLast – the alpha channel is next to the blue channel, rgba and abgr are both alpha last formats.
        // LittleEndian – blue comes before red, bgra and abgr are little endian formats.
        // Little endian ordered pixels are BGR (BGRX, XBGR, BGRA, ABGR, BGR).
        // BigEndian – red comes before blue, argb and rgba are big endian formats.
        // Big endian ordered pixels are RGB (XRGB, RGBX, ARGB, RGBA, RGB).
        
        let alphaInfo: CGImageAlphaInfo? = CGImageAlphaInfo(rawValue: self.rawValue & type(of: self).alphaInfoMask.rawValue)
        let alphaFirst: Bool = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst
        let alphaLast: Bool = alphaInfo == .premultipliedLast || alphaInfo == .last || alphaInfo == .noneSkipLast
        let endianLittle: Bool = self.contains(.byteOrder32Little)
        
        // This is slippery… while byte order host returns little endian, default bytes are stored in big endian
        // format. Here we just assume if no byte order is given, then simple RGB is used, aka big endian, though…
        
        if alphaFirst && endianLittle {
            return .bgra
        } else if alphaFirst {
            return .argb
        } else if alphaLast && endianLittle {
            return .abgr
        } else if alphaLast {
            return .rgba
        } else {
            return nil
        }
    }
}


// Extension for Reading GIFs
extension UIImage {
    
    class func gifImage( withData data: NSData) -> [ImageFrame]? {
        guard let source = CGImageSourceCreateWithData(data, nil) else {
            print("image doesn't exist")
            return nil
        }
        
        return UIImage.getImageFramesFromGIF(source: source)
    }
    
    class func gifImage( withURL url:URL) -> [ImageFrame]? {
        guard let imageData = NSData(contentsOf: url) else {
            print("image named \"\(url)\" into NSData")
            return nil
        }
        
        return gifImage(withData: imageData)
    }
    
    class func gifImage( withName name: String) -> [ImageFrame]? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
                print("SwiftGif: This image named \"\(name)\" does not exist")
                return nil
        }
        
        guard let imageData = NSData(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        
        return gifImage(withData: imageData)
    }
    
    class func delayForImageAtIndex(index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(CFDictionaryGetValue(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()), to: CFDictionary.self)
        
        var delayObject: AnyObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()), to: AnyObject.self)
        
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        delay = delayObject as! Double
        
        if delay < 0.1 {
            delay = 0.1
        }
        
        return delay
    }
    
    class func getSizeOfImage( source : CGImageSource ) -> CGSize {
        let options: [NSString: AnyObject] = [
            kCGImageSourceShouldCache: NSNumber(booleanLiteral:false)]

        if let imageProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, options as CFDictionary) as? [String:Any] {
           if let width = imageProperties[kCGImagePropertyPixelWidth as String] as? Int,
            let height = imageProperties[kCGImagePropertyPixelHeight as String] as? Int {
                return CGSize( width:width, height:height )
            }
        }

        return CGSize( width:0, height:0 )
    }
    
    class func getImageFramesFromGIF(source: CGImageSource) -> [ImageFrame] {
        let size = getSizeOfImage(source: source)
        
        let count = CGImageSourceGetCount(source)
        var images = [ImageFrame]()
        
        
        for i in 0..<count {
            let image : CGImage?
            if size.width != 16 {
                let options: [NSString: AnyObject] = [
                    kCGImageSourceThumbnailMaxPixelSize: NSNumber(integerLiteral:16),
                    kCGImageSourceCreateThumbnailFromImageAlways: NSNumber(booleanLiteral: true),
                    kCGImageSourceCreateThumbnailWithTransform:NSNumber(booleanLiteral: false)
                ]
                image = CGImageSourceCreateThumbnailAtIndex(source, i, options as CFDictionary)
            } else {
                image = CGImageSourceCreateImageAtIndex(source, i, nil)
            }
            
            if let image = image {
                
                let frame = getImageAsFrame( image )
                
                let delaySeconds = UIImage.delayForImageAtIndex(index: Int(i), source: source)
                frame.delay = Int(delaySeconds * 1000.0)
                
                images.append(frame)
            }
        }
        
        return images
    }
    
    class func getImageAsFrame( _ image: CGImage ) -> ImageFrame {
        let frame = ImageFrame()
        
        // get pixel data
        if let rawData = image.dataProvider?.data,
            let buf =  CFDataGetBytePtr(rawData) {
            let length = CFDataGetLength(rawData)
            
            var p = 0
            for i in stride(from:0, to:length, by:4) {
                
                let f1 : CGFloat = CGFloat(buf[i])/255
                let f2 : CGFloat = CGFloat(buf[i+1])/255
                let f3 : CGFloat = CGFloat(buf[i+2])/255
                let f4 : CGFloat = CGFloat(buf[i+3])/255
                
                let c : UIColor
                switch image.bitmapInfo.pixelFormat! {
                case .abgr:
                    c = UIColor(red: f4, green: f3, blue: f2, alpha: f1)
                case .argb:
                    c = UIColor(red: f2, green: f3, blue: f4, alpha: f1)
                case .bgra:
                    c = UIColor(red: f3, green: f2, blue: f1, alpha: f4)
                case .rgba:
                    c = UIColor(red: f1, green: f2, blue: f3, alpha: f4)
                }
                
                let x = p % 16
                let y = p / 16
                
                frame.pixels[x][y] = c
                
                p += 1
                if p == 256 {
                    break
                }
            }
        }
        
        return frame
    }
    
   
}
