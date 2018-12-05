//
//  PaletteManager.swift
//  UbercornFrame
//
//  Created by Andy Qua on 21/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

class PaletteManager {
    static let instance = PaletteManager()
    
    var palettes : [String:Palette]
    
    var initialPalette : Palette {
        let p = palettes[getAllPaletteNames()[0]]!
        return p
    }
    
    func getAllPaletteNames() -> [String] {
        return palettes.keys.sorted()
    }

    var nrPalettes : Int {
        return palettes.count
    }

    private init() {
        palettes = Palette.loadPalettes()
    }
    
    func getPalette(_ name: String ) -> Palette? {
        return palettes[name]
    }
    
    func createPalette( fromImageFrames frames : [ImageFrame] ) -> Palette? {
        var colors = [String]()
        for frame in frames {
            colors.append(contentsOf: (frame.pixels.flatMap { $0 }).map { $0.hexString })
        }
        
        guard var uniqueColors = Array(NSOrderedSet(array: colors)) as? [String] else { return nil }
        uniqueColors.sort { $0 < $1 }

        let p = Palette( name:"Custom", colors:uniqueColors)
        
        palettes["Custom"] = p
        return p
    }

}
