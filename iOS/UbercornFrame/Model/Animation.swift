//
//  Animation.swift
//  UbercornFrame
//
//  Created by Andy Qua on 22/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit
import MobileCoreServices

class Animation {
    public private (set) var frames : [ImageFrame]
    public private (set) var frameIndex = 0 {
        didSet { frameChanged?(frameIndex) }
    }
    
    var numberOfFrames : Int {
        return frames.count
    }
    
    var currentFrame : ImageFrame {
        return frames[frameIndex]
    }
    
    var frameChanged : ((Int)->())?
    
    init() {
        frames = [ImageFrame()]
    }
    
    func generateGif() -> Data {
        
        let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]
        
        let data = NSMutableData()
        
        if let destination = CGImageDestinationCreateWithData(data, kUTTypeGIF, frames.count, nil) {
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary?)
            
            for frame in frames {
                let gifProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: Float(frame.delay)/1000]]
                if let image = frame.asImage() {
                    CGImageDestinationAddImage(destination, image.cgImage!, gifProperties as CFDictionary?)
                }
            }
            CGImageDestinationFinalize(destination)
        }
        
        return data as Data
    }

    
    func setFrames( _ newFrames : [ImageFrame] ) -> ImageFrame {
        self.frames = newFrames
        if self.frames.count == 0 {
            self.frames = [ImageFrame()]
        }
        frameIndex = 0

        let newFrame = self.frames[frameIndex]
        return newFrame
    }
    
    func nextFrame() -> ImageFrame {
        frameIndex = frameIndex+1 >= self.frames.count ? 0 : frameIndex+1
        return self.frames[frameIndex]
    }
    
    func prevFrame() -> ImageFrame {
        frameIndex = frameIndex-1 < 0 ? self.frames.count-1 : frameIndex-1
        return self.frames[frameIndex]
    }
    
    func addNewFrameAfterCurrentPosition( ) -> ImageFrame {
        let frame = ImageFrame()
        frame.delay = self.frames[frameIndex].delay
        self.frames.insert(frame, at:self.frameIndex+1)
        self.frameIndex += 1
        return self.frames[frameIndex]
    }
    
    func duplicateFrame() -> ImageFrame {
        let frame = ImageFrame(frame:self.frames[frameIndex])
        frame.delay = self.frames[frameIndex].delay

        self.frames.insert(frame, at:self.frameIndex+1)
        self.frameIndex += 1
        return self.frames[frameIndex]
    }

    func deleteFrame() -> ImageFrame {
        self.frames.remove(at: self.frameIndex)
        if frames.count == 0 {
            self.frames.append(ImageFrame())
            frameIndex = 0
        } else if self.frameIndex >= self.frames.count {
            frameIndex -= 1
        } else {
            self.frameIndex = frameIndex + 0
        }
        return self.frames[frameIndex]
    }
}
