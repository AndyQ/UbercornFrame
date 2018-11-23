//
//  Frame.swift
//  GameFrame
//
//  Created by Andy Qua on 21/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

struct PixelData {
    var a:UInt8 = 255
    var r:UInt8
    var g:UInt8
    var b:UInt8
}

class ImageFrame {
    var pixels = [[UIColor]]()
    var delay : Int = 100
    
    init() {
        pixels = Array(repeating: Array(repeating: UIColor.white, count: 16), count: 16)
    }

    init( frame: ImageFrame ) {
        pixels = Array(repeating: Array(repeating: UIColor.white, count: 16), count: 16)
        for y in 0 ..< 16 {
            for x in 0 ..< 16 {
                self.pixels[x][y] = frame.pixels[x][y] //UIColor(cgColor:frame.pixels[x][y].cgColor)
            }
            
        }
    }

    
    func getData() -> [PixelData] {
        var data = [PixelData]()
        for y in 0 ..< 16 {
            for x in 0 ..< 16 {
                let rgb = pixels[x][y].rgb()!

                let p = PixelData(a: 255, r: rgb[0], g:rgb[1], b:rgb[2])
                data.append(p)
            }
        }
        return data
    }
    
    func asImage() -> UIImage? {
        
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue)

        let pixelDataSize = MemoryLayout<PixelData>.size
        
        var pixels = getData() // Copy to mutable []
        let data = Data(bytes: &pixels, count: pixels.count * pixelDataSize)
        let providerRef = CGDataProvider(data: data as CFData )
//            data: data//Data(bytes: &data, length: data.count * pixelDataSize))
//        )

        let width = 16
        let height = 16
        if let cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * pixelDataSize, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo, provider: providerRef!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent) {
            
            let image = UIImage(cgImage: cgImage)
            
            return image
        }
        
        return nil
    }
}
