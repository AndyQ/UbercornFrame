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
    case bgr
    case rgb
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
        
        if alphaInfo! == .none {
            if endianLittle {
                return .bgr
            } else {
                return .rgb
            }
        } else if alphaFirst && endianLittle {
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
    
    class func gifImage( withData data: Data) -> [ImageFrame]? {
        guard let source = CGImageSourceCreateWithData(data as NSData, nil) else {
            print("image doesn't exist")
            return nil
        }
        
        return UIImage.getImageFramesFromGIF(source: source)
    }
    
    class func gifImage( withURL url:URL) -> [ImageFrame]? {
        guard let imageData = try? Data(contentsOf: url) else {
            print("Unable to load image named \"\(url)\" into NSData")
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
        
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into Data")
            return nil
        }
        
        return gifImage(withData: imageData)
    }
    
    class func delayForImageAtIndex(index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary? = unsafeBitCast(CFDictionaryGetValue(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()), to: CFDictionary.self)
        
        if gifProperties == nil {
            return delay
        }
        
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
            if size.width != size.height || Int(size.width)%16 != 0 {
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
        
        let width = max(image.width, image.height)
        let pixelStride = width / 16

        // get pixel data
        let pixelData = getPixelDataForImage(image)
        
        let pixelSize = 4

        for y in 0 ..< 16 {
            for x in 0 ..< 16 {
                let i = (x*pixelStride*pixelSize) + (y*pixelStride*width*pixelSize)

                var r :CGFloat = 0
                var g :CGFloat = 0
                var b :CGFloat = 0
                if i < pixelData.count {
                    //let a = CGFloat(pixelData[i])/255
                    r = CGFloat(pixelData[i+1])/255
                    g = CGFloat(pixelData[i+2])/255
                    b = CGFloat(pixelData[i+3])/255
                }
                let c = UIColor(red: r, green: g, blue: b, alpha: 1.0)
                frame.pixels[x][y] = c
            }
        }

        return frame
    }

    
    class func getPixelDataForImage( _ inImage : CGImage ) -> [UInt8] {
        // Converts the passed in image into a ARGB image so we can be consistent
        
        // Get image width, height. We'll use the entire image.
        let pixelsWide = inImage.width
        let pixelsHigh = inImage.height
        
        
        // Use the generic RGB color space.
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let maxSize = max(pixelsWide, pixelsHigh)
        let dataSize = maxSize * maxSize * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))

        // Declare the number of bytes per row. Each pixel in the bitmap in this
        // example is represented by 4 bytes; 8 bits each of red, green, blue, and
        // alpha.
        let bitmapBytesPerRow = (maxSize * 4);

        let context = CGContext(data: &pixelData, width: maxSize, height: maxSize, bitsPerComponent: 8, bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo:CGImageAlphaInfo.premultipliedFirst.rawValue)

        let rect = CGRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh)
        
        context?.draw(inImage, in: rect)
        
        return pixelData
    }

}
